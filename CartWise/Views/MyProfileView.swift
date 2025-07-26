//
//  MyProfileView.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/5/25.
//

import SwiftUI
import CoreData

struct MyProfileView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @StateObject private var productViewModel = ProductViewModel(repository: ProductRepository())
    @State private var currentUsername: String = ""
    @State private var isLoadingUser: Bool = true
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundSecondary
                    .ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 28) {
                        // Profile Card
                        VStack(spacing: 12) {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .frame(width: 80, height: 80)
                                .foregroundColor(AppColors.accentGreen)
                                .padding(.top, 24)
                            
                            if isLoadingUser {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .padding(.vertical, 8)
                            } else {
                                Text(currentUsername.isEmpty ? "User" : currentUsername)
                                    .font(.poppins(size: 24, weight: .bold))
                                    .foregroundColor(AppColors.textPrimary)
                            }
                            
                            Text("Manage your favorite items and account")
                                .font(.poppins(size: 15, weight: .regular))
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(18)
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        
                        // Favorites Section (Card)
                        FavoriteItemsView(productViewModel: productViewModel)
                            .padding(.horizontal)
                            .padding(.top, 4)
                            .padding(.vertical, 8)
                        
                        // Log Out Button (Card style)
                        Button(action: {
                            isLoggedIn = false
                        }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 18))
                                Text("Log Out")
                                    .font(.poppins(size: 17, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(AppColors.accentGreen)
                            .cornerRadius(14)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                    }
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await loadCurrentUser()
            }
        }
    }
    
    private func loadCurrentUser() async {
        isLoadingUser = true
        
        do {
            let context = PersistenceController.shared.container.viewContext
            let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
            
            // Since we don't have a direct way to identify the current user,
            // we'll fetch the most recently created user (assuming the last logged in user)
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \UserEntity.createdAt, ascending: false)]
            fetchRequest.fetchLimit = 1
            
            let users = try context.fetch(fetchRequest)
            
            if let currentUser = users.first, let username = currentUser.username {
                await MainActor.run {
                    currentUsername = username
                    isLoadingUser = false
                }
            } else {
                await MainActor.run {
                    currentUsername = "User"
                    isLoadingUser = false
                }
            }
        } catch {
            print("Error loading current user: \(error)")
            await MainActor.run {
                currentUsername = "User"
                isLoadingUser = false
            }
        }
    }
}
