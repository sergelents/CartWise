//
//  ShoppingListCoordinator.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 8/5/25.
//

import SwiftUI
import Foundation

@MainActor
class ShoppingListCoordinator: ObservableObject {
    // MARK: - Navigation State
    @Published var showingAddProductModal = false
    @Published var showingRatingPrompt = false
    @Published var showingShareExperience = false
    @Published var showingDuplicateAlert = false
    @Published var showingCheckAllConfirmation = false
    
    // MARK: - Data State
    @Published var duplicateProductName = ""
    @Published var currentPriceComparison: PriceComparison?
    
    // MARK: - Dependencies
    private let productViewModel: ProductViewModel
    
    init(productViewModel: ProductViewModel) {
        self.productViewModel = productViewModel
    }
    
    // MARK: - Navigation Methods
    
    func showAddProductModal() {
        showingAddProductModal = true
    }
    
    func hideAddProductModal() {
        showingAddProductModal = false
    }
    
    func showRatingPrompt() {
        showingRatingPrompt = true
    }
    
    func hideRatingPrompt() {
        showingRatingPrompt = false
    }
    
    func showShareExperience(priceComparison: PriceComparison?) {
        currentPriceComparison = priceComparison
        showingShareExperience = true
    }
    
    func hideShareExperience() {
        showingShareExperience = false
        currentPriceComparison = nil
    }
    
    func showDuplicateAlert(productName: String) {
        duplicateProductName = productName
        showingDuplicateAlert = true
    }
    
    func hideDuplicateAlert() {
        showingDuplicateAlert = false
        duplicateProductName = ""
    }
    
    func showCheckAllConfirmation() {
        showingCheckAllConfirmation = true
    }
    
    func hideCheckAllConfirmation() {
        showingCheckAllConfirmation = false
    }
    
}
