//
//  ReputationViewModel.swift
//  CartWise
//
//  Created by Alex Kumar on 7/12/25.
//

import Foundation
import CoreData
import SwiftUI

class ReputationViewModel: ObservableObject {
    @Published var currentUser: UserEntity?
    @Published var isLoading = false
    @Published var showAchievementAlert = false
    @Published var newAchievement: ReputationManager.Achievement?
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }
    
    // MARK: - User Management
    
    func loadCurrentUser() async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \UserEntity.createdAt, ascending: false)]
            fetchRequest.fetchLimit = 1
            
            let users = try context.fetch(fetchRequest)
            
            await MainActor.run {
                currentUser = users.first
                isLoading = false
            }
        } catch {
            print("Error loading current user: \(error)")
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    func getCurrentUser() -> UserEntity? {
        return currentUser
    }
    
    // MARK: - Contribution Methods
    
    func addContribution(_ action: ContributionAction) async {
        guard let user = currentUser else { return }
        
        do {
            switch action {
            case .priceUpdate:
                user.addPriceUpdate()
            case .productAddition:
                user.addProductAddition()
            case .reviewSubmission:
                user.addReviewSubmission()
            case .photoUpload:
                user.addContributionPoints(20)
            case .storeReview:
                user.addContributionPoints(30)
            }
            
            // Check for new achievements
            let newAchievements = ReputationManager.checkAchievements(for: user)
            
            for achievementId in newAchievements {
                user.addBadge(achievementId)
                if let achievement = ReputationManager.getAchievement(by: achievementId) {
                    await MainActor.run {
                        newAchievement = achievement
                        showAchievementAlert = true
                    }
                }
            }
            
            try context.save()
            
            await MainActor.run {
                objectWillChange.send()
            }
            
        } catch {
            print("Error adding contribution: \(error)")
        }
    }
    
    func addPriceUpdate() async {
        await addContribution(.priceUpdate)
    }
    
    func addProductAddition() async {
        await addContribution(.productAddition)
    }
    
    func addReviewSubmission() async {
        await addContribution(.reviewSubmission)
    }
    
    func addPhotoUpload() async {
        await addContribution(.photoUpload)
    }
    
    func addStoreReview() async {
        await addContribution(.storeReview)
    }
    
    // MARK: - Reputation Data
    
    func getCurrentLevel() -> ReputationManager.ReputationLevel {
        guard let user = currentUser else {
            return ReputationManager.reputationLevels[0]
        }
        return ReputationManager.getLevelInfo(for: user.contributionPoints)
    }
    
    func getNextLevel() -> ReputationManager.ReputationLevel? {
        guard let user = currentUser else { return nil }
        return ReputationManager.getNextLevelInfo(for: user.contributionPoints)
    }
    
    func getProgressToNextLevel() -> Double {
        guard let user = currentUser else { return 0.0 }
        return ReputationManager.getProgressToNextLevel(currentPoints: user.contributionPoints)
    }
    
    func getContributionStats() -> ContributionStats {
        guard let user = currentUser else {
            return ContributionStats(points: 0, totalContributions: 0, priceUpdates: 0, productAdditions: 0, reviewsSubmitted: 0)
        }
        
        return ContributionStats(
            points: user.contributionPoints,
            totalContributions: user.totalContributions,
            priceUpdates: 0, // Temporary fix until Core Data is regenerated
            productAdditions: user.productAdditions,
            reviewsSubmitted: user.reviewsSubmitted
        )
    }
    
    func getEarnedAchievements() -> [ReputationManager.Achievement] {
        guard let user = currentUser else { return [] }
        
        let earnedBadgeIds = user.getEarnedBadges()
        return earnedBadgeIds.compactMap { ReputationManager.getAchievement(by: $0) }
    }
    
    func getAvailableAchievements() -> [ReputationManager.Achievement] {
        return ReputationManager.achievements
    }
    
    func getRecentContributions() -> [ContributionRecord] {
        guard let user = currentUser,
              let lastContribution = user.lastContributionDate else { return [] }
        
        // In a real app, you'd fetch from a separate contributions table
        // For now, we'll create a mock record based on the last contribution
        let record = ContributionRecord(
            id: UUID().uuidString,
            type: "Contribution",
            points: user.contributionPoints,
            date: lastContribution,
            description: "Last contribution"
        )
        
        return [record]
    }
}

// MARK: - Supporting Structures

struct ContributionStats {
    let points: Int32
    let totalContributions: Int32
    let priceUpdates: Int32
    let productAdditions: Int32
    let reviewsSubmitted: Int32
}

struct ContributionRecord {
    let id: String
    let type: String
    let points: Int32
    let date: Date
    let description: String
} 
