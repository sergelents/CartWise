//
//  Repository.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/7/25.
//
import Foundation
import CoreData

/// Protocol defining the contract for product and shopping list data operations.
/// All methods are async and can throw errors for proper error handling.
/// This protocol follows the Repository pattern to abstract data layer operations.
protocol ProductRepositoryProtocol: Sendable {
    // MARK: - Product Operations
    
    /// Fetches all products from the data store
    /// - Returns: Array of all grocery items
    func fetchAllProducts() async throws -> [GroceryItem]
    
    /// Fetches only products that are in the shopping list
    /// - Returns: Array of grocery items in shopping list
    func fetchListProducts() async throws -> [GroceryItem]
    
    /// Creates a new product in the data store
    /// - Parameters:
    ///   - id: Unique identifier for the product
    ///   - productName: Name of the product
    ///   - brand: Optional brand name
    ///   - category: Optional product category
    ///   - price: Product price
    ///   - currency: Currency code (e.g., "USD")
    ///   - store: Optional store name
    ///   - location: Optional location address
    ///   - imageURL: Optional product image URL
    ///   - barcode: Optional product barcode
    ///   - isInShoppingList: Whether to add to shopping list
    ///   - isOnSale: Whether product is on sale
    /// - Returns: The created grocery item
    func createProduct(
        id: String,
        productName: String,
        brand: String?,
        category: String?,
        price: Double,
        currency: String,
        store: String?,
        location: String?,
        imageURL: String?,
        barcode: String?,
        isInShoppingList: Bool,
        isOnSale: Bool
    ) async throws -> GroceryItem
    
    /// Updates an existing product
    /// - Parameter product: The product to update
    func updateProduct(_ product: GroceryItem) async throws
    
    /// Updates a product's price at a specific store (also updates reputation)
    /// - Parameters:
    ///   - product: The product to update
    ///   - price: New price value
    ///   - store: Store name
    ///   - location: Optional location address
    func updateProductWithPrice(product: GroceryItem, price: Double, store: String, location: String?) async throws
    
    /// Permanently deletes a product from the data store
    /// - Parameter product: The product to delete
    func deleteProduct(_ product: GroceryItem) async throws
    
    // MARK: - Shopping List Operations
    
    /// Removes a product from shopping list (soft delete - product still exists)
    /// - Parameter product: The product to remove from shopping list
    func removeProductFromShoppingList(_ product: GroceryItem) async throws
    
    /// Toggles the completion status of a product in shopping list
    /// - Parameter product: The product to toggle
    func toggleProductCompletion(_ product: GroceryItem) async throws
    
    /// Adds an existing product to the shopping list
    /// - Parameter product: The product to add
    func addProductToShoppingList(_ product: GroceryItem) async throws
    
    // MARK: - Favorites Operations
    
    /// Fetches all products marked as favorites
    /// - Returns: Array of favorite grocery items
    func fetchFavoriteProducts() async throws -> [GroceryItem]
    
    /// Adds a product to favorites
    /// - Parameter product: The product to favorite
    func addProductToFavorites(_ product: GroceryItem) async throws
    
    /// Removes a product from favorites
    /// - Parameter product: The product to unfavorite
    func removeProductFromFavorites(_ product: GroceryItem) async throws
    
    /// Toggles the favorite status of a product
    /// - Parameter product: The product to toggle
    func toggleProductFavorite(_ product: GroceryItem) async throws
    
    // MARK: - Search Operations
    
    /// Searches for products by name
    /// - Parameter name: Product name to search for
    /// - Returns: Array of matching grocery items
    func searchProducts(by name: String) async throws -> [GroceryItem]
    
    /// Searches for products by barcode
    /// - Parameter barcode: Barcode string to search for
    /// - Returns: Array of matching grocery items
    func searchProductsByBarcode(_ barcode: String) async throws -> [GroceryItem]
    
    // MARK: - Price Comparison
    
    /// Compares prices across stores for a shopping list
    /// - Parameter shoppingList: Array of products to compare
    /// - Returns: Price comparison result with store totals
    func getLocalPriceComparison(for shoppingList: [GroceryItem]) async throws -> LocalPriceComparisonResult
    
    // MARK: - Tag Operations
    
    /// Fetches all available tags
    /// - Returns: Array of tags
    func fetchAllTags() async throws -> [Tag]
    
    /// Creates a new tag
    /// - Parameters:
    ///   - id: Unique identifier for the tag
    ///   - name: Tag name
    ///   - color: Tag color code
    /// - Returns: The created tag
    func createTag(id: String, name: String, color: String) async throws -> Tag
    
    /// Updates an existing tag
    /// - Parameter tag: The tag to update
    func updateTag(_ tag: Tag) async throws
    
    /// Adds tags to a product
    /// - Parameters:
    ///   - product: The product to tag
    ///   - tags: Array of tags to add
    func addTagsToProduct(_ product: GroceryItem, tags: [Tag]) async throws
    
    /// Replaces all tags for a product
    /// - Parameters:
    ///   - product: The product to update
    ///   - tags: New array of tags
    func replaceTagsForProduct(_ product: GroceryItem, tags: [Tag]) async throws
    
    /// Removes specific tags from a product
    /// - Parameters:
    ///   - product: The product to update
    ///   - tags: Array of tags to remove
    func removeTagsFromProduct(_ product: GroceryItem, tags: [Tag]) async throws
    
