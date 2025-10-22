//
//  SocialFeedCoordinator.swift
//  CartWise
//
//  Created by Claude Code on 22/10/25.
//

import SwiftUI
import Foundation

@MainActor
class SocialFeedCoordinator: ObservableObject {
    // MARK: - Navigation State
    @Published var showingAddExperience = false
    @Published var showingExperienceDetail = false
    @Published var showingProductPicker = false
    @Published var showingLocationPicker = false
    @Published var showingTypePicker = false

    // MARK: - Data State
    @Published var selectedExperience: ShoppingExperience?
    @Published var selectedProduct: GroceryItem?
    @Published var selectedLocation: Location?
    @Published var selectedType = "general"

    // MARK: - Dependencies
    let socialFeedViewModel: SocialFeedViewModel

    init() {
        self.socialFeedViewModel = SocialFeedViewModel()
    }

    // MARK: - Navigation Methods

    func showAddExperience() {
        showingAddExperience = true
    }

    func hideAddExperience() {
        showingAddExperience = false
        // Reset state when closing
        selectedProduct = nil
        selectedLocation = nil
        selectedType = "general"
    }

    func showExperienceDetail(experience: ShoppingExperience) {
        selectedExperience = experience
        showingExperienceDetail = true
    }

    func hideExperienceDetail() {
        showingExperienceDetail = false
        selectedExperience = nil
    }

    func showProductPicker() {
        showingProductPicker = true
    }

    func hideProductPicker() {
        showingProductPicker = false
    }

    func showLocationPicker() {
        showingLocationPicker = true
    }

    func hideLocationPicker() {
        showingLocationPicker = false
    }

    func showTypePicker() {
        showingTypePicker = true
    }

    func hideTypePicker() {
        showingTypePicker = false
    }

    // MARK: - State Management

    func selectProduct(_ product: GroceryItem?) {
        selectedProduct = product
    }

    func clearProduct() {
        selectedProduct = nil
    }

    func selectLocation(_ location: Location?) {
        selectedLocation = location
    }

    func clearLocation() {
        selectedLocation = nil
    }

    func selectType(_ type: String) {
        selectedType = type
    }
}
