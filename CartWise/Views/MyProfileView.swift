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
    @EnvironmentObject var productViewModel: ProductViewModel
    @State private var currentUsername: String = ""
    @State private var isLoadingUser: Bool = true
    @State private var showAddLocation: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                AppColors.backgroundSecondary
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Card
                        ProfileCard(
                            currentUsername: currentUsername,
                            isLoadingUser: isLoadingUser
                        )
                        
                        // Favorites Section
                        FavoriteItemsView()
                            .padding(.horizontal)
                        
                        // Locations Section
                        LocationsSectionView()
                            .padding(.horizontal)
                        
                        // Logout Button
                        LogoutButton(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isLoggedIn = false
                            }
                        })
                        .padding(.horizontal)
                        .padding(.bottom, 32)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await loadCurrentUser()
            }
            .sheet(isPresented: $showAddLocation) {
                AddLocationView()
                    .environmentObject(productViewModel)
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
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentUsername = username
                        isLoadingUser = false
                    }
                }
            } else {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentUsername = "User"
                        isLoadingUser = false
                    }
                }
            }
        } catch {
            print("Error loading current user: \(error)")
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentUsername = "User"
                    isLoadingUser = false
                }
            }
        }
    }
}

// MARK: - Profile Card Component
struct ProfileCard: View {
    let currentUsername: String
    let isLoadingUser: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // Profile Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                AppColors.accentGreen.opacity(0.15),
                                AppColors.accentGreen.opacity(0.05)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 64, height: 64)
                    .foregroundColor(AppColors.accentGreen)
            }
            .padding(.top, 16)
            
            // User Info
            VStack(spacing: 8) {
                if isLoadingUser {
                    ProgressView()
                        .scaleEffect(0.8)
                        .padding(.vertical, 8)
                } else {
                    Text(currentUsername.isEmpty ? "User" : currentUsername)
                        .font(.poppins(size: 24, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                }
                
                Text("Manage your account and preferences")
                    .font(.poppins(size: 14, weight: .regular))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal)
    }
}

// MARK: - Logout Button Component
struct LogoutButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 16, weight: .medium))
                Text("Log Out")
                    .font(.poppins(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                AppColors.accentRed,
                                AppColors.accentRed.opacity(0.8)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: AppColors.accentRed.opacity(0.25), radius: 8, x: 0, y: 4)
            )
        }
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.2), value: true)
    }
}
