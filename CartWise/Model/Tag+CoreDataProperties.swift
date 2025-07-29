//
//  Tag+CoreDataProperties.swift
//  CartWise
//
//  Created by Brenna Wilson on 7/27/25.
//

import Foundation
import CoreData

extension Tag {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Tag> {
        return NSFetchRequest<Tag>(entityName: "Tag")
    }

    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var color: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var products: NSSet?
}

extension Tag {
    convenience init(context: NSManagedObjectContext, id: String, name: String, color: String = "#007AFF") {
        self.init(context: context)
        self.id = id
        self.name = name
        self.color = color
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

extension Tag : Identifiable {
    // Computed properties for easier access
    var displayName: String {
        return name ?? "Unnamed Tag"
    }
    
    var displayColor: String {
        return color ?? "#007AFF"
    }
    
    var productArray: [GroceryItem] {
        let set = products as? Set<GroceryItem> ?? []
        return Array(set)
    }
} 