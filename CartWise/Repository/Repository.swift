//
//  Repository.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/7/25.
//

import Foundation
import CoreData

protocol ProductRepositoryProtocol: Sendable {
    func fetchAllProducts() async throws -> [GroceryItem]
    func fetchListProducts() async throws -> [GroceryItem]
    func fetchRecentProducts(limit: Int) async throws -> [GroceryItem]
    func createProduct(id: String, productName: String, brand: String?, category: String?, price: Double, currency: String, store: String?, location: String?, imageURL: String?, barcode: String?) async throws -> GroceryItem
    func createSimpleProduct(name: String) async throws -> GroceryItem
    func updateProduct(_ product: GroceryItem) async throws
    func deleteProduct(_ product: GroceryItem) async throws
    func removeProductFromShoppingList(_ product: GroceryItem) async throws
    func toggleProductCompletion(_ product: GroceryItem) async throws
    func addProductToShoppingList(_ product: GroceryItem) async throws
    func searchProducts(by name: String) async throws -> [GroceryItem]
    func searchProductsOnAmazon(by query: String) async throws -> [GroceryItem]
    func fetchProductFromNetwork(by name: String) async throws -> GroceryItem?
}

final class ProductRepository: ProductRepositoryProtocol, @unchecked Sendable {
    private let coreDataContainer: CoreDataContainerProtocol
    private let networkService: NetworkServiceProtocol
    
    init(coreDataContainer: CoreDataContainerProtocol = CoreDataContainer(),
         networkService: NetworkServiceProtocol = NetworkService()) {
        self.coreDataContainer = coreDataContainer
        self.networkService = networkService
    }
    
    // MARK: - Cache-First Operations
    
    func fetchAllProducts() async throws -> [GroceryItem] {
        // Cache-first: return all local data immediately
        return try await coreDataContainer.fetchAllProducts()
    }
    
    func fetchListProducts() async throws -> [GroceryItem] {
        // Cache-first: return shopping list data immediately
        return try await coreDataContainer.fetchListProducts()
    }
    
    func fetchRecentProducts(limit: Int) async throws -> [GroceryItem] {
        // Cache-first: return local data immediately
        return try await coreDataContainer.fetchRecentProducts(limit: limit)
    }
    
    func createProduct(id: String, productName: String, brand: String?, category: String?, price: Double, currency: String, store: String?, location: String?, imageURL: String?, barcode: String?) async throws -> GroceryItem {
        // Create locally first
        return try await coreDataContainer.createDetailedProduct(
            id: id,
            productName: productName,
            brand: brand,
            category: category,
            price: price,
            currency: currency,
            store: store,
            location: location,
            imageURL: imageURL,
            barcode: barcode
        )
    }
    
    func createSimpleProduct(name: String) async throws -> GroceryItem {
        // Create simple product locally
        return try await coreDataContainer.createSimpleProduct(name: name)
    }
    
    func updateProduct(_ product: GroceryItem) async throws {
        // Update local cache
        try await coreDataContainer.updateProduct(product)
    }
    
    func deleteProduct(_ product: GroceryItem) async throws {
        // Permanently delete from local cache
        try await coreDataContainer.deleteProduct(product)
    }
    
    func removeProductFromShoppingList(_ product: GroceryItem) async throws {
        // Soft delete: remove from shopping list only
        try await coreDataContainer.removeProductFromShoppingList(product)
    }
    
    func toggleProductCompletion(_ product: GroceryItem) async throws {
        // Toggle completion status
        try await coreDataContainer.toggleProductCompletion(product)
    }
    
    func addProductToShoppingList(_ product: GroceryItem) async throws {
        // Add existing product to shopping list
        try await coreDataContainer.addProductToShoppingList(product)
    }
    
    func searchProducts(by name: String) async throws -> [GroceryItem] {
        // Local-only search for now
        // Cache-first: search local data first
        let localResults = try await coreDataContainer.searchProducts(by: name)

        // If we have local results, return them immediately
        if !localResults.isEmpty {
            return localResults
        }

        // Network-second: if no local results, try network
        do {
            let networkProducts = try await networkService.searchProducts(by: name)

            // Save network results to local cache
            for networkProduct in networkProducts.prefix(10) { // Limit to first 10
                _ = try await createProduct(
                    id: networkProduct.id,
                    productName: networkProduct.name,
                    brand: networkProduct.brand,
                    category: networkProduct.category,
                    price: networkProduct.priceValue,
                    currency: networkProduct.currency,
                    store: networkProduct.store,
                    location: networkProduct.location,
                    imageURL: networkProduct.imageURL,
                    barcode: networkProduct.barcode
                )
            }

            // Return the newly cached results
            return try await coreDataContainer.searchProducts(by: name)
        } catch {
            // If network fails, return empty array (cache-first approach)
            return []
        }
    }
    
