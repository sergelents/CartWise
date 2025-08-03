//
//  UserEntity+CoreDataProperties.swift
//  CartWise
//
//  Created by Alex Kumar on 7/12/25.
//

import Foundation
import CoreData

extension UserEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserEntity> {
        return NSFetchRequest<UserEntity>(entityName: "UserEntity")
    }

    @NSManaged public var id: String?
    @NSManaged public var username: String?
    @NSManaged public var password: String?
    @NSManaged public var updates: Int32
    @NSManaged public var level: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var locations: NSSet?
    @NSManaged public var experiences: NSSet?
    @NSManaged public var comments: NSSet?
}

extension UserEntity : Identifiable {
    // Computed property for easier access to locations
    var locationArray: [Location] {
        let set = locations as? Set<Location> ?? []
        return Array(set)
    }
    
    // Computed property for easier access to experiences
    var experienceArray: [ShoppingExperience] {
        let set = experiences as? Set<ShoppingExperience> ?? []
        return Array(set).sorted { $0.createdAt ?? Date() > $1.createdAt ?? Date() }
    }
    
    // Computed property for easier access to comments
    var commentArray: [UserComment] {
        let set = comments as? Set<UserComment> ?? []
        return Array(set).sorted { $0.createdAt ?? Date() > $1.createdAt ?? Date() }
    }
}
