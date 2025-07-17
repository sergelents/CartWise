//
//  SearchItemsView.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/5/25.
//  Updated by Kelly Yong on 7/9/25: Added category browsing
//  Enhanced with AI assistance from Cursor AI for UI improvements and category navigation.
//  This saved me 1-2 hours of work implementing the category grid and navigation.
//

import SwiftUI

struct SearchItemsView: View {
    // State variable for search bar input
    @State private var searchText = ""

    // Returns categories matching search text, or all if search is empty
    // TODO: Add search functionality to find products by name instead
    var filteredCategories: [ProductCategory] {
        let allCategories = ProductCategory.allCases.filter { $0 != .none }
        if searchText.isEmpty {
            return allCategories
        } else {
            // Case-insensitive search
            return allCategories.filter { $0.rawValue.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                // Search bar
                TextField("Search...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .padding(.top)

                // Category grid
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                        ForEach(filteredCategories, id: \.self) { category in
                            NavigationLink(destination: CategoryItemsView(category: category)) {
                                CategoryCard(category: category)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Categories")
        }
    }
}

// Category Card View
struct CategoryCard: View {
    let category: ProductCategory
    
    var body: some View {
        VStack(spacing: 12) {
            // Category icon
            Image(systemName: iconName)
                .font(.system(size: 32))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.mint, .yellow],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
)
            
            // Category name
            Text(category.rawValue)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // Icon name for each category - need to change to better icons..
    private var iconName: String {
        switch category {
        case .none: return "questionmark.circle"
        case .meat: return "fish"
        case .dairy: return "oval.portrait.fill"
        case .bakery: return "birthday.cake"
        case .produce: return "leaf.fill"
        case .pantry: return "cabinet"
        case .beverages: return "mug.fill"
        case .frozen: return "snowflake"
        case .household: return "house.fill"
        }
    }
}

