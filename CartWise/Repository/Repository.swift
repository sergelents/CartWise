//
//  Repository.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/7/25.
//

import Foundation
import CoreData
import CartWise

protocol ProductRepositoryProtocol: Sendable {
    func fetchAllProducts() async throws -> [GroceryItem]
    func fetchListProducts() async throws -> [GroceryItem]
    // func fetchRecentProducts(limit: Int) async throws -> [GroceryItem]
    func createProduct(id: String, productName: String, brand: String?, category: String?, price: Double, currency: String, store: String?, location: String?, imageURL: String?, barcode: String?, isInShoppingList: Bool, isOnSale: Bool) async throws -> GroceryItem
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
    func getLocalPriceComparison(for shoppingList: [GroceryItem]) async throws -> LocalPriceComparisonResult
    
    // Tag-related methods
    func fetchAllTags() async throws -> [Tag]
    func createTag(id: String, name: String, color: String) async throws -> Tag
    func updateTag(_ tag: Tag) async throws
    func addTagsToProduct(_ product: GroceryItem, tags: [Tag]) async throws
    func removeTagsFromProduct(_ product: GroceryItem, tags: [Tag]) async throws
    func initializeDefaultTags() async throws
}

// Price comparison models
struct StorePrice: Codable, Sendable {
    let store: String // Changed from Store enum to String for dynamic store names
    let totalPrice: Double
    let currency: String
    let availableItems: Int
    let unavailableItems: Int
    let itemPrices: [String: Double] // productName -> price
}

struct PriceComparison: Codable, Sendable {
    let storePrices: [StorePrice]
    let bestStore: String? // Changed from Store? to String? for dynamic store names
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
    
    func createProduct(id: String, productName: String, brand: String?, category: String?, price: Double, currency: String, store: String?, location: String?, imageURL: String?, barcode: String?, isInShoppingList: Bool = false, isOnSale: Bool = false) async throws -> GroceryItem {
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
            isInShoppingList: isInShoppingList,
            isOnSale: isOnSale
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
       return localResults

        // Network-second: if no local results, try network
//        do {
//            let networkProducts = try await networkService.searchProducts(by: name)
//
//            // Save network results to local cache
//            for networkProduct in networkProducts.prefix(10) { // Limit to first 10
//                _ = try await createProduct(
//                    id: UUID().uuidString,
//                    productName: networkProduct.name,
//                    brand: nil, // API doesn't provide brand
//                    category: nil, // API doesn't provide category
//                    price: Double(networkProduct.price.replacingOccurrences(of: "$", with: "")) ?? 0.0,
//                    currency: networkProduct.currency,
//                    store: "Amazon", // Default store
//                    location: nil, // API doesn't provide location
//                    imageURL: networkProduct.image,
//                    barcode: nil, // API doesn't provide barcode
//                    isInShoppingList: false,
//                    isOnSale: false
//                )
//            }
//
//            // Return the newly cached results
//            return try await coreDataContainer.searchProducts(by: name)
//        } catch {
//            // If network fails, return empty array (cache-first approach)
//            return []
//        }
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
                    id: UUID().uuidString,
                    productName: amazonProduct.name,
                    brand: nil, // API doesn't provide brand
                    category: nil, // API doesn't provide category
                    price: Double(amazonProduct.price.replacingOccurrences(of: "$", with: "")) ?? 0.0,
                    currency: amazonProduct.currency,
                    store: "Amazon",
                    location: nil, // API doesn't provide location
                    imageURL: amazonProduct.image,
                    barcode: nil, // API doesn't provide barcode
                    isInShoppingList: false,
                    isOnSale: false
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
                    id: UUID().uuidString,
                    productName: walmartProduct.name,
                    brand: nil, // API doesn't provide brand
                    category: nil, // API doesn't provide category
                    price: Double(walmartProduct.price.replacingOccurrences(of: "$", with: "")) ?? 0.0,
                    currency: walmartProduct.currency,
                    store: "Walmart",
                    location: nil, // API doesn't provide location
                    imageURL: walmartProduct.image,
                    barcode: nil, // API doesn't provide barcode
                    isInShoppingList: false,
                    isOnSale: false
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
        print("Repository: Items to check: \(shoppingList.compactMap { $0.productName })")
        
        // Use TaskGroup for concurrent price fetching
        return try await withTaskGroup(of: StorePrice.self) { group in
            let stores: [String] = Set(shoppingList.compactMap { $0.store }).filter { !$0.isEmpty }
            
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
            
            print("Repository: Price comparison complete. Best store: \(bestStore ?? "None"), Total: $\(bestTotalPrice)")
            return comparison
        }
    }
    
