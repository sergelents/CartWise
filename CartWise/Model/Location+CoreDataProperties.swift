//
//  Location+CoreDataProperties.swift
//  CartWise
//
//  Created by AI Assistant on 12/19/24.
//
import Foundation
import CoreData
extension Location {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Location> {
        return NSFetchRequest<Location>(entityName: "Location")
    }
    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var address: String?
    @NSManaged public var city: String?
    @NSManaged public var state: String?
    @NSManaged public var zipCode: String?
    @NSManaged public var favorited: Bool
    @NSManaged public var isDefault: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var user: UserEntity?
    @NSManaged public var groceryItems: NSSet?
    @NSManaged public var prices: NSSet?
    @NSManaged public var experiences: NSSet?
}
extension Location {
    convenience init(context: NSManagedObjectContext, id: String, name: String, address: String, city: String, state: String, zipCode: String, favorited: Bool = false, isDefault: Bool = false) {
        self.init(context: context)
        self.id = id
        self.name = name
        self.address = address
        self.city = city
        self.state = state
        self.zipCode = zipCode
        self.favorited = favorited
        self.isDefault = isDefault
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
extension Location: Identifiable {
    // Computed property for easier access to grocery items
    var groceryItemArray: [GroceryItem] {
        let set = groceryItems as? Set<GroceryItem> ?? []
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
}
