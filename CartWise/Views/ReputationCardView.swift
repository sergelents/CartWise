//
//  ReputationCardView.swift
//  CartWise
//
//  Created by CartWise Development Team on 12/19/24.
//

import SwiftUI

struct ReputationCardView: View {
    let updates: Int
    let level: String
    @State private var progressValue: Double = 0.0

    private var currentLevel: ShopperLevel {
        ReputationSystem.shared.getCurrentLevel(updates: updates)
    }

    private var nextLevel: ShopperLevel? {
        ReputationSystem.shared.getNextLevel(updates: updates)
    }

    private var progressToNextLevel: Double {
        ReputationSystem.shared.getProgressToNextLevel(updates: updates)
    }

    private var updatesToNextLevel: Int {
        ReputationSystem.shared.getUpdatesToNextLevel(updates: updates)
    }

    var body: some View {
        VStack(spacing: 20) {
            // Level Badge
            LevelBadgeView(level: currentLevel)

            // Level Info
            VStack(spacing: 8) {
                Text(currentLevel.name)
                    .font(.poppins(size: 20, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)

                Text(currentLevel.description)
                    .font(.poppins(size: 14, weight: .regular))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            // Statistics
            StatisticsView(updates: updates)

            // Progress Section
            if let nextLevel = nextLevel {
                ProgressSectionView(
                    currentLevel: currentLevel,
                    nextLevel: nextLevel,
                    progress: progressToNextLevel,
                    updatesToNext: updatesToNextLevel
                )
            } else {
                // Max level reached
                MaxLevelView()
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                progressValue = progressToNextLevel
            }
        }
    }
}

// MARK: - Level Badge View
struct LevelBadgeView: View {
    let level: ShopperLevel

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            level.color.opacity(0.2),
                            level.color.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)

            Image(systemName: level.icon)
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(level.color)
        }
    }
}

// MARK: - Statistics View
struct StatisticsView: View {
    let updates: Int

    var body: some View {
        VStack(spacing: 12) {
            Text("\(updates)")
                .font(.poppins(size: 32, weight: .bold))
                .foregroundColor(AppColors.accentGreen)

            Text("Price Updates")
                .font(.poppins(size: 14, weight: .medium))
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Progress Section View
struct ProgressSectionView: View {
    let currentLevel: ShopperLevel
    let nextLevel: ShopperLevel
    let progress: Double
    let updatesToNext: Int

    var body: some View {
        VStack(spacing: 16) {
            // Progress Bar
            VStack(spacing: 8) {
                HStack {
                    Text("Progress to \(nextLevel.name)")
                        .font(.poppins(size: 14, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)

                    Spacer()

                    Text("\(Int(progress * 100))%")
                        .font(.poppins(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.accentGreen)
                }

                ProgressBarView(progress: progress)
            }

            // Updates needed
            HStack(spacing: 8) {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundColor(AppColors.accentGreen)
                    .font(.system(size: 16))

                Text("\(updatesToNext) more updates to reach \(nextLevel.name)")
                    .font(.poppins(size: 12, weight: .medium))
                    .foregroundColor(.gray)

                Spacer()
            }
        }
    }
}

// MARK: - Progress Bar View
struct ProgressBarView: View {
    let progress: Double
    @State private var animatedProgress: Double = 0.0

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 8)

                // Progress
                RoundedRectangle(cornerRadius: 8)
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
                    .frame(width: geometry.size.width * animatedProgress, height: 8)
                    .animation(.easeInOut(duration: 1.0), value: animatedProgress)
            }
        }
        .frame(height: 8)
        .onAppear {
            animatedProgress = progress
        }
        .onChange(of: progress) { _, newValue in
            animatedProgress = newValue
        }
    }
}

// MARK: - Max Level View
struct MaxLevelView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(.yellow)

            Text("Maximum Level Reached!")
                .font(.poppins(size: 16, weight: .bold))
                .foregroundColor(AppColors.textPrimary)

            Text("You've achieved the highest level in the CartWise community!")
                .font(.poppins(size: 12, weight: .medium))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    ReputationCardView(updates: 75, level: "Expert Shopper")
        .padding()
        .background(AppColors.backgroundSecondary)
}
