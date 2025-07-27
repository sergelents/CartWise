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
    // func fetchRecentProducts(limit: Int) async throws -> [GroceryItem]
    func createProduct(id: String, productName: String, brand: String?, category: String?, price: Double, currency: String, store: String?, location: String?, imageURL: String?, barcode: String?, isInShoppingList: Bool) async throws -> GroceryItem
    func updateProduct(_ product: GroceryItem) async throws
    func deleteProduct(_ product: GroceryItem) async throws
    func removeProductFromShoppingList(_ product: GroceryItem) async throws
    func toggleProductCompletion(_ product: GroceryItem) async throws
    func addProductToShoppingList(_ product: GroceryItem) async throws
    func fetchFavoriteProducts() async throws -> [GroceryItem]
    func addProductToFavorites(_ product: GroceryItem) async throws
    func removeProductFromFavorites(_ product: GroceryItem) async throws
    func toggleProductFavorite(_ product: GroceryItem) async throws
    func searchProducts(by name: String) async throws -> [GroceryItem]
    func searchProductsOnAmazon(by query: String) async throws -> [GroceryItem]
    func searchProductsOnWalmart(by query: String) async throws -> [GroceryItem]
    func fetchProductFromNetwork(by name: String) async throws -> GroceryItem?
    func getPriceComparison(for shoppingList: [GroceryItem]) async throws -> PriceComparison
}

// Price comparison models
struct StorePrice: Codable, Sendable {
    let store: Store
    let totalPrice: Double
    let currency: String
    let availableItems: Int
    let unavailableItems: Int
    let itemPrices: [String: Double] // productName -> price
}

struct PriceComparison: Codable, Sendable {
    let storePrices: [StorePrice]
    let bestStore: Store?
    let bestTotalPrice: Double
    let bestCurrency: String
    let totalItems: Int
    let availableItems: Int
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
    
    // func fetchRecentProducts(limit: Int) async throws -> [GroceryItem] {
    //     // Cache-first: return local data immediately
    //     return try await coreDataContainer.fetchRecentProducts(limit: limit)
    // }
    