    func getLocalPriceComparison(for shoppingList: [GroceryItem]) async throws -> LocalPriceComparisonResult {
        print("Repository: Starting local price comparison for \(shoppingList.count) items")
        
        // Only include stores that actually have items in the shopping list
        let availableStores = Set(shoppingList.compactMap { $0.store }.filter { !$0.isEmpty })
        print("Repository: Found stores in shopping list: \(availableStores)")
        
        guard !availableStores.isEmpty else {
            print("Repository: No stores found in shopping list")
            return LocalPriceComparisonResult(
                storePrices: [],
                bestStore: nil,
                bestTotalPrice: 0.0,
                bestCurrency: "USD",
                totalItems: shoppingList.count,
                availableItems: 0
            )
        }
        
        var storePrices: [LocalStorePrice] = []
        
        // Calculate prices for each store that has items
        for store in availableStores {
            var totalPrice: Double = 0.0
            var availableItems = 0
            var unavailableItems = 0
            var itemPrices: [String: Double] = [:]
            
            // Get items that belong to this specific store
            let storeItems = shoppingList.filter { $0.store == store }
            
            for item in storeItems {
                guard let productName = item.productName else { continue }
                
                if item.price > 0 {
                    totalPrice += item.price
                    availableItems += 1
                    itemPrices[productName] = item.price
                    print("Repository: Found \(productName) at \(store) for $\(item.price)")
                } else {
                    unavailableItems += 1
                    print("Repository: \(productName) at \(store) has no price")
                }
            }
            
            // Only include stores that have at least one item with a price
            if availableItems > 0 {
                let storePrice = LocalStorePrice(
                    store: store,
                    totalPrice: totalPrice,
                    currency: "USD",
                    availableItems: availableItems,
                    unavailableItems: unavailableItems,
                    itemPrices: itemPrices
                )
                storePrices.append(storePrice)
                print("Repository: Store \(store) total: $\(totalPrice), available: \(availableItems)/\(storeItems.count)")
            }
        }
        
        // Sort by total price (cheapest first) and take top 3
        let sortedStorePrices = storePrices.sorted { $0.totalPrice < $1.totalPrice }
        let top3StorePrices = Array(sortedStorePrices.prefix(3))
        
        // Find the best store (cheapest)
        let bestStore = top3StorePrices.first?.store
        let bestTotalPrice = top3StorePrices.first?.totalPrice ?? 0.0
        let bestCurrency = top3StorePrices.first?.currency ?? "USD"
        
        let comparison = LocalPriceComparisonResult(
            storePrices: top3StorePrices,
            bestStore: bestStore,
            bestTotalPrice: bestTotalPrice,
            bestCurrency: bestCurrency,
            totalItems: shoppingList.count,
            availableItems: top3StorePrices.map { $0.availableItems }.max() ?? 0
        )
        
        print("Repository: Local price comparison complete. Top 3 stores: \(top3StorePrices.map { "\($0.store): $\($0.totalPrice)" }.joined(separator: ", "))")
        return comparison
    }
    
    // Helper method for fetching store prices using TaskGroup
    private func fetchStorePrices(for store: String, shoppingList: [GroceryItem]) async -> StorePrice {
        print("Repository: Checking prices at \(store)")
        var totalPrice: Double = 0.0
        var availableItems = 0
        var unavailableItems = 0
        var itemPrices: [String: Double] = [:]
        
        // Get items that belong to this specific store
        let storeItems = shoppingList.filter { $0.store == store }
        
        for item in storeItems {
            guard let productName = item.productName else { continue }
            
            if item.price > 0 {
                totalPrice += item.price
                availableItems += 1
                itemPrices[productName] = item.price
                print("Repository: Found \(productName) at \(store) for $\(item.price)")
            } else {
                unavailableItems += 1
                print("Repository: \(productName) at \(store) has no price")
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
                id: UUID().uuidString,
                productName: networkProduct.name,
                brand: nil, // API doesn't provide brand
                category: nil, // API doesn't provide category
                price: Double(networkProduct.price.replacingOccurrences(of: "$", with: "")) ?? 0.0,
                currency: networkProduct.currency,
                store: "Amazon", // Default to Amazon since this is from Amazon API
                location: nil, // API doesn't provide location
                imageURL: networkProduct.image,
                barcode: nil, // API doesn't provide barcode
                isInShoppingList: false,
                isOnSale: false
            )
            
            return savedProduct
        } catch {
            // Product not found in API, return nil
            return nil
        }
    }
    
    // MARK: - Tag Methods
    
    func fetchAllTags() async throws -> [Tag] {
        return try await coreDataContainer.fetchAllTags()
    }
    
    func createTag(id: String, name: String, color: String) async throws -> Tag {
        return try await coreDataContainer.createTag(id: id, name: name, color: color)
    }
    
    func updateTag(_ tag: Tag) async throws {
        try await coreDataContainer.updateTag(tag)
    }
    
    func addTagsToProduct(_ product: GroceryItem, tags: [Tag]) async throws {
        try await coreDataContainer.addTagsToProduct(product, tags: tags)
    }
    
    func removeTagsFromProduct(_ product: GroceryItem, tags: [Tag]) async throws {
        try await coreDataContainer.removeTagsFromProduct(product, tags: tags)
    }
    
    func initializeDefaultTags() async throws {
        try await coreDataContainer.initializeDefaultTags()
    }
}

// This code was generated with the help of Claude, saving me 7 hours of research and development.
