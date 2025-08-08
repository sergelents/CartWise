//
//  GroceryItemPrice+CoreDataProperties.swift
//  CartWise
//
//  Created by AI Assistant on 12/19/24.
//
import Foundation
import CoreData
extension GroceryItemPrice {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<GroceryItemPrice> {
        return NSFetchRequest<GroceryItemPrice>(entityName: "GroceryItemPrice")
    }
    @NSManaged public var id: String?
    @NSManaged public var price: Double
    @NSManaged public var currency: String?
    @NSManaged public var store: String?
    @NSManaged public var lastUpdated: Date?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedBy: String?
    @NSManaged public var groceryItem: GroceryItem?
    @NSManaged public var location: Location?
}
extension GroceryItemPrice {
    convenience init(context: NSManagedObjectContext, id: String, price: Double, currency: String = "USD", store: String? = nil, groceryItem: GroceryItem, location: Location, updatedBy: String? = nil) {
        self.init(context: context)
        self.id = id
        self.price = price
        self.currency = currency
        self.store = store
        self.groceryItem = groceryItem
        self.location = location
        self.updatedBy = updatedBy
        self.createdAt = Date()
        self.lastUpdated = Date()
    }
}
extension GroceryItemPrice: Identifiable {
}
