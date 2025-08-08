//
//  ProductViewModel.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/7/25.
//
import SwiftUI
import Combine
import CoreData
import Foundation
@MainActor
final class ProductViewModel: ObservableObject {
    @Published var products: [GroceryItem] = []
    @Published var favoriteProducts: [GroceryItem] = []
    @Published var recentProducts: [GroceryItem] = []
    @Published var priceComparison: PriceComparison?
    @Published var isLoadingPriceComparison = false
    @Published var tags: [Tag] = []
    @Published var locations: [Location] = []
    var errorMessage: String?
    private let repository: ProductRepositoryProtocol
    private let imageService: ImageServiceProtocol
    // Computed property to check if all products are completed
    var allProductsCompleted: Bool {
        !products.isEmpty && products.allSatisfy { $0.isCompleted }
    }
    init(repository: ProductRepositoryProtocol, imageService: ImageServiceProtocol = ImageService()) {
        self.repository = repository
        self.imageService = imageService
        Task {
            await loadTags()
        }
    }
    func loadShoppingListProducts() async {
        do {
            products = try await repository.fetchListProducts()
            
            // Fetch images for products that don't have them
            await fetchImagesForProducts()
            
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

    // Fetch all products without mutating the published `products` array
    // Useful for views that need a read-only snapshot without triggering UI-wide reloads
    func fetchAllProducts() async -> [GroceryItem] {
        do {
            return try await repository.fetchAllProducts()
        } catch {
            // Surface the error but do not mutate state; return an empty list on failure
            errorMessage = error.localizedDescription
            return []
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
            
            // Update the products array on the main thread
            await MainActor.run {
                products.removeAll { $0.id == product.id }
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    func permanentlyDeleteProduct(_ product: GroceryItem) async {
        do {
            try await repository.deleteProduct(product)
            // Reload the entire list instead of manually removing items
            // This prevents collection view inconsistency during animations
            await loadShoppingListProducts()
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
    
    func clearShoppingList() async {
        do {
            // Remove all products from shopping list without deleting the actual product data
            for product in products {
                try await repository.removeProductFromShoppingList(product)
            }
            // Clear the local products array
            await MainActor.run {
                products.removeAll()
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    func addExistingProductToShoppingList(_ product: GroceryItem) async {
        do {
            try await repository.addProductToShoppingList(product)
            // Refresh shopping list to show the newly added item
            await loadShoppingListProducts()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // Quiet version that doesn't reload lists - for UI components
    func addExistingProductToShoppingListQuiet(_ product: GroceryItem) async {
        do {
            try await repository.addProductToShoppingList(product)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    // MARK: - Favorites Methods
    func loadFavoriteProducts() async {
        do {
            favoriteProducts = try await repository.fetchFavoriteProducts()
            
            // Fetch images for favorite products that don't have them
            await fetchImagesForProductArray(favoriteProducts)
            
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
    
    // Quiet version that doesn't reload lists - for UI components
    func addProductToFavoritesQuiet(_ product: GroceryItem) async {
        do {
            try await repository.addProductToFavorites(product)
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
    
    // Quiet version that doesn't reload lists - for UI components
    func removeProductFromFavoritesQuiet(_ product: GroceryItem) async {
        do {
            try await repository.removeProductFromFavorites(product)
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
    
    // Image Fetching
    // Fetches images for products that don't have image URLs
    func fetchImagesForProducts() async {
        await fetchImagesForProductArray(products)
    }
    
    // Fetches images for any array of products that don't have image URLs
    private func fetchImagesForProductArray(_ productArray: [GroceryItem]) async {
        // Get products that don't have image URLs
        let productsWithoutImages = productArray.filter { $0.imageURL == nil || $0.imageURL?.isEmpty == true }
        
        if productsWithoutImages.isEmpty {
            return
        }
        
        // Fetch images for each product
        for product in productsWithoutImages {
            await fetchImageForProduct(product)
        }
    }
    
    // Fetches image for a specific product
    private func fetchImageForProduct(_ product: GroceryItem) async {
        do {
            let productName = product.productName ?? ""
            let brand = product.brand
            let category = product.category
            
            if let imageURL = try await imageService.fetchImageURL(for: productName, brand: brand, category: category) {
                // Download image data
                if let url = URL(string: imageURL) {
                    let (imageData, _) = try await URLSession.shared.data(from: url)
                    
                    // Update product with image data on main thread
                    await MainActor.run {
                        // Save image to Core Data using new ProductImage entity
                        Task {
                            do {
                                try await repository.saveProductImage(for: product, imageURL: imageURL, imageData: imageData)
                                
                                // Force a UI update by triggering objectWillChange
                                self.objectWillChange.send()
                            } catch {
                                print("ProductViewModel: Error saving image data: \(error.localizedDescription)")
                            }
                        }
                    }
                }
            }
            
        } catch {
            print("ProductViewModel: Error fetching image for '\(product.productName ?? "")': \(error.localizedDescription)")
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

    // Search without mutating the published `products` array
    func searchProductsQuiet(by name: String) async -> [GroceryItem] {
        do {
            return try await repository.searchProducts(by: name)
        } catch {
            errorMessage = error.localizedDescription
            return []
        }
    }
    func searchProductsByBarcode(_ barcode: String) async throws -> [GroceryItem] {
        return try await repository.searchProductsByBarcode(barcode)
    }
    func createProductForShoppingList(byName name: String, brand: String? = nil, category: String? = nil, isOnSale: Bool = false) async {
        do {
            if await isDuplicateProduct(name: name) {
                errorMessage = "Product '\(name)' already exists in your list"
                return
            }
            let id = UUID().uuidString
            // Capture the created product to fetch its image
            let savedProduct = try await repository.createProduct(
                id: id,
                productName: name,
                brand: brand,
                category: category,
                price: 0.0, // Default price - will be stored in GroceryItemPrice if > 0
                currency: "USD",
                store: nil,
                location: nil,
                imageURL: nil,
                barcode: nil,
                isInShoppingList: true,
                isOnSale: isOnSale
            )
            
            // Fetch image for the newly created product
            await fetchImageForProduct(savedProduct)
            
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
            let existingProducts = try await repository.searchProductsByBarcode(barcode)
            return existingProducts.contains { product in
                product.barcode?.lowercased() == barcode.lowercased()
            }
        } catch {
            return false // If search fails, allow creation
        }
    }
    func createProductByBarcode(
        barcode: String,
        productName: String,
        brand: String?,
        category: String?,
        price: Double,
        store: String,
        isOnSale: Bool = false
    ) async -> GroceryItem? {
        do {
            print("ProductViewModel: Creating product with barcode: \(barcode)")
            print("ProductViewModel: Store value: '\(store)'")
            // Check if product already exists with this barcode
            if await isDuplicateBarcode(barcode) {
                errorMessage = "Product with barcode '\(barcode)' already exists"
                return nil
            }
            let id = UUID().uuidString
            // Capture the created product to fetch its image
            let savedProduct = try await repository.createProduct(
                id: id,
                productName: productName,
                brand: brand,
                category: category,
                price: price,
                currency: "USD",
                store: store, // Set store for price comparison
                location: nil,
                imageURL: nil,
                barcode: barcode,
                isInShoppingList: false, // Don't automatically add to shopping list
                isOnSale: isOnSale
            )
            print("ProductViewModel: Product created successfully")
            print("ProductViewModel: Saved product store: '\(savedProduct.store ?? "nil")'")
            
            // Fetch image for the newly created product
            await fetchImageForProduct(savedProduct)
            
            await loadShoppingListProducts()
            errorMessage = nil
            return savedProduct
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
    func updateProductByBarcode(barcode: String, productName: String?, brand: String?, category: String?, price: Double?, store: String?, isOnSale: Bool?) async -> GroceryItem? {
        do {
            print("ProductViewModel: Updating product with barcode: \(barcode)")
            print("ProductViewModel: Update store value: '\(store ?? "nil")'")
            let existingProducts = try await repository.searchProductsByBarcode(barcode)
            guard let existingProduct = existingProducts.first(where: { $0.barcode?.lowercased() == barcode.lowercased() }) else {
                // This should not happen if we checked isDuplicateBarcode first
                // But handle gracefully just in case
                errorMessage = "Unable to update product with barcode '\(barcode)' - product not found in database"
                return nil
            }
            print("ProductViewModel: Found existing product, current store: '\(existingProduct.store ?? "nil")'")
            // Update only provided values
            if let productName = productName {
                existingProduct.productName = productName
            }
            if let brand = brand {
                existingProduct.brand = brand
            }
            if let category = category {
                existingProduct.category = category
            }
            if let isOnSale = isOnSale {
                existingProduct.isOnSale = isOnSale
            }
            // Handle price and store updates
            if let price = price, let store = store, price > 0 {
                try await repository.updateProductWithPrice(product: existingProduct, price: price, store: store, location: nil)
            } else {
                // Just update the product without price changes
                try await repository.updateProduct(existingProduct)
            }
            print("ProductViewModel: Product updated successfully")
            print("ProductViewModel: Final product store: '\(existingProduct.store ?? "nil")'")
            await loadShoppingListProducts()
            errorMessage = nil
            return existingProduct
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
    func loadLocalPriceComparison() async {
        // Get the current shopping list products specifically
        let shoppingListProducts = try? await repository.fetchListProducts()
        print("ProductViewModel: Starting local price comparison")
        print("ProductViewModel: Shopping list products count: \(shoppingListProducts?.count ?? 0)")
        guard let shoppingList = shoppingListProducts, !shoppingList.isEmpty else {
            print("ProductViewModel: No shopping list products found")
            await MainActor.run {
                priceComparison = nil
            }
            return
        }
        // Print details of each shopping list item
        for (index, item) in shoppingList.enumerated() {
            print("ProductViewModel: Item \(index + 1): \(item.productName ?? "Unknown") - Store: \(item.store ?? "None") - Price: $\(item.price)")
        }
        await MainActor.run {
            isLoadingPriceComparison = true
            errorMessage = nil
        }
        do {
            print("ViewModel: Starting local price comparison for shopping list with \(shoppingList.count) items")
            // Use the repository to get local price comparison
            let localComparison = try await repository.getLocalPriceComparison(for: shoppingList)
            print("ProductViewModel: Local comparison result - \(localComparison.storePrices.count) stores")
            for storePrice in localComparison.storePrices {
                print("ProductViewModel: Store \(storePrice.store): $\(storePrice.totalPrice)")
            }
            // Convert LocalPriceComparisonResult to PriceComparison for compatibility
            let storePrices = localComparison.storePrices.map { localStorePrice in
                StorePrice(
                    store: localStorePrice.store, // Now using String directly
                    totalPrice: localStorePrice.totalPrice,
                    currency: localStorePrice.currency,
                    availableItems: localStorePrice.availableItems,
                    unavailableItems: localStorePrice.unavailableItems,
                    itemPrices: localStorePrice.itemPrices,
                    itemShoppers: localStorePrice.itemShoppers
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
    
    @MainActor
    func replaceTagsForProduct(_ product: GroceryItem, tags: [Tag]) async {
        do {
            try await repository.replaceTagsForProduct(product, tags: tags)
        } catch {
            // Optionally handle error
        }
    }
    // MARK: - Location Management
    @MainActor
    func loadLocations() async {
        do {
            let context = await CoreDataStack.shared.viewContext
            // Get current user
            let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \UserEntity.createdAt, ascending: false)]
            fetchRequest.fetchLimit = 1
            let users = try context.fetch(fetchRequest)
            guard let currentUser = users.first else { return }
            // Fetch user's locations
            let locationFetchRequest: NSFetchRequest<Location> = Location.fetchRequest()
            locationFetchRequest.predicate = NSPredicate(format: "user == %@", currentUser)
            locationFetchRequest.sortDescriptors = [
                NSSortDescriptor(keyPath: \Location.isDefault, ascending: false),
                NSSortDescriptor(keyPath: \Location.favorited, ascending: false),
                NSSortDescriptor(keyPath: \Location.name, ascending: true)
            ]
            let fetchedLocations = try context.fetch(locationFetchRequest)
            // Update on main thread since we're already @MainActor
            self.locations = fetchedLocations
        } catch {
            print("Error loading locations: \(error)")
            self.locations = []
        }
    }
}
// This code was generated with the help of Claude, saving me 1 hour of research and development.
