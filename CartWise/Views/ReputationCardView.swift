//
//  ReputationCardView.swift
//  CartWise
//
//  Created by AI Assistant on 12/19/24.
//

import SwiftUI

struct ReputationCardView: View {
    let updates: Int
    let username: String
    
    private var reputationSystem: ReputationSystem {
        ReputationSystem.shared
    }
    
    private var currentLevel: ShopperLevel {
        reputationSystem.getCurrentLevel(updates: updates)
    }
    
    private var nextLevel: ShopperLevel? {
        reputationSystem.getNextLevel(updates: updates)
    }
    
    private var progressToNext: Double {
        reputationSystem.getProgressToNextLevel(updates: updates)
    }
    
    private var updatesUntilNext: Int {
        reputationSystem.getUpdatesUntilNextLevel(updates: updates)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Level Badge
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    currentLevel.color.opacity(0.2),
                                    currentLevel.color.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: currentLevel.icon)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(currentLevel.color)
                }
                
                VStack(spacing: 4) {
                    Text(currentLevel.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(currentLevel.description)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Stats
            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text("\(updates)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    Text("Price Updates")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Divider()
                    .frame(height: 40)
                    .background(Color.gray.opacity(0.3))
                
                VStack(spacing: 4) {
                    Text("\(currentLevel.minUpdates)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    Text("Level Min")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 20)
            
            // Progress to next level
            if let nextLevel = nextLevel {
                VStack(spacing: 12) {
                    HStack {
                        Text("Progress to \(nextLevel.name)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                        Spacer()
                        Text("\(updatesUntilNext) more updates")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            currentLevel.color,
                                            currentLevel.color.opacity(0.7)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * progressToNext, height: 8)
                                .animation(.easeInOut(duration: 0.5), value: progressToNext)
                        }
                    }
                    .frame(height: 8)
                }
                .padding(.horizontal, 20)
            } else {
                // Max level reached
                VStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 24))
                        .foregroundColor(currentLevel.color)
                    
                    Text("Maximum Level Reached!")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("You've achieved the highest shopper level")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
        )
        .padding(.horizontal, 20)
    }
}

#Preview {
    ReputationCardView(updates: 75, username: "TestUser")
        .background(Color.gray.opacity(0.1))
} 