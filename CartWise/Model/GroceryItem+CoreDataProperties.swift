//
//  GroceryItem+CoreDataProperties.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/7/25.
//

import Foundation
import CoreData

extension GroceryItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<GroceryItem> {
        return NSFetchRequest<GroceryItem>(entityName: "GroceryItem")
    }

    @NSManaged public var id: String?
    @NSManaged public var productName: String?
    @NSManaged public var brand: String?
    @NSManaged public var category: String?
    @NSManaged public var price: Double
    @NSManaged public var currency: String?
    @NSManaged public var store: String?
    @NSManaged public var location: String?
    @NSManaged public var lastUpdated: Date?
    @NSManaged public var imageURL: String?
    @NSManaged public var barcode: String?
    @NSManaged public var isCompleted: Bool
    @NSManaged public var isInShoppingList: Bool
    @NSManaged public var isFavorite: Bool
    @NSManaged public var isOnSale: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?

}

extension GroceryItem {
    convenience init(context: NSManagedObjectContext, id: String, productName: String, brand: String? = nil, category: String? = nil, price: Double = 0.0, currency: String = "USD", store: String? = nil, location: String? = nil, imageURL: String? = nil, barcode: String? = nil, isOnSale: Bool = false) {
        self.init(context: context)
        self.id = id
        self.productName = productName
        self.brand = brand
        self.category = category
        self.price = price
        self.currency = currency
        self.store = store
        self.location = location
        self.imageURL = imageURL
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

} 