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
    @StateObject private var reputationViewModel = ReputationViewModel()
    @StateObject private var reputationService = ReputationService.shared
    @State private var currentUsername: String = ""
    @State private var isLoadingUser: Bool = true
    @State private var showingReputation = false
    
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
                        // Enhanced Profile Card with Reputation
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
                                VStack(spacing: 8) {
                                    Text(currentUsername.isEmpty ? "User" : currentUsername)
                                        .font(.poppins(size: 26, weight: .bold))
                                        .foregroundColor(AppColors.textPrimary)
                                        .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                                    
                                    // Reputation Level Badge
                                    let currentLevel = reputationViewModel.getCurrentLevel()
                                    HStack(spacing: 6) {
                                        Image(systemName: currentLevel.icon)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(currentLevel.color)
                                        
                                        Text(currentLevel.name)
                                            .font(.poppins(size: 14, weight: .semibold))
                                            .foregroundColor(currentLevel.color)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(currentLevel.color.opacity(0.1))
                                    )
                                }
                            }
                            
                            Text("Manage your favorite items and account")
                                .font(.poppins(size: 16, weight: .regular))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                            
                            // Reputation Button
                            Button(action: {
                                showingReputation = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "trophy.fill")
                                        .font(.system(size: 16, weight: .medium))
                                    Text("View Reputation")
                                        .font(.poppins(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
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
                                        .shadow(color: AppColors.accentGreen.opacity(0.3), radius: 6, x: 0, y: 3)
                                )
                            }
                            

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
                        FavoriteItemsView(productViewModel: productViewModel)
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
                await reputationViewModel.loadCurrentUser()
                
                // Setup ReputationService with the reputation view model
                ReputationService.shared.setup(with: reputationViewModel)
            }
            .sheet(isPresented: $showingReputation) {
                NavigationView {
                    ReputationView(reputationViewModel: reputationViewModel)
                        .navigationTitle("Reputation")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showingReputation = false
                                }
                            }
                        }
                }
            }
            .alert("Achievement Unlocked!", isPresented: $reputationViewModel.showAchievementAlert) {
                Button("Awesome!") { }
            } message: {
                if let achievement = reputationViewModel.newAchievement {
                    Text("You've earned the '\(achievement.name)' badge! \(achievement.description)")
                }
            }

            .overlay(
                // Points Notification Toast
                Group {
                    if reputationService.showPointsNotification {
                        VStack {
                            Spacer()
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text(reputationService.pointsNotificationMessage)
                                    .font(.poppins(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("+\(reputationService.pointsNotificationPoints)")
                                    .font(.poppins(size: 16, weight: .bold))
                                    .foregroundColor(.yellow)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.black.opacity(0.8))
                                    .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                            )
                            .padding(.horizontal, 20)
                            .padding(.bottom, 100)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        .animation(.easeInOut(duration: 0.3), value: reputationService.showPointsNotification)
                    }
                }
            )
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