    /// Initializes default tags in the system
    func initializeDefaultTags() async throws
    
    // MARK: - Product Image Operations
    
    /// Saves a product image
    /// - Parameters:
    ///   - product: The product to associate the image with
    ///   - imageURL: URL string of the image
    ///   - imageData: Optional image binary data
    func saveProductImage(for product: GroceryItem, imageURL: String, imageData: Data?) async throws
    
    /// Retrieves a product's image
    /// - Parameter product: The product to get image for
    /// - Returns: ProductImage if exists, nil otherwise
    func getProductImage(for product: GroceryItem) async throws -> ProductImage?
    
    /// Deletes a product's image
    /// - Parameter product: The product whose image to delete
    func deleteProductImage(for product: GroceryItem) async throws
    
    // MARK: - Location Operations
    
    /// Fetches all locations for the current user
    /// - Returns: Array of user's locations
    func fetchUserLocations() async throws -> [Location]
    
    /// Creates a new location
    /// - Parameters:
    ///   - id: Unique identifier for the location
    ///   - name: Location/store name
    ///   - address: Street address
    ///   - city: City name
    ///   - state: State/province
    ///   - zipCode: Postal code
    /// - Returns: The created location
    func createLocation(id: String, name: String, address: String, city: String, state: String, zipCode: String) async throws -> Location
    
    /// Updates an existing location
    /// - Parameter location: The location to update
    func updateLocation(_ location: Location) async throws
    
    /// Deletes a location
    /// - Parameter location: The location to delete
    func deleteLocation(_ location: Location) async throws
    
    /// Toggles the favorite status of a location
    /// - Parameter location: The location to toggle
    func toggleLocationFavorite(_ location: Location) async throws
    
    /// Sets a location as the default location
    /// - Parameter location: The location to set as default
    func setLocationAsDefault(_ location: Location) async throws
}

// MARK: - Repository Implementation

/// Concrete implementation of ProductRepositoryProtocol.
/// Uses CoreDataContainer for data persistence operations.
/// Follows the Repository pattern to provide a clean abstraction over data operations.
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
    func createProduct(
        id: String,
        productName: String,
        brand: String?,
        category: String?,
        price: Double,
        currency: String,
        store: String?,
        location: String?,
        imageURL: String?,
        barcode: String?,
        isInShoppingList: Bool = false,
        isOnSale: Bool = false
    ) async throws -> GroceryItem {
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
        try await coreDataContainer.updateProductWithPrice(
            product: product,
            price: price,
            store: store,
            location: location
        )
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
                    print("Repository: Found \(productName) at \(store) for $\(price) " +
                          "by \(itemPriceResult.shopper ?? "Unknown")")
                } else {
                    unavailableItems += 1
                    print("Repository: \(productName) not available at \(store)")
                }
            }
            // Calculate availability percentage
            let availabilityPercentage = Double(availableItems) / Double(shoppingList.count)
            let minimumAvailability = 0.85 // 85% minimum availability threshold

            // Only include stores that have at least 85% of items available
            if availableItems > 0 && availabilityPercentage >= minimumAvailability {
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
                print("Repository: Store \(store) total: $\(totalPrice), " +
                      "available: \(availableItems)/\(shoppingList.count) " +
                      "(\(String(format: "%.1f", availabilityPercentage * 100))%) - INCLUDED")
            } else {
                print("Repository: Store \(store) available: \(availableItems)/\(shoppingList.count) " +
                      "(\(String(format: "%.1f", availabilityPercentage * 100))%) - " +
                      "EXCLUDED (below 85% threshold)")
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
        let storeList = top3StorePrices.map { "\($0.store): $\($0.totalPrice)" }.joined(separator: ", ")
        print("Repository: Local price comparison complete. Top 3 stores: \(storeList)")
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
    private func getItemPriceAndShopperAtStore(
        item: GroceryItem,
        store: String
    ) async throws -> (price: Double?, shopper: String?) {
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

    // MARK: - ProductImage Methods
    func saveProductImage(for product: GroceryItem, imageURL: String, imageData: Data?) async throws {
        try await coreDataContainer.saveProductImage(for: product, imageURL: imageURL, imageData: imageData)
    }

    func getProductImage(for product: GroceryItem) async throws -> ProductImage? {
        return try await coreDataContainer.getProductImage(for: product)
    }

    func deleteProductImage(for product: GroceryItem) async throws {
        try await coreDataContainer.deleteProductImage(for: product)
    }
    
    // MARK: - Location Methods
    
    func fetchUserLocations() async throws -> [Location] {
        return try await coreDataContainer.fetchUserLocations()
    }
    
    func createLocation(id: String, name: String, address: String, city: String, state: String, zipCode: String) async throws -> Location {
        return try await coreDataContainer.createLocation(id: id, name: name, address: address, city: city, state: state, zipCode: zipCode)
    }
    
    func updateLocation(_ location: Location) async throws {
        try await coreDataContainer.updateLocation(location)
    }
    
    func deleteLocation(_ location: Location) async throws {
        try await coreDataContainer.deleteLocation(location)
    }
    
    func toggleLocationFavorite(_ location: Location) async throws {
        try await coreDataContainer.toggleLocationFavorite(location)
    }
    
    func setLocationAsDefault(_ location: Location) async throws {
        try await coreDataContainer.setLocationAsDefault(location)
    }
}
// This code was generated with the help of Claude, saving me 7 hours of research and development.
