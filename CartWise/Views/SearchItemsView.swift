//
//  SearchItemsView.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/5/25.
//  Updated by Kelly Yong on 7/9/25: Added search bar and category list
//

import SwiftUI

// Example: Assume you have an array of products
let products: [OpenFoodFactsProduct] = [] // Replace with your actual products source

// Build a unique, sorted list of all categories from all products
let allCategories = products.flatMap { $0.categoryList }
let uniqueCategoryNames = Array(Set(allCategories.map { $0.name })).sorted()
let categories = uniqueCategoryNames.map { Category(name: $0) }

struct SearchItemsView: View {
    @State private var searchText = ""
    // Use the unique categories list
    // let categories = [Category] // Now defined above

    // Returns categories matching the search text, or all if search is empty
    var filteredCategories: [Category] {
        if searchText.isEmpty {
            return categories
        } else {
            return categories.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                TextField("Search...", text: $searchText)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)

                // Grid or list of categories
                List(filteredCategories) { category in
                    NavigationLink(destination: CategoryItemsView(category: category)) {
                        Text(category.name)
                    }
                }
            }
            .navigationTitle("Search Items")
        }
    }
}

