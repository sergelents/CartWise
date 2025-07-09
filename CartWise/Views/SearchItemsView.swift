//
//  SearchItemsView.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/5/25.
//  Updated by Kelly Yong on 7/9/25: Added search bar and category list
//

import SwiftUI

struct SearchItemsView: View {
    // State variable for search bar input
    @State private var searchText = ""

    // Sample categories for testing, using Category model
    let categories: [Category] = [
        Category(name: "Meat & Seafood"),
        Category(name: "Dairy & Eggs"),
        Category(name: "Bakery"),
        Category(name: "Produce"),
        Category(name: "Pantry Items"),
        Category(name: "Beverages"),
        Category(name: "Frozen Foods"),
        Category(name: "Household & Personal Care")
    ]

    // Returns categories matching search text, or all if search is empty
    var filteredCategories: [Category] {
        if searchText.isEmpty {
            return categories
        } else {
            // Case-insensitive search
            return categories.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationView {
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
                        Text(category.name)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Search Items")
        }
    }
}

