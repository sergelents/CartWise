//
//  ReputationSystem.swift
//  CartWise
//
//  Created by CartWise Development Team on 12/19/24.
//

import SwiftUI

struct ShopperLevel {
    let name: String
    let icon: String
    let color: Color
    let minUpdates: Int
    let description: String
}

class ReputationSystem: ObservableObject {
    static let shared = ReputationSystem()

    let levels: [ShopperLevel] = [
        ShopperLevel(
            name: "New Shopper",
            icon: "cart.badge.plus",
            color: .gray,
            minUpdates: 0,
            description: "Just getting started with product contributions"
        ),
        ShopperLevel(
            name: "Regular Shopper",
            icon: "cart.fill",
            color: .green,
            minUpdates: 10,
            description: "Consistently helping the community"
        ),
        ShopperLevel(
            name: "Smart Shopper",
            icon: "cart.circle.fill",
            color: .blue,
            minUpdates: 25,
            description: "A trusted source for product information"
        ),
        ShopperLevel(
            name: "Expert Shopper",
            icon: "cart.badge.checkmark",
            color: .orange,
            minUpdates: 50,
            description: "Highly reliable product contributions"
        ),
        ShopperLevel(
            name: "Master Shopper",
            icon: "crown.fill",
            color: .yellow,
            minUpdates: 100,
            description: "The ultimate product contribution authority"
        ),
        ShopperLevel(
            name: "Legendary Shopper",
            icon: "star.circle.fill",
            color: .pink,
            minUpdates: 200,
            description: "A legend in the shopping community"
        )
    ]

    func getCurrentLevel(updates: Int) -> ShopperLevel {
        for level in levels.reversed() where updates >= level.minUpdates {
            return level
        }
        return levels.first!
    }

    func getNextLevel(updates: Int) -> ShopperLevel? {
        let currentLevel = getCurrentLevel(updates: updates)
        guard let currentIndex = levels.firstIndex(where: { $0.name == currentLevel.name }) else {
            return nil
        }

        let nextIndex = currentIndex + 1
        return nextIndex < levels.count ? levels[nextIndex] : nil
    }

    func getProgressToNextLevel(updates: Int) -> Double {
        let currentLevel = getCurrentLevel(updates: updates)
        guard let nextLevel = getNextLevel(updates: updates) else {
            return 1.0 // Max level reached
        }

        let updatesInCurrentLevel = updates - currentLevel.minUpdates
        let updatesNeededForNextLevel = nextLevel.minUpdates - currentLevel.minUpdates

        return Double(updatesInCurrentLevel) / Double(updatesNeededForNextLevel)
    }

    func getUpdatesToNextLevel(updates: Int) -> Int {
        guard let nextLevel = getNextLevel(updates: updates) else {
            return 0 // Max level reached
        }

        return nextLevel.minUpdates - updates
    }
}
