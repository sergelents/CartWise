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
    private let searchViewModel: SearchViewModel
    private let tagViewModel: TagViewModel

    init(searchViewModel: SearchViewModel, tagViewModel: TagViewModel) {
        self.searchViewModel = searchViewModel
        self.tagViewModel = tagViewModel
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
