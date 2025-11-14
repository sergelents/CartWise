//
//  AddItemsCoordinator.swift
//  CartWise
//
//  Created by Claude Code on 22/10/25.
//

import SwiftUI
import Foundation

@MainActor
class AddItemsCoordinator: ObservableObject {
    // MARK: - Navigation State
    @Published var showingBarcodeConfirmation = false
    @Published var showingCategoryPicker = false
    @Published var showingLocationPicker = false
    @Published var showingTagPicker = false
    @Published var showingCamera = false
    @Published var showingError = false

    // MARK: - Data State
    @Published var pendingBarcode: String = ""
    @Published var pendingProductName: String = ""
    @Published var pendingCompany: String = ""
    @Published var pendingPrice: String = ""
    @Published var pendingCategory: ProductCategory = .none
    @Published var pendingIsOnSale: Bool = false
    @Published var pendingLocation: Location?
    @Published var selectedTags: [Tag] = []
    @Published var addToShoppingList = false
    @Published var isExistingProduct = false
    @Published var isScanInProgress = false
    @Published var errorMessage = ""

    // MARK: - Dependencies
    let addItemsViewModel: AddItemsViewModel
    let tagViewModel: TagViewModel
    let shoppingListViewModel: ShoppingListViewModel

    init(
        addItemsViewModel: AddItemsViewModel,
        tagViewModel: TagViewModel,
        shoppingListViewModel: ShoppingListViewModel
    ) {
        self.addItemsViewModel = addItemsViewModel
        self.tagViewModel = tagViewModel
        self.shoppingListViewModel = shoppingListViewModel
    }

    // MARK: - Navigation Methods

    func startCamera() {
        showingCamera = true
    }

    func stopCamera() {
        showingCamera = false
    }

    func showBarcodeConfirmation() {
        showingBarcodeConfirmation = true
    }

    func hideBarcodeConfirmation() {
        showingBarcodeConfirmation = false
    }

    func showCategoryPicker() {
        showingCategoryPicker = true
    }

    func hideCategoryPicker() {
        showingCategoryPicker = false
    }

    func showLocationPicker() {
        showingLocationPicker = true
    }

    func hideLocationPicker() {
        showingLocationPicker = false
    }

    func showTagPicker() {
        showingTagPicker = true
    }

    func hideTagPicker() {
        showingTagPicker = false
    }

    func showError(message: String) {
        errorMessage = message
        showingError = true
    }

    func hideError() {
        showingError = false
        errorMessage = ""
    }

    // MARK: - State Management

    func resetPendingData() {
        pendingBarcode = ""
        pendingProductName = ""
        pendingCompany = ""
        pendingPrice = ""
        pendingCategory = .none
        pendingIsOnSale = false
        pendingLocation = nil
        selectedTags = []
        addToShoppingList = false
        isExistingProduct = false
    }

    func setScanInProgress(_ inProgress: Bool) {
        isScanInProgress = inProgress
    }

    func setPendingData(
        barcode: String,
        productName: String,
        company: String,
        price: String,
        category: ProductCategory,
        isOnSale: Bool,
        location: Location?,
        tags: [Tag],
        addToList: Bool,
        isExisting: Bool
    ) {
        pendingBarcode = barcode
        pendingProductName = productName
        pendingCompany = company
        pendingPrice = price
        pendingCategory = category
        pendingIsOnSale = isOnSale
        pendingLocation = location
        selectedTags = tags
        addToShoppingList = addToList
        isExistingProduct = isExisting
    }
}
