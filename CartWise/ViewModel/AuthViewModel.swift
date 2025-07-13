//
//  AuthViewModel.swift
//  CartWise
//
//  Created by Alex Kumar on 7/12/25.
//

import CoreData
import Foundation

class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var error: String?
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    @MainActor
    func signUp(username: String, password: String) async {
        do {
            let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "username == %@", username)
            let existingUsers = try context.fetch(fetchRequest)
            if !existingUsers.isEmpty {
                self.error = "Username already taken"
                return
            }
            
            let userEntity = UserEntity(context: context)
            userEntity.id = UUID().uuidString
            userEntity.username = username
            userEntity.password = password // Mock: plain text for demo
            userEntity.updates = 0
            userEntity.level = "Newbie"
            userEntity.createdAt = Date()
            
            try context.save()
            self.user = User(id: userEntity.id, username: userEntity.username, updates: Int(userEntity.updates))
        } catch {
            self.error = "Failed to sign up: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    func login(username: String, password: String) async {
        do {
            let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "username == %@ AND password == %@", username, password)
            let users = try context.fetch(fetchRequest)
            
            if let userEntity = users.first {
                self.user = User(id: userEntity.id, username: userEntity.username, updates: Int(userEntity.updates))
            } else {
                self.error = "Invalid username or password"
            }
        } catch {
            self.error = "Failed to log in: \(error.localizedDescription)"
        }
    }
}
