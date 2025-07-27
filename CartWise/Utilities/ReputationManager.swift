//
//  ReputationManager.swift
//  CartWise
//
//  Created by Alex Kumar on 7/12/25.
//

import Foundation
import SwiftUI

class ReputationManager: ObservableObject {
    static let shared = ReputationManager()
    
    private init() {}
    
    // MARK: - Reputation Levels
    struct ReputationLevel {
        let name: String
        let minPoints: Int32
        let color: Color
        let icon: String
        let description: String
    }
    
    static let reputationLevels: [ReputationLevel] = [
        ReputationLevel(name: "Newbie", minPoints: 0, color: .gray, icon: "star", description: "Just getting started"),
        ReputationLevel(name: "Contributor", minPoints: 50, color: .blue, icon: "star.fill", description: "Making contributions"),
        ReputationLevel(name: "Helper", minPoints: 150, color: .green, icon: "star.circle", description: "Helping the community"),
        ReputationLevel(name: "Expert", minPoints: 300, color: .orange, icon: "star.circle.fill", description: "Knowledgeable contributor"),
        ReputationLevel(name: "Master", minPoints: 600, color: .purple, icon: "crown", description: "Master of shopping"),
        ReputationLevel(name: "Legend", minPoints: 1000, color: .red, icon: "crown.fill", description: "Shopping legend"),
        ReputationLevel(name: "Grandmaster", minPoints: 2000, color: .yellow, icon: "crown.circle", description: "Ultimate shopping expert")
    ]
    
    // MARK: - Achievement Badges
    struct Achievement {
        let id: String
        let name: String
        let description: String
        let icon: String
        let color: Color
        let requirement: String
    }
    
    static let achievements: [Achievement] = [
        Achievement(id: "first_contribution", name: "First Step", description: "Made your first contribution", icon: "1.circle.fill", color: .blue, requirement: "1 contribution"),
        Achievement(id: "price_updater", name: "Price Watcher", description: "Updated 10 prices", icon: "dollarsign.circle.fill", color: .green, requirement: "10 price updates"),
        Achievement(id: "product_adder", name: "Product Scout", description: "Added 5 new products", icon: "plus.circle.fill", color: .orange, requirement: "5 product additions"),
        Achievement(id: "reviewer", name: "Reviewer", description: "Submitted 3 reviews", icon: "star.circle.fill", color: .yellow, requirement: "3 reviews"),
        Achievement(id: "contributor_50", name: "Active Contributor", description: "Reached 50 contribution points", icon: "50.circle.fill", color: .purple, requirement: "50 points"),
        Achievement(id: "contributor_100", name: "Dedicated Helper", description: "Reached 100 contribution points", icon: "100.circle.fill", color: .red, requirement: "100 points"),
        Achievement(id: "contributor_500", name: "Community Expert", description: "Reached 500 contribution points", icon: "500.circle.fill", color: .indigo, requirement: "500 points"),
        Achievement(id: "daily_streak", name: "Daily Helper", description: "Contributed for 7 consecutive days", icon: "calendar.circle.fill", color: .pink, requirement: "7-day streak"),
        Achievement(id: "variety_contributor", name: "Versatile Helper", description: "Contributed in all categories", icon: "square.grid.3x3.fill", color: .teal, requirement: "All contribution types")
    ]
    
    // MARK: - Public Methods
    
    static func getLevelForPoints(_ points: Int32) -> String {
        let level = reputationLevels.last { $0.minPoints <= points } ?? reputationLevels[0]
        return level.name
    }
    
    static func getLevelInfo(for points: Int32) -> ReputationLevel {
        return reputationLevels.last { $0.minPoints <= points } ?? reputationLevels[0]
    }
    
    static func getNextLevelInfo(for points: Int32) -> ReputationLevel? {
        return reputationLevels.first { $0.minPoints > points }
    }
    
    static func getProgressToNextLevel(currentPoints: Int32) -> Double {
        let currentLevel = getLevelInfo(for: currentPoints)
        guard let nextLevel = getNextLevelInfo(for: currentPoints) else {
            return 1.0 // Already at max level
        }
        
        let pointsInCurrentLevel = currentPoints - currentLevel.minPoints
        let pointsNeededForNextLevel = nextLevel.minPoints - currentLevel.minPoints
        
        return Double(pointsInCurrentLevel) / Double(pointsNeededForNextLevel)
    }
    
    static func checkAchievements(for user: UserEntity) -> [String] {
        var newAchievements: [String] = []
        
        // Check contribution-based achievements
        if user.totalContributions >= 1 && !user.getEarnedBadges().contains("first_contribution") {
            newAchievements.append("first_contribution")
        }
        
        if user.priceUpdates >= 10 && !user.getEarnedBadges().contains("price_updater") {
            newAchievements.append("price_updater")
        }
        
        if user.productAdditions >= 5 && !user.getEarnedBadges().contains("product_adder") {
            newAchievements.append("product_adder")
        }
        
        if user.reviewsSubmitted >= 3 && !user.getEarnedBadges().contains("reviewer") {
            newAchievements.append("reviewer")
        }
        
        if user.contributionPoints >= 50 && !user.getEarnedBadges().contains("contributor_50") {
            newAchievements.append("contributor_50")
        }
        
        if user.contributionPoints >= 100 && !user.getEarnedBadges().contains("contributor_100") {
            newAchievements.append("contributor_100")
        }
        
        if user.contributionPoints >= 500 && !user.getEarnedBadges().contains("contributor_500") {
            newAchievements.append("contributor_500")
        }
        
        return newAchievements
    }
    
    static func getAchievement(by id: String) -> Achievement? {
        return achievements.first { $0.id == id }
    }
    
    static func getContributionPoints(for action: ContributionAction) -> Int32 {
        switch action {
        case .priceUpdate:
            return 10
        case .productAddition:
            return 25
        case .reviewSubmission:
            return 15
        case .photoUpload:
            return 20
        case .storeReview:
            return 30
        }
    }
}

// MARK: - Contribution Actions
enum ContributionAction {
    case priceUpdate
    case productAddition
    case reviewSubmission
    case photoUpload
    case storeReview
} 