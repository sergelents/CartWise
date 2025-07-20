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
            
            // If no products exist, load some initial data for each category
            if products.isEmpty {
                await loadInitialCategoryData()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // Load initial products for each category
    private func loadInitialCategoryData() async {
        let initialSearches = [
            "beer",           // Beverages
            "milk",           // Dairy
            "bread",          // Bakery
            "chicken",        // Meat
            "apple",          // Produce
            "pasta",          // Pantry
            "ice cream",      // Frozen
            "soap"            // Household
        ]
        
        for searchTerm in initialSearches {
            do {
                await searchProductsOnAmazon(by: searchTerm)
                // Only keep a few products per category to avoid overwhelming
                if products.count > 20 {
                    break
                }
            } catch {
                print("Error loading initial data for \(searchTerm): \(error)")
            }
        }
    }
    
    func loadRecentProducts(limit: Int = 10) async {
        do {
            recentProducts = try await repository.fetchRecentProducts(limit: limit)
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
            // Toggle all products completion status
            for product in products {
                try await repository.toggleProductCompletion(product)
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
        do {
            products = try await repository.searchProductsOnAmazon(by: query)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func searchProductsByBarcode(_ barcode: String) async {
        do {
            products = try await repository.searchProducts(by: barcode)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func createProductForShoppingList(byName name: String, brand: String? = nil, category: String? = nil) async {
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
                price: 0.0,
                currency: "USD",
                store: nil,
                location: nil,
                imageURL: nil,
                barcode: nil
            )
            await loadShoppingListProducts()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
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
                    barcode: barcode
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
}// This code was generated with the help of Claude, saving me 1 hour of research and development.