    func createProduct(id: String, productName: String, brand: String?, category: String?, price: Double, currency: String, store: String?, location: String?, imageURL: String?, barcode: String?, isInShoppingList: Bool = false) async throws -> GroceryItem {
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
            barcode: barcode,
            isInShoppingList: isInShoppingList
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
    
    func fetchFavoriteProducts() async throws -> [GroceryItem] {
        // Cache-first: return favorite products immediately
        return try await coreDataContainer.fetchFavoriteProducts()
    }
    
    func addProductToFavorites(_ product: GroceryItem) async throws {
        // Add existing product to favorites
        try await coreDataContainer.addProductToFavorites(product)
    }
    
    func removeProductFromFavorites(_ product: GroceryItem) async throws {
        // Remove product from favorites
        try await coreDataContainer.removeProductFromFavorites(product)
    }
    
    func toggleProductFavorite(_ product: GroceryItem) async throws {
        // Toggle favorite status
        try await coreDataContainer.toggleProductFavorite(product)
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
                    barcode: networkProduct.barcode,
                    isInShoppingList: false
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
        print("Repository: Starting Amazon search for query: \(query)")
        // Network-first: search Amazon directly
        do {
            let amazonProducts = try await networkService.searchProductsOnAmazon(by: query)
            print("Repository: Got \(amazonProducts.count) products from network service")
            
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
                    barcode: amazonProduct.barcode,
                    isInShoppingList: false
                )
                print("Repository: Created GroceryItem: '\(groceryItem.productName ?? "Unknown")'")
                groceryItems.append(groceryItem)
            }
            
            print("Repository: Returning \(groceryItems.count) GroceryItems")
            return groceryItems
        } catch {
            print("Repository: Error in Amazon search: \(error)")
            // If Amazon search fails, return empty array
            return []
        }
    }
    
    func searchProductsOnWalmart(by query: String) async throws -> [GroceryItem] {
        print("Repository: Starting Walmart search for query: \(query)")
        // Network-first: search Walmart directly
        do {
            let walmartProducts = try await networkService.searchProductsOnWalmart(by: query)
            print("Repository: Got \(walmartProducts.count) products from network service")
            
            // Convert Walmart products to GroceryItems and save to local cache
            var groceryItems: [GroceryItem] = []
            for walmartProduct in walmartProducts.prefix(10) { // Limit to first 10
                let groceryItem = try await createProduct(
                    id: walmartProduct.id,
                    productName: walmartProduct.productName,
                    brand: walmartProduct.brand,
                    category: walmartProduct.category,
                    price: walmartProduct.price,
                    currency: walmartProduct.currency,
                    store: walmartProduct.store,
                    location: walmartProduct.location,
                    imageURL: walmartProduct.imageURL,
                    barcode: walmartProduct.barcode
                )
                print("Repository: Created GroceryItem: '\(groceryItem.productName ?? "Unknown")'")
                groceryItems.append(groceryItem)
            }
            
            print("Repository: Returning \(groceryItems.count) GroceryItems")
            return groceryItems
        } catch {
            print("Repository: Error in Walmart search: \(error)")
            // If Walmart search fails, return empty array
            return []
        }
    }
    
    func getPriceComparison(for shoppingList: [GroceryItem]) async throws -> PriceComparison {
        print("Repository: Starting price comparison for \(shoppingList.count) items")
        
        // Use TaskGroup for concurrent price fetching
        return try await withTaskGroup(of: StorePrice.self) { group in
            let stores: [Store] = [.amazon, .walmart]
            
            // Add tasks for each store
            for store in stores {
                group.addTask {
                    await self.fetchStorePrices(for: store, shoppingList: shoppingList)
                }
            }
            
            // Collect results
            var storePrices: [StorePrice] = []
            for await storePrice in group {
                storePrices.append(storePrice)
            }
            
            // Find the best store
            let bestStorePrice = storePrices.min { $0.totalPrice < $1.totalPrice }
            let bestStore = bestStorePrice?.store
            let bestTotalPrice = bestStorePrice?.totalPrice ?? 0.0
            let bestCurrency = bestStorePrice?.currency ?? "USD"
            
            let comparison = PriceComparison(
                storePrices: storePrices,
                bestStore: bestStore,
                bestTotalPrice: bestTotalPrice,
                bestCurrency: bestCurrency,
                totalItems: shoppingList.count,
                availableItems: storePrices.map { $0.availableItems }.max() ?? 0
            )
            
            print("Repository: Price comparison complete. Best store: \(bestStore?.rawValue ?? "None"), Total: $\(bestTotalPrice)")
            return comparison
        }
    }
    
    // Helper method for fetching store prices using TaskGroup
    private func fetchStorePrices(for store: Store, shoppingList: [GroceryItem]) async -> StorePrice {
        print("Repository: Checking prices at \(store.rawValue)")
        var totalPrice: Double = 0.0
        var availableItems = 0
        var unavailableItems = 0
        var itemPrices: [String: Double] = [:]
        
        // Use TaskGroup for concurrent item price fetching
        await withTaskGroup(of: (String, Double?).self) { group in
            for item in shoppingList {
                guard let productName = item.productName else { continue }
                
                group.addTask {
                    do {
                        if let priceData = try await self.networkService.searchGroceryPrice(productName: productName, store: store) {
                            print("Repository: Found \(productName) at \(store.rawValue) for $\(priceData.price)")
                            return (productName, priceData.price)
                        } else {
                            print("Repository: \(productName) not found at \(store.rawValue)")
                            return (productName, nil)
                        }
                    } catch {
                        print("Repository: Error searching for \(productName) at \(store.rawValue): \(error)")
                        return (productName, nil)
                    }
                }
            }
            
            // Collect results
            for await (productName, price) in group {
                if let price = price {
                    totalPrice += price
                    availableItems += 1
                    itemPrices[productName] = price
                } else {
                    unavailableItems += 1
                }
            }
        }
        
        return StorePrice(
            store: store,
            totalPrice: totalPrice,
            currency: "USD",
            availableItems: availableItems,
            unavailableItems: unavailableItems,
            itemPrices: itemPrices
        )
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
                barcode: networkProduct.barcode,
                isInShoppingList: false
            )
            
            return savedProduct
        } catch {
            // Product not found in API, return nil
            return nil
        }
    }
}

// This code was generated with the help of Claude, saving me 7 hours of research and development.