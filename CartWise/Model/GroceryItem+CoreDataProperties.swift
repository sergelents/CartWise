//
//  GroceryItem+CoreDataProperties.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/7/25.
//
import Foundation
import CoreData
import UIKit
extension GroceryItem {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<GroceryItem> {
        return NSFetchRequest<GroceryItem>(entityName: "GroceryItem")
    }
    @NSManaged public var id: String?
    @NSManaged public var productName: String?
    @NSManaged public var brand: String?
    @NSManaged public var category: String?
    @NSManaged public var lastUpdated: Date?
    @NSManaged public var barcode: String?
    @NSManaged public var productImage: ProductImage?
    @NSManaged public var isCompleted: Bool
    @NSManaged public var isInShoppingList: Bool
    @NSManaged public var isFavorite: Bool
    @NSManaged public var isOnSale: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var tags: NSSet?
    @NSManaged public var locations: NSSet?
    @NSManaged public var prices: NSSet?
    @NSManaged public var experiences: NSSet?
}
extension GroceryItem {
    convenience init(context: NSManagedObjectContext, id: String, productName: String, brand: String? = nil, category: String? = nil, barcode: String? = nil, isOnSale: Bool = false) {
        self.init(context: context)
        self.id = id
        self.productName = productName
        self.brand = brand
        self.category = category
        self.barcode = barcode
        self.isCompleted = false
        self.isInShoppingList = false
        self.isFavorite = false
        self.isOnSale = isOnSale
        self.createdAt = Date()
        self.updatedAt = Date()
        self.lastUpdated = Date()
    }
}
extension GroceryItem : Identifiable {
    // Computed property for easier access to tags
    var tagArray: [Tag] {
        let set = tags as? Set<Tag> ?? []
        return Array(set)
    }
    // Computed property for easier access to locations
    var locationArray: [Location] {
        let set = locations as? Set<Location> ?? []
        return Array(set)
    }
    // Computed property for easier access to prices
    var priceArray: [GroceryItemPrice] {
        let set = prices as? Set<GroceryItemPrice> ?? []
        return Array(set)
    }
    // Computed property for easier access to experiences
    var experienceArray: [ShoppingExperience] {
        let set = experiences as? Set<ShoppingExperience> ?? []
        return Array(set).sorted { $0.createdAt ?? Date() > $1.createdAt ?? Date() }
    }
    // Helper method to get the current price at a specific location
    func getPrice(at location: Location) -> GroceryItemPrice? {
        return priceArray.first { $0.location == location }
    }
    // Helper method to get all prices across all locations
    func getAllPrices() -> [GroceryItemPrice] {
        return priceArray
    }
    // Helper method to get the lowest price
    func getLowestPrice() -> GroceryItemPrice? {
        return priceArray.min { $0.price < $1.price }
    }
    // Helper method to get the highest price
    func getHighestPrice() -> GroceryItemPrice? {
        return priceArray.max { $0.price < $1.price }
    }
    // Backward compatibility properties
    var price: Double {
        return getLowestPrice()?.price ?? 0.0
    }
    var store: String? {
        return getLowestPrice()?.store
    }
    var location: String? {
        return getLowestPrice()?.location?.name
    }
    var currency: String? {
        return getLowestPrice()?.currency
    }
    
    // Image compatibility properties
    var imageURL: String? {
        return productImage?.imageURL
    }
    
    var imageData: Data? {
        return productImage?.imageData
    }
    
    var uiImage: UIImage? {
        return productImage?.uiImage
    }
}