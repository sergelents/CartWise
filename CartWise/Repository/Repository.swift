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
    func createProduct(id: String, productName: String, brand: String?, category: String?, price: Double, currency: String, store: String?, location: String?, imageURL: String?, barcode: String?, isInShoppingList: Bool, isOnSale: Bool) async throws -> GroceryItem
    func updateProduct(_ product: GroceryItem) async throws
    func updateProductWithPrice(product: GroceryItem, price: Double, store: String, location: String?) async throws
    func deleteProduct(_ product: GroceryItem) async throws
    func removeProductFromShoppingList(_ product: GroceryItem) async throws
    func toggleProductCompletion(_ product: GroceryItem) async throws
    func addProductToShoppingList(_ product: GroceryItem) async throws
    func fetchFavoriteProducts() async throws -> [GroceryItem]
    func addProductToFavorites(_ product: GroceryItem) async throws
    func removeProductFromFavorites(_ product: GroceryItem) async throws
    func toggleProductFavorite(_ product: GroceryItem) async throws
    func searchProducts(by name: String) async throws -> [GroceryItem]
    func searchProductsByBarcode(_ barcode: String) async throws -> [GroceryItem]
    func getLocalPriceComparison(for shoppingList: [GroceryItem]) async throws -> LocalPriceComparisonResult
    // Tag-related methods
    func fetchAllTags() async throws -> [Tag]
    func createTag(id: String, name: String, color: String) async throws -> Tag
    func updateTag(_ tag: Tag) async throws
    func addTagsToProduct(_ product: GroceryItem, tags: [Tag]) async throws
    func replaceTagsForProduct(_ product: GroceryItem, tags: [Tag]) async throws
    func removeTagsFromProduct(_ product: GroceryItem, tags: [Tag]) async throws
    func initializeDefaultTags() async throws
}
final class ProductRepository: ProductRepositoryProtocol, @unchecked Sendable {
    private let coreDataContainer: CoreDataContainerProtocol
    init(coreDataContainer: CoreDataContainerProtocol = CoreDataContainer()) {
        self.coreDataContainer = coreDataContainer
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
    func createProduct(id: String, productName: String, brand: String?, category: String?, price: Double, currency: String, store: String?, location: String?, imageURL: String?, barcode: String?, isInShoppingList: Bool = false, isOnSale: Bool = false) async throws -> GroceryItem {
        print("Repository: Creating product with store: '\(store ?? "nil")'")
        // Create locally first
        let product = try await coreDataContainer.createProduct(
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
        print("Repository: Product created, final store: '\(product.store ?? "nil")'")
        return product
    }
    func updateProduct(_ product: GroceryItem) async throws {
        // Update local cache
        try await coreDataContainer.updateProduct(product)
    }
    func updateProductWithPrice(product: GroceryItem, price: Double, store: String, location: String?) async throws {
        try await coreDataContainer.updateProductWithPrice(product: product, price: price, store: store, location: location)
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
        // Local-only search
        return try await coreDataContainer.searchProducts(by: name)
    }
    func searchProductsByBarcode(_ barcode: String) async throws -> [GroceryItem] {
        return try await coreDataContainer.searchProductsByBarcode(barcode)
    }
    func getLocalPriceComparison(for shoppingList: [GroceryItem]) async throws -> LocalPriceComparisonResult {
        print("Repository: Starting local price comparison for \(shoppingList.count) items")
        // Get all available stores from the database
        let allStores = try await getAllStores()
        print("Repository: Found \(allStores.count) stores in database: \(allStores)")
        guard !allStores.isEmpty else {
            print("Repository: No stores found in database")
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
        // Calculate prices for each store
        for store in allStores {
            var totalPrice: Double = 0.0
            var availableItems = 0
            var unavailableItems = 0
            var itemPrices: [String: Double] = [: ]
            var itemShoppers: [String: String] = [:]
            // For each item in the shopping list, find its price at this store
            for item in shoppingList {
                guard let productName = item.productName else { continue }
                // Find the price for this item at this store
                let itemPriceResult = try await getItemPriceAndShopperAtStore(item: item, store: store)
                if let price = itemPriceResult.price, price > 0 {
                    totalPrice += price
                    availableItems += 1
                    itemPrices[productName] = price
                    if let shopper = itemPriceResult.shopper {
                        itemShoppers[productName] = shopper
                    }
                    print("Repository: Found \(productName) at \(store) for $\(price) by \(itemPriceResult.shopper ?? "Unknown")")
                } else {
                    unavailableItems += 1
                    print("Repository: \(productName) not available at \(store)")
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
                    itemPrices: itemPrices,
                    itemShoppers: itemShoppers.isEmpty ? nil : itemShoppers
                )
                storePrices.append(storePrice)
                print("Repository: Store \(store) total: $\(totalPrice), available: \(availableItems)/\(shoppingList.count)")
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
    // Helper method to get all stores from the database
    private func getAllStores() async throws -> [String] {
        return try await coreDataContainer.getAllStores()
    }
    // Helper method to get the price of an item at a specific store
    private func getItemPriceAtStore(item: GroceryItem, store: String) async throws -> Double? {
        return try await coreDataContainer.getItemPriceAtStore(item: item, store: store)
    }
    
    // Helper method to get the price and shopper of an item at a specific store
    private func getItemPriceAndShopperAtStore(item: GroceryItem, store: String) async throws -> (price: Double?, shopper: String?) {
        return try await coreDataContainer.getItemPriceAndShopperAtStore(item: item, store: store)
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
    
    func replaceTagsForProduct(_ product: GroceryItem, tags: [Tag]) async throws {
        try await coreDataContainer.replaceTagsForProduct(product, tags: tags)
    }
    func removeTagsFromProduct(_ product: GroceryItem, tags: [Tag]) async throws {
        try await coreDataContainer.removeTagsFromProduct(product, tags: tags)
    }
    func initializeDefaultTags() async throws {
        try await coreDataContainer.initializeDefaultTags()
    }
}
// This code was generated with the help of Claude, saving me 7 hours of research and development.
