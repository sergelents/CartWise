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
        let context = PersistenceController.shared.container.viewContext
        
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
        let context = PersistenceController.shared.container.viewContext
        
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
        let context = PersistenceController.shared.container.viewContext
        
        do {
            let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \UserEntity.createdAt, ascending: false)]
            fetchRequest.fetchLimit = 1
            
            let users = try context.fetch(fetchRequest)
            
            if let user = users.first {
                return (Int(user.updates), user.level ?? "New Shopper")
            }
        } catch {
            print("Error fetching current user reputation: \(error)")
        }
        
        return nil
    }
} 