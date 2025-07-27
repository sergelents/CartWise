//
//  ReputationView.swift
//  CartWise
//
//  Created by Alex Kumar on 7/12/25.
//

import SwiftUI

struct ReputationView: View {
    @ObservedObject var reputationViewModel: ReputationViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Reputation Level Card
            ReputationLevelCard(reputationViewModel: reputationViewModel)
            
            // Contribution Stats
            ContributionStatsView(reputationViewModel: reputationViewModel)
            
            // Achievements Section
            AchievementsView(reputationViewModel: reputationViewModel)
        }
        .padding(.horizontal, 20)
    }
}

struct ReputationLevelCard: View {
    @ObservedObject var reputationViewModel: ReputationViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            let currentLevel = reputationViewModel.getCurrentLevel()
            let nextLevel = reputationViewModel.getNextLevel()
            let progress = reputationViewModel.getProgressToNextLevel()
            let stats = reputationViewModel.getContributionStats()
            
            // Level Header
            HStack {
                Image(systemName: currentLevel.icon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(currentLevel.color)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(currentLevel.name)
                        .font(.poppins(size: 20, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(currentLevel.description)
                        .font(.poppins(size: 14, weight: .regular))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(stats.points))")
                        .font(.poppins(size: 24, weight: .bold))
                        .foregroundColor(currentLevel.color)
                    
                    Text("Points")
                        .font(.poppins(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
            
            // Progress Bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Progress to next level")
                        .font(.poppins(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    if let next = nextLevel {
                        Text("\(next.name)")
                            .font(.poppins(size: 14, weight: .semibold))
                            .foregroundColor(next.color)
                    } else {
                        Text("Max Level")
                            .font(.poppins(size: 14, weight: .semibold))
                            .foregroundColor(.green)
                    }
                }
                
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: currentLevel.color))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                
                if let next = nextLevel {
                    let pointsNeeded = next.minPoints - stats.points
                    Text("\(pointsNeeded) points needed for \(next.name)")
                        .font(.poppins(size: 12, weight: .regular))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
}

struct ContributionStatsView: View {
    @ObservedObject var reputationViewModel: ReputationViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Contribution Stats")
                    .font(.poppins(size: 18, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
            }
            
            let stats = reputationViewModel.getContributionStats()
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(title: "Total", value: "\(Int(stats.totalContributions))", icon: "chart.bar.fill", color: .blue)
                StatCard(title: "Price Updates", value: "\(Int(stats.priceUpdates))", icon: "dollarsign.circle.fill", color: .green)
                StatCard(title: "Products Added", value: "\(Int(stats.productAdditions))", icon: "plus.circle.fill", color: .orange)
                StatCard(title: "Reviews", value: "\(Int(stats.reviewsSubmitted))", icon: "star.circle.fill", color: .yellow)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
            
            Text(value)
                .font(.poppins(size: 20, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
            
            Text(title)
                .font(.poppins(size: 12, weight: .medium))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

struct AchievementsView: View {
    @ObservedObject var reputationViewModel: ReputationViewModel
    @State private var showingAllAchievements = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Achievements")
                    .font(.poppins(size: 18, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Button("View All") {
                    showingAllAchievements = true
                }
                .font(.poppins(size: 14, weight: .medium))
                .foregroundColor(AppColors.accentGreen)
            }
            
            let earnedAchievements = reputationViewModel.getEarnedAchievements()
            
            if earnedAchievements.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "trophy")
                        .font(.system(size: 32))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("No achievements yet")
                        .font(.poppins(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Text("Start contributing to earn badges!")
                        .font(.poppins(size: 14, weight: .regular))
                        .foregroundColor(.gray.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(earnedAchievements.prefix(6), id: \.id) { achievement in
                        AchievementBadge(achievement: achievement)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
        .sheet(isPresented: $showingAllAchievements) {
            AllAchievementsView(reputationViewModel: reputationViewModel)
        }
    }
}

struct AchievementBadge: View {
    let achievement: ReputationManager.Achievement
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: achievement.icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(achievement.color)
            
            Text(achievement.name)
                .font(.poppins(size: 12, weight: .medium))
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(achievement.color.opacity(0.1))
        )
    }
}

struct AllAchievementsView: View {
    @ObservedObject var reputationViewModel: ReputationViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(reputationViewModel.getAvailableAchievements(), id: \.id) { achievement in
                        DetailedAchievementCard(
                            achievement: achievement,
                            isEarned: reputationViewModel.getEarnedAchievements().contains { $0.id == achievement.id }
                        )
                    }
                }
                .padding(20)
            }
            .navigationTitle("All Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DetailedAchievementCard: View {
    let achievement: ReputationManager.Achievement
    let isEarned: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: achievement.icon)
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(isEarned ? achievement.color : .gray.opacity(0.5))
            
            VStack(spacing: 4) {
                Text(achievement.name)
                    .font(.poppins(size: 16, weight: .bold))
                    .foregroundColor(isEarned ? AppColors.textPrimary : .gray)
                    .multilineTextAlignment(.center)
                
                Text(achievement.description)
                    .font(.poppins(size: 14, weight: .regular))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                
                Text(achievement.requirement)
                    .font(.poppins(size: 12, weight: .medium))
                    .foregroundColor(isEarned ? achievement.color : .gray.opacity(0.7))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isEarned ? achievement.color.opacity(0.1) : Color.gray.opacity(0.1))
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
        .opacity(isEarned ? 1.0 : 0.7)
    }
} 