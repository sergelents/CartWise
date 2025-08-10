//
//  UserComment+CoreDataProperties.swift
//  CartWise
//
//  Created by AI Assistant on 12/19/24.
//
import Foundation
import CoreData
extension UserComment {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserComment> {
        return NSFetchRequest<UserComment>(entityName: "UserComment")
    }
    @NSManaged public var id: String?
    @NSManaged public var comment: String?
    @NSManaged public var rating: Int16
    @NSManaged public var createdAt: Date?
    @NSManaged public var user: UserEntity?
    @NSManaged public var experience: ShoppingExperience?
}
extension UserComment {
    convenience init(
        context: NSManagedObjectContext,
        id: String,
        comment: String,
        rating: Int16 = 0,
        user: UserEntity? = nil,
        experience: ShoppingExperience? = nil
    ) {
        self.init(context: context)
        self.id = id
        self.comment = comment
        self.rating = rating
        self.user = user
        self.experience = experience
        self.createdAt = Date()
    }
}
extension UserComment: Identifiable {
}
