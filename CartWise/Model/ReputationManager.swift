//
//  ReputationManager.swift
//  CartWise
//
//  Created by CartWise Development Team on 12/19/24.
//

import Foundation
import CoreData

class ReputationManager: ObservableObject {
    static let shared = ReputationManager()
    
    private init() {}
    
    func updateUserReputation(userId: String) async {
        // Use CoreDataStack to ensure we're in the right context
        let context = await CoreDataStack.shared.viewContext
        
        do {
            let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", userId)
            
            let users = try context.fetch(fetchRequest)
            
            if let user = users.first {
                // Increment updates count
                user.updates += 1
                
                // Update level based on new count
                let newLevel = ReputationSystem.shared.getCurrentLevel(updates: Int(user.updates))
                user.level = newLevel.name
                
                // Save to Core Data
                try context.save()
                
                print("Updated reputation for user \(userId): \(user.updates) updates, level: \(newLevel.name)")
            } else {
                // Try to find user by username if ID not found
                let usernameFetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
                usernameFetchRequest.predicate = NSPredicate(format: "username == %@", userId)
                
                let usersByUsername = try context.fetch(usernameFetchRequest)
                
                if let user = usersByUsername.first {
                    // Increment updates count
                    user.updates += 1
                    
                    // Update level based on new count
                    let newLevel = ReputationSystem.shared.getCurrentLevel(updates: Int(user.updates))
                    user.level = newLevel.name
                    
                    // Save to Core Data
                    try context.save()
                    
                    print("Updated reputation for user \(userId): \(user.updates) updates, level: \(newLevel.name)")
                }
            }
        } catch {
            print("Error updating user reputation: \(error)")
        }
    }
    
    func getUserReputation(userId: String) async -> (updates: Int, level: String)? {
        let context = await CoreDataStack.shared.viewContext
        
        do {
            let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", userId)
            
            let users = try context.fetch(fetchRequest)
            
            if let user = users.first {
                return (Int(user.updates), user.level ?? "New Shopper")
            }
        } catch {
            print("Error fetching user reputation: \(error)")
        }
        
        return nil
    }
    
    func getCurrentUserReputation() async -> (updates: Int, level: String)? {
        let context = await CoreDataStack.shared.viewContext
        
        do {
            let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \UserEntity.createdAt, ascending: false)]
            fetchRequest.fetchLimit = 1
            
            let users = try context.fetch(fetchRequest)
            
            if let user = users.first {
                print("ReputationManager: Found user \(user.username ?? "Unknown") with \(user.updates) updates, level: \(user.level ?? "None")")
                return (Int(user.updates), user.level ?? "New Shopper")
            } else {
                print("ReputationManager: No users found")
            }
        } catch {
            print("Error fetching current user reputation: \(error)")
        }
        
        return nil
    }
    
    // Debug function to manually test reputation updates
    func debugReputationUpdate() async {
        let context = await CoreDataStack.shared.viewContext
        
        do {
            let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \UserEntity.createdAt, ascending: false)]
            fetchRequest.fetchLimit = 1
            
            let users = try context.fetch(fetchRequest)
            
            if let user = users.first {
                print("Debug: Current user \(user.username ?? "Unknown") has \(user.updates) updates")
                
                // Manually increment updates
                user.updates += 1
                let newLevel = ReputationSystem.shared.getCurrentLevel(updates: Int(user.updates))
                user.level = newLevel.name
                
                try context.save()
                
                print("Debug: Updated user to \(user.updates) updates, level: \(newLevel.name)")
            } else {
                print("Debug: No users found")
            }
        } catch {
            print("Debug: Error updating reputation: \(error)")
        }
    }
} 