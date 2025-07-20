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
        return try await coreDataContainer.createProduct(
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
                    productName: networkProduct.productName,
                    brand: networkProduct.brand,
                    category: networkProduct.category,
                    price: networkProduct.price,
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
            var groceryItems: [GroceryItem] = []
            for amazonProduct in amazonProducts.prefix(10) { // Limit to first 10
                let groceryItem = try await createProduct(
                    id: amazonProduct.id,
                    productName: amazonProduct.productName,
                    brand: amazonProduct.brand,
                    category: amazonProduct.category,
                    price: amazonProduct.price,
                    currency: amazonProduct.currency,
                    store: amazonProduct.store,
                    location: amazonProduct.location,
                    imageURL: amazonProduct.imageURL,
                    barcode: amazonProduct.barcode
                )
                groceryItems.append(groceryItem)
            }
            
            return groceryItems
        } catch {
            // If Amazon search fails, return empty array
            return []
        }
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
                productName: networkProduct.productName,
                brand: networkProduct.brand,
                category: networkProduct.category,
                price: networkProduct.price,
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
