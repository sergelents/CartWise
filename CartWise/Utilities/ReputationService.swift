//
//  ReputationService.swift
//  CartWise
//
//  Created by Alex Kumar on 7/12/25.
//

import Foundation
import CoreData

class ReputationService: ObservableObject {
    static let shared = ReputationService()
    
    @Published var showPointsNotification = false
    @Published var pointsNotificationMessage = ""
    @Published var pointsNotificationPoints = 0
    
    private let context: NSManagedObjectContext
    private var reputationViewModel: ReputationViewModel?
    
    private init() {
        self.context = PersistenceController.shared.container.viewContext
    }
    
    // MARK: - Setup
    
    func setup(with reputationViewModel: ReputationViewModel) {
        self.reputationViewModel = reputationViewModel
    }
    
    // MARK: - Product Addition Actions
    
    /// Award points for adding a new product via barcode scan
    func awardProductAdditionViaBarcode() async {
        print("ReputationService: Awarding points for product addition via barcode")
        await reputationViewModel?.addProductAddition()
        
        await MainActor.run {
            pointsNotificationMessage = "Product added successfully!"
            pointsNotificationPoints = 25
            showPointsNotification = true
            
            // Hide notification after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.showPointsNotification = false
            }
        }
    }
    
    /// Award points for adding a new product via manual entry
    func awardProductAdditionViaManualEntry() async {
        print("ReputationService: Awarding points for product addition via manual entry")
        await reputationViewModel?.addProductAddition()
    }
    
    /// Award points for adding a product to favorites
    func awardFavoriteAddition() async {
        print("ReputationService: Awarding points for adding to favorites")
        await reputationViewModel?.addContribution(.reviewSubmission) // Using review points for favorites
        
        await MainActor.run {
            pointsNotificationMessage = "Added to favorites!"
            pointsNotificationPoints = 15
            showPointsNotification = true
            
            // Hide notification after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.showPointsNotification = false
            }
        }
    }
    
    /// Award points for adding a product to shopping list
    func awardShoppingListAddition() async {
        print("ReputationService: Awarding points for adding to shopping list")
        await reputationViewModel?.addContribution(.productAddition) // Using product addition points
    }
    
    // MARK: - Price Update Actions
    
    /// Award points for updating a product price
    func awardPriceUpdate() async {
        print("ReputationService: Awarding points for price update")
        await reputationViewModel?.addPriceUpdate()
        
        await MainActor.run {
            pointsNotificationMessage = "Price updated!"
            pointsNotificationPoints = 10
            showPointsNotification = true
            
            // Hide notification after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.showPointsNotification = false
            }
        }
    }
    
    /// Award points for reporting inaccurate price
    func awardPriceReport() async {
        print("ReputationService: Awarding points for price report")
        await reputationViewModel?.addPriceUpdate()
    }
    
    // MARK: - Photo Upload Actions
    
    /// Award points for uploading a product photo
    func awardPhotoUpload() async {
        print("ReputationService: Awarding points for photo upload")
        await reputationViewModel?.addPhotoUpload()
    }
    
    // MARK: - Review Actions
    
    /// Award points for submitting a product review
    func awardReviewSubmission() async {
        print("ReputationService: Awarding points for review submission")
        await reputationViewModel?.addReviewSubmission()
    }
    
    /// Award points for submitting a store review
    func awardStoreReview() async {
        print("ReputationService: Awarding points for store review")
        await reputationViewModel?.addStoreReview()
    }
    
    // MARK: - Search and Discovery Actions
    
    /// Award points for discovering new products
    func awardProductDiscovery() async {
        print("ReputationService: Awarding points for product discovery")
        await reputationViewModel?.addContribution(.productAddition)
    }
    
    /// Award points for category exploration
    func awardCategoryExploration() async {
        print("ReputationService: Awarding points for category exploration")
        await reputationViewModel?.addContribution(.reviewSubmission)
    }
    
    // MARK: - Shopping List Management
    
    /// Award points for completing shopping list items
    func awardShoppingListCompletion() async {
        print("ReputationService: Awarding points for shopping list completion")
        await reputationViewModel?.addContribution(.priceUpdate)
    }
    
    /// Award points for organizing shopping list
    func awardShoppingListOrganization() async {
        print("ReputationService: Awarding points for shopping list organization")
        await reputationViewModel?.addContribution(.reviewSubmission)
    }
    
    // MARK: - Community Actions
    
    /// Award points for helping other users
    func awardCommunityHelp() async {
        print("ReputationService: Awarding points for community help")
        await reputationViewModel?.addContribution(.storeReview)
    }
    
    /// Award points for data validation
    func awardDataValidation() async {
        print("ReputationService: Awarding points for data validation")
        await reputationViewModel?.addPriceUpdate()
    }
    
    // MARK: - Streak and Consistency
    
    /// Award bonus points for daily login
    func awardDailyLogin() async {
        print("ReputationService: Awarding points for daily login")
        await reputationViewModel?.addContribution(.reviewSubmission)
    }
    
    /// Award bonus points for weekly activity
    func awardWeeklyActivity() async {
        print("ReputationService: Awarding points for weekly activity")
        await reputationViewModel?.addContribution(.productAddition)
    }
    
    // MARK: - Special Events
    
    /// Award points for special events or challenges
    func awardSpecialEvent(description: String) async {
        print("ReputationService: Awarding points for special event: \(description)")
        await reputationViewModel?.addContribution(.storeReview)
    }
    
    // MARK: - Bulk Actions
    
    /// Award points for bulk product additions
    func awardBulkProductAddition(count: Int) async {
        print("ReputationService: Awarding points for bulk product addition (\(count) items)")
        for _ in 0..<min(count, 5) { // Cap at 5 to prevent abuse
            await reputationViewModel?.addProductAddition()
        }
    }
    
    /// Award points for bulk price updates
    func awardBulkPriceUpdate(count: Int) async {
        print("ReputationService: Awarding points for bulk price update (\(count) items)")
        for _ in 0..<min(count, 3) { // Cap at 3 to prevent abuse
            await reputationViewModel?.addPriceUpdate()
        }
    }
}

