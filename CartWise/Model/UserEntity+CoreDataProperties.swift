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
    
    // Reputation System Properties
    @NSManaged public var contributionPoints: Int32
    @NSManaged public var reputationLevel: String?
    @NSManaged public var totalContributions: Int32
    @NSManaged public var priceUpdates: Int32
    @NSManaged public var productAdditions: Int32
    @NSManaged public var reviewsSubmitted: Int32
    @NSManaged public var lastContributionDate: Date?
    @NSManaged public var achievementBadges: String? // JSON string of earned badges
}

extension UserEntity : Identifiable {
}
