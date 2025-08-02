//
//  SocialFeedViewModel.swift
//  CartWise
//
//  Created by AI Assistant on 12/19/24.
//

import Foundation
import CoreData
import SwiftUI

@MainActor
class SocialFeedViewModel: ObservableObject {
    @Published var experiences: [ShoppingExperience] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let persistenceController = PersistenceController.shared
    
    init() {
        loadExperiences()
    }
    
    // MARK: - Public Methods
    
    func loadExperiences() {
        isLoading = true
        errorMessage = nil
        
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<ShoppingExperience> = ShoppingExperience.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ShoppingExperience.createdAt, ascending: false)]
        
        do {
            experiences = try context.fetch(request)
            isLoading = false
        } catch {
            errorMessage = "Failed to load experiences: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    func createExperience(comment: String, rating: Int16 = 0, type: String = "general", groceryItem: GroceryItem? = nil, location: Location? = nil, user: UserEntity? = nil) {
        let context = persistenceController.container.viewContext
        
        let experience = ShoppingExperience(
            context: context,
            id: UUID().uuidString,
            comment: comment,
            rating: rating,
            type: type,
            user: user,
            groceryItem: groceryItem,
            location: location
        )
        
        do {
            try context.save()
            loadExperiences() // Refresh the feed
        } catch {
            errorMessage = "Failed to create experience: \(error.localizedDescription)"
        }
    }
    
    func createComment(comment: String, rating: Int16 = 0, experience: ShoppingExperience, user: UserEntity? = nil) {
        let context = persistenceController.container.viewContext
        
        let userComment = UserComment(
            context: context,
            id: UUID().uuidString,
            comment: comment,
            rating: rating,
            user: user,
            experience: experience
        )
        
        do {
            try context.save()
            loadExperiences() // Refresh the feed
        } catch {
            errorMessage = "Failed to create comment: \(error.localizedDescription)"
        }
    }
    
    func createPriceUpdateExperience(groceryItem: GroceryItem, location: Location, price: Double, user: UserEntity? = nil) {
        let comment = "Price updated to $\(String(format: "%.2f", price)) at \(location.name ?? "Unknown Store")"
        createExperience(
            comment: comment,
            rating: 0,
            type: "price_update",
            groceryItem: groceryItem,
            location: location,
            user: user
        )
    }
    
    func createStoreReviewExperience(location: Location, comment: String, rating: Int16, user: UserEntity? = nil) {
        createExperience(
            comment: comment,
            rating: rating,
            type: "store_review",
            location: location,
            user: user
        )
    }
    
    func createProductReviewExperience(groceryItem: GroceryItem, comment: String, rating: Int16, user: UserEntity? = nil) {
        createExperience(
            comment: comment,
            rating: rating,
            type: "product_review",
            groceryItem: groceryItem,
            user: user
        )
    }
    
    func createGeneralExperience(comment: String, user: UserEntity? = nil) {
        createExperience(
            comment: comment,
            rating: 0,
            type: "general",
            user: user
        )
    }
    
    // MARK: - Helper Methods
    
    func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Unknown" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    func formatRating(_ rating: Int16) -> String {
        return String(repeating: "⭐", count: Int(rating))
    }
    
    func getCurrentUser() -> UserEntity? {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        
        do {
            let users = try context.fetch(request)
            return users.first
        } catch {
            return nil
        }
    }
    
    // MARK: - Sample Data for Testing
    
    func createSampleData() {
        let context = persistenceController.container.viewContext
        
        // Create sample user if none exists
        let user = getCurrentUser() ?? {
            let newUser = UserEntity(context: context)
            newUser.id = UUID().uuidString
            newUser.username = "SuperShopper555"
            newUser.createdAt = Date()
            return newUser
        }()
        
        // Create sample experiences
        let experience1 = ShoppingExperience(
            context: context,
            id: UUID().uuidString,
            comment: "SpaghettiO's @Albertsons => $0.89",
            rating: 4,
            type: "price_update",
            user: user
        )
        
        let experience2 = ShoppingExperience(
            context: context,
            id: UUID().uuidString,
            comment: "Winco Foods does NOT have enough cashiers today. AVOID",
            rating: 1,
            type: "store_review",
            user: user
        )
        
        do {
            try context.save()
            loadExperiences()
        } catch {
            errorMessage = "Failed to create sample data: \(error.localizedDescription)"
        }
    }
} 