    func searchProductsOnAmazon(by query: String) async throws -> [GroceryItem] {
        // Network-first: search Amazon directly
        do {
            let amazonProducts = try await networkService.searchProductsOnAmazon(by: query)
            
            // Convert Amazon products to GroceryItems and save to local cache
            var createdIds: [String] = []
            for amazonProduct in amazonProducts.prefix(10) { // Limit to first 10
                // Detect category based on product name and search query
                let detectedCategory = detectCategory(from: amazonProduct.name, searchQuery: query)
                
                let groceryItem = try await createProduct(
                    id: amazonProduct.id,
                    productName: amazonProduct.name,
                    brand: amazonProduct.brand,
                    category: detectedCategory,
                    price: amazonProduct.priceValue,
                    currency: amazonProduct.currency,
                    store: amazonProduct.store,
                    location: amazonProduct.location,
                    imageURL: amazonProduct.imageURL,
                    barcode: amazonProduct.barcode
                )
                createdIds.append(groceryItem.id ?? "")
            }
            
            // Fetch the created products from the main context
            let allProducts = try await coreDataContainer.fetchAllProducts()
            let groceryItems = allProducts.filter { product in
                createdIds.contains(product.id ?? "")
            }
            
            return groceryItems
        } catch {
            print("Amazon search error: \(error)")
            return []
        }
    }
    
    // Helper function to detect category from product name and search query
    private func detectCategory(from productName: String, searchQuery: String) -> String {
        let name = productName.lowercased()
        let query = searchQuery.lowercased()
        
        // Check for meat/seafood
        if name.contains("chicken") || name.contains("beef") || name.contains("pork") || 
           name.contains("fish") || name.contains("salmon") || name.contains("shrimp") ||
           query.contains("meat") || query.contains("seafood") {
            return ProductCategory.meat.rawValue
        }
        
        // Check for dairy
        if name.contains("milk") || name.contains("cheese") || name.contains("yogurt") ||
           name.contains("butter") || name.contains("cream") || name.contains("egg") ||
           query.contains("dairy") || query.contains("milk") {
            return ProductCategory.dairy.rawValue
        }
        
        // Check for bakery
        if name.contains("bread") || name.contains("cake") || name.contains("pastry") ||
           name.contains("cookie") || name.contains("muffin") || name.contains("donut") ||
           query.contains("bakery") || query.contains("bread") {
            return ProductCategory.bakery.rawValue
        }
        
        // Check for produce
        if name.contains("apple") || name.contains("banana") || name.contains("tomato") ||
           name.contains("lettuce") || name.contains("carrot") || name.contains("onion") ||
           query.contains("produce") || query.contains("fruit") || query.contains("vegetable") {
            return ProductCategory.produce.rawValue
        }
        
        // Check for beverages
        if name.contains("beer") || name.contains("wine") || name.contains("juice") ||
           name.contains("soda") || name.contains("coffee") || name.contains("tea") ||
           query.contains("beverage") || query.contains("drink") || query.contains("beer") {
            return ProductCategory.beverages.rawValue
        }
        
        // Check for frozen
        if name.contains("frozen") || name.contains("ice cream") || name.contains("pizza") ||
           query.contains("frozen") {
            return ProductCategory.frozen.rawValue
        }
        
        // Check for household
        if name.contains("soap") || name.contains("shampoo") || name.contains("toothpaste") ||
           name.contains("paper") || name.contains("cleaner") ||
           query.contains("household") || query.contains("personal") {
            return ProductCategory.household.rawValue
        }
        
        // Default to pantry for everything else
        return ProductCategory.pantry.rawValue
    }
    
    // MARK: - Network Operations
    
    func fetchProductFromNetwork(by name: String) async throws -> GroceryItem? {
        // Check cache first
        let existingProducts = try await coreDataContainer.fetchAllProducts()
        if let existingProduct = existingProducts.first(where: { $0.productName?.lowercased() == name.lowercased() }) {
            return existingProduct
        }
        
        // Network-second: fetch from API with retry logic
        do {
            let networkProduct = try await networkService.fetchProductWithRetry(by: name, retries: 3)
            
            guard let networkProduct = networkProduct else {
                return nil
            }
            
            // Save to local cache
            let savedProduct = try await createProduct(
                id: networkProduct.id,
                productName: networkProduct.name,
                brand: networkProduct.brand,
                category: networkProduct.category,
                price: networkProduct.priceValue,
                currency: networkProduct.currency,
                store: networkProduct.store,
                location: networkProduct.location,
                imageURL: networkProduct.imageURL,
                barcode: networkProduct.barcode
            )
            
            return savedProduct
        } catch NetworkError.productNotFound {
            // Product not found in API, return nil
            return nil
        } catch NetworkError.rateLimitExceeded {
            // Rate limited, return nil but could implement queue for later retry
            return nil
        } catch {
            // Other network errors, re-throw
            throw error
        }
    }
}

// This code was generated with the help of Claude, saving me 7 hours of research and development.
