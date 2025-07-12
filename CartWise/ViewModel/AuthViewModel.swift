//
//  AuthViewModel.swift
//  CartWise
//
//  Created by Alex Kumar on 7/12/25.
//

import FirebaseAuth
import FirebaseFirestore
import Foundation

class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var error: String?
    private let db = Firestore.firestore()
    
    @MainActor
    func signUp(email: String, password: String, username: String) async {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            self.user = User(id: result.user.uid, username: username, updates: 0)
            try await saveUserData(userId: result.user.uid, username: username)
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    @MainActor
    func login(email: String, password: String) async {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            await loadUserData(userId: result.user.uid)
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    @MainActor
    private func saveUserData(userId: String, username: String) async throws {
        try await db.collection("users").document(userId).setData([
            "username": username,
            "updates": 0,
            "level": "Newbie",
            "createdAt": Timestamp()
        ])
    }
    
    @MainActor
    func loadUserData(userId: String) async {
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            if let data = document.data() {
                self.user = User(
                    id: userId,
                    username: data["username"] as? String ?? "",
                    updates: data["updates"] as? Int ?? 0
                )
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
}
