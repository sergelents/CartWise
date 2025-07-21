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
    @State private var searchResults: [GroceryItem] = []
    @State private var isSearching = false
    @State private var selectedCategory: ProductCategory? = nil

    @StateObject private var viewModel = ProductViewModel(repository: ProductRepository())

    // Returns categories matching search text, or all if search is empty
    // Predefined categories
    var filteredCategories: [ProductCategory] {
        let allCategoriesExceptNone = ProductCategory.allCases.filter { $0 != .none }
        
        if searchText.isEmpty {
            return allCategoriesExceptNone
        } else {
            // Case-insensitive search
            return allCategoriesExceptNone.filter { $0.rawValue.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    // Get unique categories from actual products
    var availableCategories: [ProductCategory] {
        let categories = Set(viewModel.products.compactMap { groceryItem in
            ProductCategory(rawValue: groceryItem.category ?? "")
        })
        return Array(categories).sorted { $0.rawValue < $1.rawValue }
    }

    var body: some View {
        NavigationStack {
            VStack {
                searchBarView
                
                if !searchText.isEmpty && !searchResults.isEmpty {
                    searchResultsView
                } else {
                    categoryGridView
                }
            }
            .navigationTitle("Search")
            .onAppear {
                Task {
                    await viewModel.loadProducts()
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var searchBarView: some View {
        VStack(spacing: 8) {
            HStack {
                TextField("Search products...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        Task {
                            await performSearch()
                        }
                    }
                
                // Category selection button - filtering
                Menu {
                    ForEach(filteredCategories, id: \.self) { category in
                        Button(category.rawValue) {
                            selectCategory(category)
                        }
                    }
                    Divider()
                    Button("Clear Category") {
                        clearCategorySelection()
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundColor(.blue)
                        .font(.system(size: 20))
                }
                
                if isSearching {
                    ProgressView()
                        .scaleEffect(0.8)
                }
                
                if !searchText.isEmpty || selectedCategory != nil {
                    Button(action: {
                        searchText = ""
                        clearCategorySelection()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 18))
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Show selected category if any
            if let selectedCategory = selectedCategory {
                HStack {
                    Text("Category: \(selectedCategory.rawValue)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Button("Clear Category") {
                        clearCategorySelection()
                    }
                    .font(.system(size: 12))
                    .foregroundColor(.red)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
    }
    
    private var searchResultsView: some View {
        List(searchResults, id: \.id) { product in
            NavigationLink(destination: ProductDetailView(product: product, productViewModel: viewModel)) {
                SearchResultRowView(product: product)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .listStyle(PlainListStyle())
    }
    
    private var categoryGridView: some View {
        ScrollView {
            VStack(spacing: 16) {
                categoryGrid
            }
        }
    }
    
    private var categoryGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)
        
        return LazyVGrid(columns: columns, spacing: 16) {
            ForEach(filteredCategories, id: \.self) { category in
                NavigationLink(destination: CategoryItemsView(category: category)) {
                    CategoryCard(
                        category: category, 
                        productCount: getProductCount(for: category)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
    }


    // MARK: - Helper Functions
    private func performSearch() async {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        defer { isSearching = false }
        
        do {
            // Create enhanced query with category keywords if category is selected
            let enhancedQuery = createEnhancedQuery(searchText: searchText, category: selectedCategory)
            await viewModel.searchProductsOnAmazon(by: enhancedQuery)
            searchResults = viewModel.products
        } catch {
            print("Search error: \(error)")
            searchResults = []
        }
    }
    
    // Helper function to enhance search query with category keywords
    private func createEnhancedQuery(searchText: String, category: ProductCategory?) -> String {
        guard let category = category else {
            return searchText
        }
        
        switch category {
        case .none:
            return searchText
        case .meat:
            return "\(searchText) meat seafood"
        case .dairy:
            return "\(searchText) dairy eggs milk cheese"
        case .bakery:
            return "\(searchText) bakery bread pastry"
        case .produce:
            return "\(searchText) fresh produce vegetables fruits"
        case .pantry:
            return "\(searchText) pantry staples canned goods"
        case .beverages:
            return "\(searchText) beverages drinks"
        case .frozen:
            return "\(searchText) frozen foods"
        case .household:
            return "\(searchText) household personal care"
        }
    }
    
    private func selectCategory(_ category: ProductCategory) {
        selectedCategory = category
        // Automatically perform search with selected category
        Task {
            await performSearch()
        }
    }
    
    private func clearCategorySelection() {
        selectedCategory = nil
        searchResults = []
    }
    
    private func getProductCount(for category: ProductCategory) -> Int {
        return viewModel.products.filter { $0.category == category.rawValue }.count
    }
}

// MARK: - Search Result Row
struct SearchResultRowView: View {
    let product: GroceryItem
    
    var body: some View {
        HStack(spacing: 12) {
            // Product image placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.productName ?? "Unknown Product")
                    .font(.system(size: 16, weight: .medium))
                    .lineLimit(2)
                
                if let brand = product.brand, !brand.isEmpty {
                    Text(brand)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                if let store = product.store, !store.isEmpty {
                    Text(store)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if product.price > 0 {
                    Text("$\(String(format: "%.2f", product.price))")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                if let category = product.category {
                    Text(category)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Category Card View
struct CategoryCard: View {
    let category: ProductCategory
    let productCount: Int
    
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
                .minimumScaleFactor(0.8)
            
            // Product count
            if productCount > 0 {
                Text("\(productCount) items")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 95, maxHeight: 95)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // Icon name for each category - need to change to better icons..
    private var iconName: String {
        switch category {
        case .none: return ""
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


#Preview {
    SearchItemsView()
}
