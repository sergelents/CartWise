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
    @State private var isSearching = false
    @State private var selectedCategory: ProductCategory? = nil
    @State private var selectedTag: Tag? = nil
    @State private var showingTagPicker = false

    @EnvironmentObject var viewModel: ProductViewModel
    
    // Computed property for search results that updates automatically
    private var searchResults: [GroceryItem] {
        guard !searchText.isEmpty else { return [] }
        // Filter viewModel products to match search text
        let filtered = viewModel.products.filter { product in
            guard let name = product.productName?.lowercased() else { return false }
            return name.contains(searchText.lowercased())
        }
        return filtered
    }
    
    // Computed property for tag-filtered results
    private var tagFilteredResults: [GroceryItem] {
        guard let selectedTag = selectedTag else { return viewModel.products }
        return viewModel.products.filter { product in
            product.tagArray.contains(selectedTag)
        }
    }

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
                } else if selectedTag != nil {
                    tagFilteredResultsView
                } else {
                    categoryGridView
                }
            }
            .navigationTitle("Search")
            .onAppear {
                Task {
                    await viewModel.loadProducts()
                    await viewModel.loadTags()
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
                
                if isSearching {
                    ProgressView()
                        .scaleEffect(0.8)
                }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 18))
                    }
                }
                
                // Tag filter button
                Button(action: {
                    showingTagPicker = true
                }) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundColor(selectedTag != nil ? .blue : .gray)
                        .font(.system(size: 20))
                }
                
                if selectedTag != nil {
                    Button(action: {
                        selectedTag = nil
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 16))
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

                    .font(.system(size: 12))
                    .foregroundColor(.red)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
        .sheet(isPresented: $showingTagPicker) {
            SingleTagPickerView(selectedTag: $selectedTag, tags: viewModel.tags)
        }
    }
    
    private var searchResultsView: some View {
        List(searchResults, id: \.id) { product in
            NavigationLink(destination: ProductDetailView(product: product)) {
                SearchResultRowView(product: product)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .listStyle(PlainListStyle())
    }
    
    private var tagFilteredResultsView: some View {
        VStack {
            if tagFilteredResults.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "tag")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.gray.opacity(0.7))
                    Text("No products found with tag '\(selectedTag?.displayName ?? "Unknown")'")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.gray)
                    Text("Try selecting a different tag or adding tags to products")
                        .font(.system(size: 14))
                        .foregroundColor(.gray.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(tagFilteredResults, id: \.id) { product in
                    NavigationLink(destination: ProductDetailView(product: product)) {
                        SearchResultRowView(product: product)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .listStyle(PlainListStyle())
            }
        }
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
                        category: category
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
            return
        }
        
        await MainActor.run {
            isSearching = true
        }
        
        defer {
            Task { @MainActor in
                isSearching = false
            }
        }
        
        // First, search Core Data for existing products
        await viewModel.searchProducts(by: searchText)
        let coreDataResults = viewModel.products
        
        // Then search Amazon API for new products
        await viewModel.searchProducts(by: searchText)
        let apiResults = viewModel.products
        
        // Combine results, avoiding duplicates
        var combinedResults: [GroceryItem] = []
        var seenNames = Set<String>()
        
        // Add Core Data results first
        for product in coreDataResults {
            if let name = product.productName?.lowercased() {
                seenNames.insert(name)
                combinedResults.append(product)
            }
        }
        
        // Add API results that aren't duplicates
        for product in apiResults {
            if let name = product.productName?.lowercased() {
                if !seenNames.contains(name) {
                    seenNames.insert(name)
                    combinedResults.append(product)
                }
            }
        }
        
        // Update the viewModel products with combined results
        // Note: We need to update the viewModel products directly
        print("Search completed: \(coreDataResults.count) Core Data results, \(apiResults.count) API results, \(combinedResults.count) total")
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
}

// MARK: - Search Result Row
struct SearchResultRowView: View {
    @ObservedObject var product: GroceryItem
    
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
                
                // Show tags if they exist
                if !product.tagArray.isEmpty {
                    TagDisplayView(tags: product.tagArray)
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


// MARK: - Single Tag Picker View
struct SingleTagPickerView: View {
    @Binding var selectedTag: Tag?
    let tags: [Tag]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(tags, id: \.id) { tag in
                    Button(action: {
                        selectedTag = tag
                        dismiss()
                    }) {
                        HStack {
                            Text(tag.displayName)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if selectedTag?.id == tag.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Select Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Tag Display View - contains the individual tag chips
struct TagDisplayView: View {
    let tags: [Tag]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(tags, id: \.id) { tag in
                    SearchTagChipView(tag: tag)
                }
            }
        }
    }
}

// MARK: - Individual Tag Chip View
struct SearchTagChipView: View {
    let tag: Tag
    
    var body: some View {
        Text(tag.displayName)
            .font(.system(size: 10))
            .foregroundColor(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color(.systemGray6))
            .cornerRadius(8)
    }
}

#Preview {
    SearchItemsView()
}
