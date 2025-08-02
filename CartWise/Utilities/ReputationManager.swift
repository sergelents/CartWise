//
//  ReputationManager.swift
//  CartWise
//
//  Created by AI Assistant on 12/19/24.
//

import Foundation
import CoreData

class ReputationManager {
    static let shared = ReputationManager()
    
    private init() {}
    
    func updateUserReputation(userId: String) async {
        do {
            let context = await CoreDataStack.shared.viewContext
            
            // Find the user by ID
            let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", userId)
            fetchRequest.fetchLimit = 1
            
            let users = try context.fetch(fetchRequest)
            
            if let user = users.first {
                // Increment the updates count
                user.updates += 1
                
                // Update the level based on the new count
                let newLevel = ReputationSystem.shared.getCurrentLevel(updates: Int(user.updates))
                user.level = newLevel.name
                
                try context.save()
                
                print("Updated reputation for user \(userId): \(user.updates) updates, level: \(newLevel.name)")
            } else {
                print("User not found for reputation update: \(userId)")
            }
        } catch {
            print("Error updating user reputation: \(error)")
        }
    }
    
    func getUserReputation(userId: String) async -> (updates: Int, level: String)? {
        do {
            let context = await CoreDataStack.shared.viewContext
            
            let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", userId)
            fetchRequest.fetchLimit = 1
            
            let users = try context.fetch(fetchRequest)
            
            if let user = users.first {
                return (updates: Int(user.updates), level: user.level ?? "New Shopper")
            }
        } catch {
            print("Error getting user reputation: \(error)")
        }
        return nil
    }
    
    func getCurrentUserReputation() async -> (updates: Int, level: String)? {
        do {
            let context = await CoreDataStack.shared.viewContext
            
            // Get the most recently created user (current user)
            let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \UserEntity.createdAt, ascending: false)]
            fetchRequest.fetchLimit = 1
            
            let users = try context.fetch(fetchRequest)
            
            if let user = users.first {
                return (updates: Int(user.updates), level: user.level ?? "New Shopper")
            }
        } catch {
            print("Error getting current user reputation: \(error)")
        }
        return nil
    }
} 