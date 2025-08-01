
//
//  ProductViewModel.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/7/25.
//
import SwiftUI
import Combine

@MainActor
final class ProductViewModel: ObservableObject {
    @Published var products: [GroceryItem] = []
    @Published var favoriteProducts: [GroceryItem] = []
    @Published var recentProducts: [GroceryItem] = []
    @Published var priceComparison: PriceComparison?
    @Published var isLoadingPriceComparison = false
    @Published var tags: [Tag] = []
    var errorMessage: String?
    
    private let repository: ProductRepositoryProtocol
    
    // Computed property to check if all products are completed
    var allProductsCompleted: Bool {
        !products.isEmpty && products.allSatisfy { $0.isCompleted }
    }
    
    init(repository: ProductRepositoryProtocol) {
        self.repository = repository
        Task {
            await loadTags()
        }
    }
    
    func loadShoppingListProducts() async {
        do {
            products = try await repository.fetchListProducts()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func loadProducts() async {
        do {
            products = try await repository.fetchAllProducts()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func updateProduct(_ product: GroceryItem) async {
        do {
            try await repository.updateProduct(product)
            await loadProducts() 
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func deleteProduct(_ product: GroceryItem) async {
        do {
            try await repository.deleteProduct(product)
            products.removeAll { $0.id == product.id }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func removeProductFromShoppingList(_ product: GroceryItem) async {
        do {
            try await repository.removeProductFromShoppingList(product)
            products.removeAll { $0.id == product.id }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func permanentlyDeleteProduct(_ product: GroceryItem) async {
        do {
            try await repository.deleteProduct(product)
            products.removeAll { $0.id == product.id }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func toggleProductCompletion(_ product: GroceryItem) async {
        do {
            try await repository.toggleProductCompletion(product)
            await loadShoppingListProducts() // Refresh the list to show updated completion status
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func toggleAllProductsCompletion() async {
        do {
            // Check if all products are completed
            let allCompleted = products.allSatisfy { $0.isCompleted }
            
            // If all are completed, uncheck them all. Otherwise, check them all.
            for product in products {
                if allCompleted {
                    // Uncheck all if all are completed
                    if product.isCompleted {
                        try await repository.toggleProductCompletion(product)
                    }
                } else {
                    // Check all if not all are completed
                    if !product.isCompleted {
                        try await repository.toggleProductCompletion(product)
                    }
                }
            }
            await loadShoppingListProducts() // Refresh the list
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func addExistingProductToShoppingList(_ product: GroceryItem) async {
        do {
            try await repository.addProductToShoppingList(product)
            await loadShoppingListProducts()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Favorites Methods
    
    func loadFavoriteProducts() async {
        do {
            favoriteProducts = try await repository.fetchFavoriteProducts()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func addProductToFavorites(_ product: GroceryItem) async {
        do {
            try await repository.addProductToFavorites(product)
            await loadFavoriteProducts()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func removeProductFromFavorites(_ product: GroceryItem) async {
        do {
            try await repository.removeProductFromFavorites(product)
            await loadFavoriteProducts()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func toggleProductFavorite(_ product: GroceryItem) async {
        do {
            try await repository.toggleProductFavorite(product)
            await loadFavoriteProducts()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func isProductInFavorites(_ product: GroceryItem) async -> Bool {
        do {
            let favorites = try await repository.fetchFavoriteProducts()
            return favorites.contains { favorite in
                favorite.id == product.id
            }
        } catch {
            return false
        }
    }
    
    func searchProducts(by name: String) async {
        do {
            products = try await repository.searchProducts(by: name)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func createProductForShoppingList(byName name: String, brand: String? = nil, category: String? = nil, price: Double = 0.0, isOnSale: Bool = false) async {
        do {
            if await isDuplicateProduct(name: name) {
                errorMessage = "Product '\(name)' already exists in your list"
                return
            }
            
            let id = UUID().uuidString
            _ = try await repository.createProduct(
                id: id,
                productName: name,
                brand: brand,
                category: category,
                price: price,
                currency: "USD",
                store: nil,
                location: nil,
                imageURL: nil,
                barcode: nil,
                isInShoppingList: true,
                isOnSale: isOnSale
            )
            await loadShoppingListProducts()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // For creating products to database
    func isDuplicateProduct(name: String) async -> Bool {
        do {
            let existingProducts = try await repository.searchProducts(by: name)
            return existingProducts.contains { product in
                product.productName?.lowercased() == name.lowercased()
            }
        } catch {
            return false // If search fails, allow creation
        }
    }
    
    // For checking if existing product is already in shopping list
    func isProductInShoppingList(name: String) async -> Bool {
        do {
            // Only check shopping list products, not all products
            let shoppingListProducts = try await repository.fetchListProducts()
            return shoppingListProducts.contains { product in
                product.productName?.lowercased() == name.lowercased()
            }
        } catch {
            return false // If search fails, allow adding
        }
    }
    
    
    func isDuplicateBarcode(_ barcode: String) async -> Bool {
        do {
            let existingProducts = try await repository.searchProducts(by: barcode)
            return existingProducts.contains { product in
                product.barcode?.lowercased() == barcode.lowercased()
            }
        } catch {
            return false // If search fails, allow creation
        }
    }
    
    func loadLocalPriceComparison() async {
        // Get the current shopping list products specifically
        let shoppingListProducts = try? await repository.fetchListProducts()
        
        guard let shoppingList = shoppingListProducts, !shoppingList.isEmpty else {
            await MainActor.run {
                priceComparison = nil
            }
            return
        }
        
        await MainActor.run {
            isLoadingPriceComparison = true
            errorMessage = nil
        }
        
        do {
            print("ViewModel: Starting local price comparison for shopping list with \(shoppingList.count) items")
            
            // Use the repository to get local price comparison
            let localComparison = try await repository.getLocalPriceComparison(for: shoppingList)
            
            // Convert LocalPriceComparisonResult to PriceComparison for compatibility
            let storePrices = localComparison.storePrices.map { localStorePrice in
                StorePrice(
                    store: localStorePrice.store, // Now using String directly
                    totalPrice: localStorePrice.totalPrice,
                    currency: localStorePrice.currency,
                    availableItems: localStorePrice.availableItems,
                    unavailableItems: localStorePrice.unavailableItems,
                    itemPrices: localStorePrice.itemPrices
                )
            }
            
            let comparison = PriceComparison(
                storePrices: storePrices,
                bestStore: localComparison.bestStore, // Now using String directly
                bestTotalPrice: localComparison.bestTotalPrice,
                bestCurrency: localComparison.bestCurrency,
                totalItems: localComparison.totalItems,
                availableItems: localComparison.availableItems
            )
            
            await MainActor.run {
                priceComparison = comparison
                print("ViewModel: Local price comparison loaded successfully")
            }
        } catch {
            await MainActor.run {
                print("ViewModel: Error loading local price comparison: \(error)")
                errorMessage = "Failed to load local price comparison: \(error.localizedDescription)"
            }
        }
        
        await MainActor.run {
            isLoadingPriceComparison = false
        }
    }
}

extension ProductViewModel {
    @MainActor
    func loadTags() async {
        do {
            tags = try await repository.fetchAllTags()
        } catch {
            tags = []
        }
    }
    
    @MainActor
    func fetchAllTags() async -> [Tag] {
        do {
            return try await repository.fetchAllTags()
        } catch {
            return []
        }
    }
    
    @MainActor
    func addTagsToProduct(_ product: GroceryItem, tags: [Tag]) async {
        do {
            try await repository.addTagsToProduct(product, tags: tags)
        } catch {
            // Optionally handle error
        }
    }
}

// This code was generated with the help of Claude, saving me 1 hour of research and development.
