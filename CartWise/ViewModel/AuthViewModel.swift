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
        print("AuthViewModel: Starting sign up for username: \(username)")
        
        guard !username.isEmpty, !password.isEmpty else {
            error = "Username and password cannot be empty"
            print("AuthViewModel: Validation failed - empty username or password")
            return
        }
        
        guard username.count >= 3 else {
            error = "Username must be at least 3 characters long"
            print("AuthViewModel: Validation failed - username too short")
            return
        }
        
        guard password.count >= 6 else {
            error = "Password must be at least 6 characters long"
            print("AuthViewModel: Validation failed - password too short")
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            print("AuthViewModel: Checking for existing users")
            let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "username == %@", username)
            let existingUsers = try context.fetch(fetchRequest)
            
            if !existingUsers.isEmpty {
                error = "Username already taken"
                isLoading = false
                print("AuthViewModel: Username already taken")
                return
            }

            print("AuthViewModel: Creating new user entity")
            let userEntity = UserEntity(context: context)
            userEntity.id = UUID().uuidString
            userEntity.username = username
            userEntity.password = hashPassword(password)
            userEntity.updates = 0
            userEntity.level = "Newbie"
            userEntity.createdAt = Date()

            print("AuthViewModel: Saving context")
            try context.save()
            
            user = User(id: userEntity.id ?? UUID().uuidString, username: username, updates: Int(userEntity.updates))
            // Store the current username for the social feed
            UserDefaults.standard.set(username, forKey: "currentUsername")
            error = nil
            print("AuthViewModel: Sign up successful")
        } catch {
            self.error = "Failed to sign up: \(error.localizedDescription)"
            print("AuthViewModel: Sign up failed with error: \(error)")
        }
        
        isLoading = false
    }

    @MainActor
    func login(username: String, password: String) async {
        print("AuthViewModel: Starting login for username: \(username)")
        
        guard !username.isEmpty, !password.isEmpty else {
            error = "Username and password cannot be empty"
            print("AuthViewModel: Validation failed - empty username or password")
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            print("AuthViewModel: Fetching user from Core Data")
            let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "username == %@", username)
            let users = try context.fetch(fetchRequest)

            if let userEntity = users.first {
                print("AuthViewModel: User found, checking password")
                let hashedPassword = hashPassword(password)
                if userEntity.password == hashedPassword {
                    user = User(id: userEntity.id ?? UUID().uuidString, username: username, updates: Int(userEntity.updates))
                    // Store the current username for the social feed
                    UserDefaults.standard.set(username, forKey: "currentUsername")
                    error = nil
                    print("AuthViewModel: Login successful")
                } else {
                    error = "Invalid username or password"
                    print("AuthViewModel: Password mismatch")
                }
            } else {
                error = "Invalid username or password"
                print("AuthViewModel: User not found")
            }
        } catch {
            self.error = "Login failed: \(error.localizedDescription)"
            print("AuthViewModel: Login failed with error: \(error)")
        }
        
        isLoading = false
    }
    
    func logout() {
        user = nil
        error = nil
        // Clear the current username when logging out
        UserDefaults.standard.removeObject(forKey: "currentUsername")
    }
    
    private func hashPassword(_ password: String) -> String {
        let inputData = Data(password.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}
