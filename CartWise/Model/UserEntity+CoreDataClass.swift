//
//  UserEntity+CoreDataClass.swift
//  CartWise
//
//  Created by Alex Kumar on 7/12/25.
//

import Foundation
import CoreData

@objc(UserEntity)
public class UserEntity: NSManagedObject {
    
    // MARK: - Reputation System Methods
    
    func addContributionPoints(_ points: Int32) {
        contributionPoints += points
        totalContributions += 1
        lastContributionDate = Date()
        updateReputationLevel()
    }
    
    func addPriceUpdate() {
        // priceUpdates += 1  // Commented out until Core Data is regenerated
        addContributionPoints(10)
    }
    
    func addProductAddition() {
        productAdditions += 1
        addContributionPoints(25)
    }
    
    func addReviewSubmission() {
        reviewsSubmitted += 1
        addContributionPoints(15)
    }
    
    private func updateReputationLevel() {
        let level = ReputationManager.getLevelForPoints(contributionPoints)
        reputationLevel = level
    }
    
    func getEarnedBadges() -> [String] {
        guard let badgesData = achievementBadges,
              let data = badgesData.data(using: .utf8),
              let badges = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return badges
    }
    
    func addBadge(_ badge: String) {
        var currentBadges = getEarnedBadges()
        if !currentBadges.contains(badge) {
            currentBadges.append(badge)
            if let badgesData = try? JSONEncoder().encode(currentBadges),
               let badgesString = String(data: badgesData, encoding: .utf8) {
                achievementBadges = badgesString
            }
        }
    }
}
