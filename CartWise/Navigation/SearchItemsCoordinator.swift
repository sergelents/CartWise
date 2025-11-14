//
//  SearchItemsCoordinator.swift
//  CartWise
//
//  Created by Claude Code on 22/10/25.
//

import SwiftUI
import Foundation

@MainActor
class SearchItemsCoordinator: ObservableObject {
    // MARK: - Navigation State
    @Published var showingTagPicker = false
    @Published var selectedTag: Tag?
    @Published var selectedProduct: GroceryItem?
    @Published var showingProductDetail = false

    // MARK: - Dependencies
    let searchViewModel: SearchViewModel
    let tagViewModel: TagViewModel
    let shoppingListViewModel: ShoppingListViewModel
    let profileViewModel: ProfileViewModel
    let locationViewModel: LocationViewModel

    init(
        searchViewModel: SearchViewModel,
        tagViewModel: TagViewModel,
        shoppingListViewModel: ShoppingListViewModel,
        profileViewModel: ProfileViewModel,
        locationViewModel: LocationViewModel
    ) {
        self.searchViewModel = searchViewModel
        self.tagViewModel = tagViewModel
        self.shoppingListViewModel = shoppingListViewModel
        self.profileViewModel = profileViewModel
        self.locationViewModel = locationViewModel
    }

    // MARK: - Navigation Methods

    func showTagPicker() {
        showingTagPicker = true
    }

    func hideTagPicker() {
        showingTagPicker = false
    }

    func selectTag(_ tag: Tag?) {
        selectedTag = tag
    }

    func clearTag() {
        selectedTag = nil
    }

    func showProductDetail(for product: GroceryItem) {
        selectedProduct = product
        showingProductDetail = true
    }

    func hideProductDetail() {
        showingProductDetail = false
        selectedProduct = nil
    }
}
