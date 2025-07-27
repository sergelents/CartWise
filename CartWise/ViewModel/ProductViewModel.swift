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
    @Published var recentProducts: [GroceryItem] = []
    @Published var priceComparison: PriceComparison?
    @Published var isLoadingPriceComparison = false
    var errorMessage: String?
    
    private let repository: ProductRepositoryProtocol
    
    // Computed property to check if all products are completed
    var allProductsCompleted: Bool {
        !products.isEmpty && products.allSatisfy { $0.isCompleted }
    }
    
    init(repository: ProductRepositoryProtocol) {
            self.repository = repository
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
    
    // func loadRecentProducts(limit: Int = 10) async {
    //     do {
    //         recentProducts = try await repository.fetchRecentProducts(limit: limit)
    //         errorMessage = nil
    //     } catch {
    //         errorMessage = error.localizedDescription
    //     }
    // }
    
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
    

  
    func searchProducts(by name: String) async {
        do {
            products = try await repository.searchProducts(by: name)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func searchProductsOnAmazon(by query: String) async {
        print("ViewModel: Searching Amazon for query: \(query)")
        do {
            products = try await repository.searchProductsOnAmazon(by: query)
            print("ViewModel: Received \(products.count) products from API")
            
            // Print details of each product
            for (index, product) in products.enumerated() {
                print("  Product \(index + 1):")
                print("    Name: \(product.productName ?? "Unknown")")
                print("    Brand: \(product.brand ?? "Unknown")")
                print("    Category: \(product.category ?? "Unknown")")
                print("    Price: $\(product.price)")
                print("    Store: \(product.store ?? "Unknown")")
                print("    Location: \(product.location ?? "Unknown")")
                print("    Image URL: \(product.imageURL ?? "None")")
                print("    Barcode: \(product.barcode ?? "None")")
                print("    ---")
            }
            
            errorMessage = nil
        } catch {
            print("ViewModel: Error searching Amazon: \(error)")
            errorMessage = error.localizedDescription
        }
    }
    
    func searchProductsOnWalmart(by query: String) async {
        print("ViewModel: Searching Walmart for query: \(query)")
        do {
            products = try await repository.searchProductsOnWalmart(by: query)
            print("ViewModel: Received \(products.count) products from API")
            errorMessage = nil
        } catch {
            print("ViewModel: Error searching Walmart: \(error)")
            errorMessage = error.localizedDescription
        }
    }
    
    func loadPriceComparison() async {
        // Get the current shopping list products specifically
        let shoppingListProducts = try? await repository.fetchListProducts()
        
        guard let shoppingList = shoppingListProducts, !shoppingList.isEmpty else {
            priceComparison = nil
            return
        }
        
        isLoadingPriceComparison = true
        errorMessage = nil
        
        do {
            print("ViewModel: Starting price comparison for shopping list with \(shoppingList.count) items")
            let comparison = try await repository.getPriceComparison(for: shoppingList)
            priceComparison = comparison
            print("ViewModel: Price comparison loaded successfully")
        } catch {
            print("ViewModel: Error loading price comparison: \(error)")
            errorMessage = "Failed to load price comparison: \(error.localizedDescription)"
        }
        
        isLoadingPriceComparison = false
    }
    
    func refreshPriceComparison() async {
        await loadPriceComparison()
    }
    
    func searchProductsByBarcode(_ barcode: String) async {
        do {
            products = try await repository.searchProducts(by: barcode)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func createProductForShoppingList(byName name: String, brand: String? = nil, category: String? = nil, price: Double = 0.0) async {
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
                isInShoppingList: true
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
    
    // MARK: - Barcode-specific methods for future implementation
    
    func createProductByBarcode(_ barcode: String) async {
        do {
            // Check if product already exists with this barcode
            if await isDuplicateBarcode(barcode) {
                errorMessage = "Product with barcode '\(barcode)' already exists in your list"
                return
            }
            
            // Try to fetch product from API using barcode
            if let apiProduct = try await repository.fetchProductFromNetwork(by: barcode) {
                // Product found in API, add to shopping list
                await addExistingProductToShoppingList(apiProduct)
                errorMessage = nil
            } else {
                // Product not found in API, create basic entry
                let id = UUID().uuidString
                _ = try await repository.createProduct(
                    id: id,
                    productName: "Product (Barcode: \(barcode))",
                    brand: nil,
                    category: nil,
                    price: 0.0,
                    currency: "USD",
                    store: nil,
                    location: nil,
                    imageURL: nil,
                    barcode: barcode,
                    isInShoppingList: false
                )
                await loadShoppingListProducts()
                errorMessage = nil
            }
        } catch {
            errorMessage = error.localizedDescription
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
    
}

// This code was generated with the help of Claude, saving me 1 hour of research and development.