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
        // Ensure all objects are in the same context
        let contextGroceryItem: GroceryItem?
        let contextLocation: Location?
        let contextUser: UserEntity?
        if let groceryItem = groceryItem {
            contextGroceryItem = context.object(with: groceryItem.objectID) as? GroceryItem
            print("GroceryItem context conversion: \(groceryItem.managedObjectContext?.description ?? "nil") -> \(contextGroceryItem?.managedObjectContext?.description ?? "nil")")
        } else {
            contextGroceryItem = nil
        }
        if let location = location {
            contextLocation = context.object(with: location.objectID) as? Location
            print("Location context conversion: \(location.managedObjectContext?.description ?? "nil") -> \(contextLocation?.managedObjectContext?.description ?? "nil")")
        } else {
            contextLocation = nil
        }
        if let user = user {
            contextUser = context.object(with: user.objectID) as? UserEntity
            print("User context conversion: \(user.managedObjectContext?.description ?? "nil") -> \(contextUser?.managedObjectContext?.description ?? "nil")")
        } else {
            contextUser = nil
        }
        let experience = ShoppingExperience(
            context: context,
            id: UUID().uuidString,
            comment: comment,
            rating: rating,
            type: type,
            user: contextUser,
            groceryItem: contextGroceryItem,
            location: contextLocation
        )
        do {
            try context.save()
            loadExperiences() // Refresh the feed
        } catch {
            print("Core Data save error: \(error)")
            errorMessage = "Failed to create experience: \(error.localizedDescription)"
        }
    }
    func createComment(comment: String, rating: Int16 = 0, experience: ShoppingExperience, user: UserEntity? = nil) {
        let context = persistenceController.container.viewContext
        // Ensure all objects are in the same context
        let contextExperience = context.object(with: experience.objectID) as? ShoppingExperience
        let contextUser: UserEntity?
        if let user = user {
            contextUser = context.object(with: user.objectID) as? UserEntity
        } else {
            contextUser = nil
        }
        let userComment = UserComment(
            context: context,
            id: UUID().uuidString,
            comment: comment,
            rating: rating,
            user: contextUser,
            experience: contextExperience
        )
        do {
            try context.save()
            loadExperiences() // Refresh the feed
        } catch {
            print("Core Data save error: \(error)")
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
        // Get the current username from UserDefaults
        let currentUsername = UserDefaults.standard.string(forKey: "currentUsername")
        if let username = currentUsername {
            // Find the user with the current username
            request.predicate = NSPredicate(format: "username == %@", username)
        } else {
            // Fallback to the most recently created user
            request.sortDescriptors = [NSSortDescriptor(keyPath: \UserEntity.createdAt, ascending: false)]
            request.fetchLimit = 1
        }
        do {
            let users = try context.fetch(request)
            let user = users.first
            print("getCurrentUser: Found user \(user?.username ?? "nil") in context \(user?.managedObjectContext?.description ?? "nil")")
            return user
        } catch {
            print("getCurrentUser error: \(error)")
            return nil
        }
    }
}