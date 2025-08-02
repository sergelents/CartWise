//
//  ReputationTest.swift
//  CartWise
//
//  Created by AI Assistant on 12/19/24.
//

import Foundation
import CoreData

class ReputationTest {
    static func testReputationSystem() async {
        print("=== Testing Reputation System ===")
        
        let reputationSystem = ReputationSystem.shared
        
        // Test different update counts
        let testCounts = [0, 5, 15, 30, 75, 150, 250]
        
        for count in testCounts {
            let level = reputationSystem.getCurrentLevel(updates: count)
            let nextLevel = reputationSystem.getNextLevel(updates: count)
            let progress = reputationSystem.getProgressToNextLevel(updates: count)
            let updatesUntilNext = reputationSystem.getUpdatesUntilNextLevel(updates: count)
            
            print("Updates: \(count)")
            print("  Current Level: \(level.name)")
            print("  Next Level: \(nextLevel?.name ?? "Max Level")")
            print("  Progress: \(String(format: "%.2f", progress))")
            print("  Updates until next: \(updatesUntilNext)")
            print("---")
        }
        
        // Test reputation manager
        let reputationManager = ReputationManager.shared
        
        // Test getting user reputation
        if let userReputation = await reputationManager.getUserReputation(userId: "testuser") {
            print("User reputation: \(userReputation.updates) updates, level: \(userReputation.level)")
        } else {
            print("No user reputation found for testuser")
        }
    }
    
    // Simple verification that the system compiles
    static func verifyCompilation() {
        print("=== Verifying Reputation System Compilation ===")
        
        // Test ReputationSystem
        let reputationSystem = ReputationSystem.shared
        let testLevel = reputationSystem.getCurrentLevel(updates: 50)
        print("✓ ReputationSystem: \(testLevel.name)")
        
        // Test ReputationManager
        let reputationManager = ReputationManager.shared
        print("✓ ReputationManager: Initialized successfully")
        
        // Test tuple-based price info
        let testPriceInfo: (price: Double, shopper: String?)? = (price: 5.99, shopper: "testuser")
        if let priceInfo = testPriceInfo {
            print("✓ Tuple-based price info: $\(priceInfo.price) by \(priceInfo.shopper ?? "Unknown")")
        }
        
        print("✓ All reputation components compiled successfully")
    }
} 