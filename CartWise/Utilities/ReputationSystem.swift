//
//  ReputationSystem.swift
//  CartWise
//
//  Created by AI Assistant on 12/19/24.
//

import Foundation
import SwiftUI

struct ShopperLevel {
    let name: String
    let icon: String
    let color: Color
    let minUpdates: Int
    let description: String
}

class ReputationSystem {
    static let shared = ReputationSystem()
    
    private init() {}
    
    // Define shopper levels
    let levels: [ShopperLevel] = [
        ShopperLevel(
            name: "New Shopper",
            icon: "cart.badge.plus",
            color: Color.gray,
            minUpdates: 0,
            description: "Just getting started with price updates"
        ),
        ShopperLevel(
            name: "Regular Shopper",
            icon: "cart.fill",
            color: Color.green,
            minUpdates: 10,
            description: "Consistently helping the community"
        ),
        ShopperLevel(
            name: "Smart Shopper",
            icon: "cart.circle.fill",
            color: Color.blue,
            minUpdates: 25,
            description: "A trusted source for price information"
        ),
        ShopperLevel(
            name: "Expert Shopper",
            icon: "cart.badge.checkmark",
            color: Color.orange,
            minUpdates: 50,
            description: "Highly reliable price updates"
        ),
        ShopperLevel(
            name: "Master Shopper",
            icon: "crown.fill",
            color: Color.yellow,
            minUpdates: 100,
            description: "The ultimate price update authority"
        ),
        ShopperLevel(
            name: "Legendary Shopper",
            icon: "star.circle.fill",
            color: Color.pink,
            minUpdates: 200,
            description: "A legend in the shopping community"
        )
    ]
    
    func getCurrentLevel(updates: Int) -> ShopperLevel {
        for level in levels.reversed() {
            if updates >= level.minUpdates {
                return level
            }
        }
        return levels.first!
    }
    
    func getNextLevel(updates: Int) -> ShopperLevel? {
        for level in levels {
            if updates < level.minUpdates {
                return level
            }
        }
        return nil
    }
    
    func getProgressToNextLevel(updates: Int) -> Double {
        let currentLevel = getCurrentLevel(updates: updates)
        let nextLevel = getNextLevel(updates: updates)
        
        guard let nextLevel = nextLevel else {
            return 1.0 // Already at max level
        }
        
        let currentMin = currentLevel.minUpdates
        let nextMin = nextLevel.minUpdates
        let userProgress = updates - currentMin
        let totalProgress = nextMin - currentMin
        
        return Double(userProgress) / Double(totalProgress)
    }
    
    func getUpdatesUntilNextLevel(updates: Int) -> Int {
        let nextLevel = getNextLevel(updates: updates)
        guard let nextLevel = nextLevel else {
            return 0 // Already at max level
        }
        return nextLevel.minUpdates - updates
    }
} 