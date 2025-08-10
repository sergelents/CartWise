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
    @State private var selectedCategory: ProductCategory?
    @State private var selectedTag: Tag?
    @State private var showingTagPicker = false
    @State private var selectedLocation: Location?
    @State private var userLocations: [Location] = []
    @State private var searchProducts: [GroceryItem] = [] // Separate array for search products
    @EnvironmentObject var viewModel: ProductViewModel
    // Computed property for search results that updates automatically
    private var searchResults: [GroceryItem] {
        guard !searchText.isEmpty else { return [] }
        // If a tag is selected, filter from products that have that tag
        let productsToSearch = selectedTag != nil ?
            searchProducts.filter { $0.tagArray.contains(selectedTag!) } :
            searchProducts
        // Filter products to match search text
        let filtered = productsToSearch.filter { product in
            guard let name = product.productName?.lowercased() else { return false }
            return name.contains(searchText.lowercased())
        }
        return filtered
    }
    // Computed property for tag-filtered results
    private var tagFilteredResults: [GroceryItem] {
        guard let selectedTag = selectedTag else { return [] }
        // If we have search text, use searchResults (which already respects the tag)
        if !searchText.isEmpty {
            return searchResults
        }
        // Otherwise filter from all products
        return searchProducts.filter { product in
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
        let categories = Set(searchProducts.compactMap { groceryItem in
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
                    // Load products into local array without affecting viewModel.products
                    await loadSearchProducts()
                    await viewModel.loadTags()
                    await loadUserLocations()
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
                    .onChange(of: searchText) { _, _ in
                        // Real-time filtering is handled by computed properties
                        // No need to call performSearch() as searchResults updates automatically
                    }
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
                    }, label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 18))
                    })
                }
                // Tag filter button
                Button(action: {
                    showingTagPicker = true
                }, label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundColor(selectedTag != nil ? .blue : .gray)
                        .font(.system(size: 20))
                })
                if selectedTag != nil {
                    Button(action: {
                        selectedTag = nil
                    }, label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 16))
                    })
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
            NavigationLink(destination: ProductDetailView(product: product, selectedLocation: selectedLocation)) {
                SearchResultRowView(product: product)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .listStyle(PlainListStyle())
    }
    private var tagFilteredResultsView: some View {
        VStack {
            if tagFilteredResults.isEmpty {
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "tag")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.gray.opacity(0.7))
                    Text("No products found with tag '\(selectedTag?.displayName ?? "Unknown")'")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    Text("Try selecting a different tag or adding tags to products")
                        .font(.system(size: 14))
                        .foregroundColor(.gray.opacity(0.7))
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 40)
            } else {
                List(tagFilteredResults, id: \.id) { product in
                    NavigationLink(
                        destination: ProductDetailView(product: product, selectedLocation: selectedLocation)
                    ) {
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
    private func loadSearchProducts() async {
        // Save current shopping list products
        let currentShoppingListProducts = viewModel.products

        // Load all products temporarily
        await viewModel.loadProducts()

        // Store search products and restore shopping list
        await MainActor.run {
            searchProducts = viewModel.products
            viewModel.products = currentShoppingListProducts
        }
    }

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

        // Save current shopping list products
        let currentShoppingListProducts = viewModel.products

        // Search Core Data for existing products only (offline-first)
        await viewModel.searchProducts(by: searchText)

        // Update local search products and restore shopping list
        await MainActor.run {
            searchProducts = viewModel.products
            viewModel.products = currentShoppingListProducts
        }

        print("Search completed: \(searchProducts.count) local results")
    }
    private func selectCategory(_ category: ProductCategory) {
        selectedCategory = category
        // Automatically perform search with selected category
        Task {
            await performSearch()
        }
    }
    // MARK: - Helper Functions
    private func loadUserLocations() async {
        await viewModel.loadLocations()
        userLocations = viewModel.locations
        // Set selected location to default or first favorited location
        selectedLocation = userLocations.first { $0.isDefault } ??
                           userLocations.first { $0.favorited } ??
                           userLocations.first
    }
}
// MARK: - Search Result Row
struct SearchResultRowView: View {
    @ObservedObject var product: GroceryItem
    var body: some View {
        HStack(spacing: 12) {
                                    // Product image
                        ProductImageView(
                            product: product,
                            size: CGSize(width: 50, height: 50),
                            cornerRadius: 8,
                            showSaleBadge: false
                        )
            VStack(alignment: .leading, spacing: 4) {
                Text(product.productName ?? "Unknown Product")
                    .font(.system(size: 16, weight: .medium))
                    .lineLimit(2)
                if let brand = product.brand, !brand.isEmpty {
                    Text(brand)
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
    @State private var searchText = ""
    // Search tags
    var filteredTags: [Tag] {
        if searchText.isEmpty {
            return tags
        } else {
            return tags.filter { tag in
                tag.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search tags...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal)
                .padding(.top)
                List {
                    ForEach(filteredTags, id: \.id) { tag in
                        Button(action: {
                            selectedTag = tag
                            dismiss()
                        }, label: {
                            HStack {
                                Text(tag.displayName)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedTag?.id == tag.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        })
                        .buttonStyle(PlainButtonStyle())
                    }
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
