//
//  ShoppingExperience+CoreDataProperties.swift
//  CartWise
//
//  Created by AI Assistant on 12/19/24.
//
import Foundation
import CoreData
extension ShoppingExperience {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ShoppingExperience> {
        return NSFetchRequest<ShoppingExperience>(entityName: "ShoppingExperience")
    }
    @NSManaged public var id: String?
    @NSManaged public var comment: String?
    @NSManaged public var rating: Int16
    @NSManaged public var type: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var user: UserEntity?
    @NSManaged public var groceryItem: GroceryItem?
    @NSManaged public var location: Location?
    @NSManaged public var comments: NSSet?
}
extension ShoppingExperience {
    convenience init(context: NSManagedObjectContext, id: String, comment: String, rating: Int16 = 0, type: String? = nil, user: UserEntity? = nil, groceryItem: GroceryItem? = nil, location: Location? = nil) {
        self.init(context: context)
        self.id = id
        self.comment = comment
        self.rating = rating
        self.type = type
        self.user = user
        self.groceryItem = groceryItem
        self.location = location
        self.createdAt = Date()
    }
}
extension ShoppingExperience : Identifiable {
    // Computed property for easier access to comments
    var commentArray: [UserComment] {
        let set = comments as? Set<UserComment> ?? []
        return Array(set).sorted { $0.createdAt ?? Date() > $1.createdAt ?? Date() }
    }
    // Computed property for display name
    var displayName: String {
        if let groceryItem = groceryItem {
            return groceryItem.productName ?? "Unknown Product"
        } else if let location = location {
            return location.name ?? "Unknown Location"
        }
        return "Shopping Experience"
    }
    // Computed property for display type
    var displayType: String {
        switch type {
        case "price_update":
            return "Price Update"
        case "store_review":
            return "Store Review"
        case "product_review":
            return "Product Review"
        case "general":
            return "General Comment"
        case "new_product":
            return "New Product"
        default:
            return "Shopping Experience"
        }
    }
}