//
//  MyProfileCoordinator.swift
//  CartWise
//
//  Created by Claude Code on 22/10/25.
//

import SwiftUI
import Foundation

@MainActor
class MyProfileCoordinator: ObservableObject {
    // MARK: - Navigation State
    @Published var showingAddLocation = false
    @Published var showingAvatarPicker = false
    @Published var selectedTab: ProfileTab = .favorites

    // MARK: - Data State
    @Published var currentUsername: String = ""
    @Published var isLoadingUser: Bool = true

    // Profile tabs
    enum ProfileTab: String, CaseIterable {
        case favorites = "Favorites"
        case locations = "Locations"
        case reputation = "Reputation"
    }

    // MARK: - Dependencies
    let profileViewModel: ProfileViewModel
    let locationViewModel: LocationViewModel
    let searchViewModel: SearchViewModel
    let shoppingListViewModel: ShoppingListViewModel
    let tagViewModel: TagViewModel

    init(profileViewModel: ProfileViewModel, 
         locationViewModel: LocationViewModel,
         searchViewModel: SearchViewModel,
         shoppingListViewModel: ShoppingListViewModel,
         tagViewModel: TagViewModel) {
        self.profileViewModel = profileViewModel
        self.locationViewModel = locationViewModel
        self.searchViewModel = searchViewModel
        self.shoppingListViewModel = shoppingListViewModel
        self.tagViewModel = tagViewModel
    }

    // MARK: - Navigation Methods

    func showAddLocation() {
        showingAddLocation = true
    }

    func hideAddLocation() {
        showingAddLocation = false
    }

    func showAvatarPicker() {
        showingAvatarPicker = true
    }

    func hideAvatarPicker() {
        showingAvatarPicker = false
    }

    func selectTab(_ tab: ProfileTab) {
        selectedTab = tab
    }

    // MARK: - State Management

    func setUsername(_ username: String) {
        currentUsername = username
    }

    func setLoadingState(_ loading: Bool) {
        isLoadingUser = loading
    }
}
