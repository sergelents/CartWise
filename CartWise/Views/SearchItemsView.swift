//
//  SearchItemsView.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/5/25.
//  Updated by Kelly Yong on 7/9/25: Added category browsing
//

import SwiftUI

struct SearchItemsView: View {
    // State variable for search bar input
    @State private var searchText = ""

    // Returns categories matching search text, or all if search is empty
    var filteredCategories: [ProductCategory] {
        if searchText.isEmpty {
            ProductCategory.allCases
        } else {
            // Case-insensitive search
            ProductCategory.allCases.filter { $0.rawValue.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        VStack {
            // Search bar
            TextField("Search...", text: $searchText)
                .padding(8)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                .padding(.horizontal)

            // List of filtered categories
            List(filteredCategories) { category in
                NavigationLink(destination: CategoryItemsView(category: category)) {
                    Text(category.rawValue)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Search Items")
    }
}