// MARK: - Reputation Action Types

enum ReputationAction {
    case productAddition
    case priceUpdate
    case photoUpload
    case reviewSubmission
    case storeReview
    case favoriteAddition
    case shoppingListAddition
    case productDiscovery
    case categoryExploration
    case shoppingListCompletion
    case shoppingListOrganization
    case communityHelp
    case dataValidation
    case dailyLogin
    case weeklyActivity
    case specialEvent(description: String)
    case bulkProductAddition(count: Int)
    case bulkPriceUpdate(count: Int)
}

// MARK: - Reputation Action Descriptions

extension ReputationAction {
    var description: String {
        switch self {
        case .productAddition:
            return "Added a new product"
        case .priceUpdate:
            return "Updated product price"
        case .photoUpload:
            return "Uploaded product photo"
        case .reviewSubmission:
            return "Submitted a review"
        case .storeReview:
            return "Reviewed a store"
        case .favoriteAddition:
            return "Added to favorites"
        case .shoppingListAddition:
            return "Added to shopping list"
        case .productDiscovery:
            return "Discovered new product"
        case .categoryExploration:
            return "Explored product category"
        case .shoppingListCompletion:
            return "Completed shopping list item"
        case .shoppingListOrganization:
            return "Organized shopping list"
        case .communityHelp:
            return "Helped the community"
        case .dataValidation:
            return "Validated product data"
        case .dailyLogin:
            return "Daily login bonus"
        case .weeklyActivity:
            return "Weekly activity bonus"
        case .specialEvent(let description):
            return "Special event: \(description)"
        case .bulkProductAddition(let count):
            return "Bulk product addition (\(count) items)"
        case .bulkPriceUpdate(let count):
            return "Bulk price update (\(count) items)"
        }
    }
    
    var points: Int32 {
        switch self {
        case .productAddition:
            return 25
        case .priceUpdate:
            return 10
        case .photoUpload:
            return 20
        case .reviewSubmission:
            return 15
        case .storeReview:
            return 30
        case .favoriteAddition:
            return 5
        case .shoppingListAddition:
            return 5
        case .productDiscovery:
            return 10
        case .categoryExploration:
            return 5
        case .shoppingListCompletion:
            return 5
        case .shoppingListOrganization:
            return 10
        case .communityHelp:
            return 20
        case .dataValidation:
            return 15
        case .dailyLogin:
            return 5
        case .weeklyActivity:
            return 25
        case .specialEvent:
            return 50
        case .bulkProductAddition(let count):
            return Int32(min(count, 5) * 25)
        case .bulkPriceUpdate(let count):
            return Int32(min(count, 3) * 10)
        }
    }
} 
