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
    
    var body: some View {
        NavigationView {
            ZStack {
                // Enhanced background with gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        AppColors.backgroundSecondary,
                        AppColors.backgroundSecondary.opacity(0.8),
                        Color.white.opacity(0.1)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Enhanced Profile Card
                        VStack(spacing: 16) {
                            // Profile Avatar with enhanced styling
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                AppColors.accentGreen.opacity(0.2),
                                                AppColors.accentGreen.opacity(0.1)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .frame(width: 80, height: 80)
                                    .foregroundColor(AppColors.accentGreen)
                                    .shadow(color: AppColors.accentGreen.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .padding(.top, 28)
                            
                            if isLoadingUser {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .padding(.vertical, 12)
                            } else {
                                Text(currentUsername.isEmpty ? "User" : currentUsername)
                                    .font(.poppins(size: 26, weight: .bold))
                                    .foregroundColor(AppColors.textPrimary)
                                    .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                            }
                            
                            Text("Manage your favorite items and account")
                                .font(.poppins(size: 16, weight: .regular))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
                        )
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        
                        // Enhanced Favorites Section
                        FavoriteItemsView()
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                        
                        // Enhanced Log Out Button
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isLoggedIn = false
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 18, weight: .medium))
                                Text("Log Out")
                                    .font(.poppins(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                AppColors.accentGreen,
                                                AppColors.accentGreen.opacity(0.8)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: AppColors.accentGreen.opacity(0.3), radius: 12, x: 0, y: 6)
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                        .scaleEffect(1.0)
                        .animation(.easeInOut(duration: 0.2), value: isLoggedIn)
                    }
                    .padding(.top, 16)
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
