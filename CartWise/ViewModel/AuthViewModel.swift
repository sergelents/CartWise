//
//  AuthViewModel.swift
//  CartWise
//
//  Created by Alex Kumar on 7/12/25.
//

import Foundation
import CoreData
import CryptoKit

class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var error: String?
    @Published var isLoading = false
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    @MainActor
    func signUp(username: String, password: String) async {
        guard !username.isEmpty, !password.isEmpty else {
            error = "Username and password cannot be empty"
            return
        }
        
        guard username.count >= 3 else {
            error = "Username must be at least 3 characters long"
            return
        }
        
        guard password.count >= 6 else {
            error = "Password must be at least 6 characters long"
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "username == %@", username)
            let existingUsers = try context.fetch(fetchRequest)
            
            if !existingUsers.isEmpty {
                error = "Username already taken"
                isLoading = false
                return
            }

            let userEntity = UserEntity(context: context)
            userEntity.id = UUID().uuidString
            userEntity.username = username
            userEntity.password = hashPassword(password)
            userEntity.updates = 0
            userEntity.level = "Newbie"
            userEntity.createdAt = Date()

            try context.save()
            
            user = User(id: userEntity.id ?? UUID().uuidString, username: username, updates: Int(userEntity.updates))
            error = nil
        } catch {
            self.error = "Failed to sign up: \(error.localizedDescription)" // Assign to self.error
        }
        
        isLoading = false
    }

    @MainActor
    func login(username: String, password: String) async {
        guard !username.isEmpty, !password.isEmpty else {
            error = "Username and password cannot be empty"
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "username == %@", username)
            let users = try context.fetch(fetchRequest)

            if let userEntity = users.first {
                let hashedPassword = hashPassword(password)
                if userEntity.password == hashedPassword {
                    user = User(id: userEntity.id ?? UUID().uuidString, username: username, updates: Int(userEntity.updates))
                    error = nil
                } else {
                    error = "Invalid username or password"
                }
            } else {
                error = "Invalid username or password"
            }
        } catch {
            self.error = "Login failed: \(error.localizedDescription)" // Assign to self.error
        }
        
        isLoading = false
    }
    
    func logout() {
        user = nil
        error = nil
    }
    
    private func hashPassword(_ password: String) -> String {
        let inputData = Data(password.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}
