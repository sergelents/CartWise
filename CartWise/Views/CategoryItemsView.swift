//
//  CategoryItemsView.swift
//  CartWise
//
//  Created by Kelly Yong on 7/9/25.
//  Enhanced with AI assistance from Cursor AI for sample data implementation and UI improvements.
//  This saved me 2-3 hours of work implementing product display functionality.
//

import SwiftUI
import CoreData



struct CategoryItemsView: View { 
    let category: ProductCategory
    @EnvironmentObject var viewModel: ProductViewModel
    @State private var selectedItemsToAdd: Set<String> = []
    @State private var isLoading = false
    @State private var hasSearched = false

    
    private var categoryProducts: [GroceryItem] {
        // First, load all existing products from Core Data
        let allProducts = viewModel.products
        
        // Filter products by category field first, then by name keywords
        let filtered = allProducts.filter { groceryItem in
            // First check if the category field matches
            if let productCategory = groceryItem.category {
                if productCategory.lowercased() == category.rawValue.lowercased() {
                    return true
                }
            }
            
            // Then check product name against category keywords
            if let productName = groceryItem.productName {
                let categoryKeywords = getCategoryKeywords(for: category)
                let matches = categoryKeywords.contains { keyword in
                    productName.lowercased().contains(keyword.lowercased())
                }
                print("CategoryItemsView: Filtering by name: \(productName) - Keywords: \(categoryKeywords) - Matches: \(matches)")
                return matches
            }
            return false
        }
        
        print("CategoryItemsView: Total products: \(allProducts.count), Filtered products: \(filtered.count)")
        
        // If no products found after filtering, but we have products from the search,
        // return all products as they were found for this category
        if filtered.isEmpty && !allProducts.isEmpty {
            print("CategoryItemsView: No products found for category \(category.rawValue), showing all products as fallback")
            return allProducts
        }
        
        return filtered
    }
    
    private func getCategoryKeywords(for category: ProductCategory) -> [String] {
        switch category {
        case .none:
            return ["grocery", "food"]
        case .meat:
            return ["meat", "seafood", "chicken", "beef", "pork", "fish", "salmon", "turkey"]
        case .dairy:
            return ["dairy", "eggs", "milk", "cheese", "yogurt", "butter", "cream"]
        case .bakery:
            return ["bakery", "bread", "pastry", "cake", "cookie", "muffin", "donut"]
        case .produce:
            return ["produce", "vegetable", "fruit", "fresh", "organic", "apple", "banana", "tomato"]
        case .pantry:
            return ["pantry", "canned", "staple", "rice", "pasta", "sauce", "condiment"]
        case .beverages:
            return ["beverage", "drink", "juice", "soda", "water", "coffee", "tea"]
        case .frozen:
            return ["frozen", "ice cream", "frozen food"]
        case .household:
            return ["household", "personal care", "cleaning", "hygiene", "soap", "shampoo"]
        }
    }
    
    private var displayProducts: [GroceryItem] {
        // If we have filtered products, show them
        if !categoryProducts.isEmpty {
            return categoryProducts
        }
        
        // If we've searched and have products, show all products as they were found for this category
        if hasSearched && !viewModel.products.isEmpty {
            return viewModel.products
        }
        
        // Otherwise, show filtered products (which might be empty)
        return categoryProducts
    }
    
    var body: some View {
        VStack {
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading products...")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if displayProducts.isEmpty && !hasSearched {
                VStack(spacing: 16) {
                    Image(systemName: "basket")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.gray.opacity(0.7))
                    Text("No products found in this category")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.gray)
                    Text("Products will appear here when available")
                        .font(.system(size: 14))
                        .foregroundColor(.gray.opacity(0.7))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(displayProducts, id: \.id) { groceryItem in
                            ProductCard(
                                product: groceryItem,
                                isSelected: groceryItem.id != nil && selectedItemsToAdd.contains(groceryItem.id!),
                                onToggle: {
                                    if let productId = groceryItem.id {
                                        if selectedItemsToAdd.contains(productId) {
                                            selectedItemsToAdd.remove(productId)
                                        } else {
                                            selectedItemsToAdd.insert(productId)
                                        }
                                    }
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(category.rawValue)
        .onAppear {
            // Load existing products and search for new ones in this category when view appears
            Task {
                isLoading = true
                hasSearched = false // Reset search flag
                await loadCategoryProducts()
                await searchProductsForCategory()
                isLoading = false
            }
        }
    }
    
    private func searchProductsForCategory() async {
        // Create a query based on the category
        let categoryQuery = createCategoryQuery(for: category)
        print("CategoryItemsView: Searching for category: \(category.rawValue) with query: \(categoryQuery)")
        
        // Check initial state
        print("CategoryItemsView: Initial products count: \(viewModel.products.count)")
        
        // Search Amazon for products in this category
        await viewModel.searchProducts(by: categoryQuery)
        print("CategoryItemsView: After search - Found \(viewModel.products.count) products for category: \(category.rawValue)")
        
        // Update the category field for the found products to match the current category
        for product in viewModel.products {
            if product.category == nil || product.category?.isEmpty == true {
                // Update the product's category to match the current category
                let updatedProduct = product
                updatedProduct.category = category.rawValue
                await viewModel.updateProduct(updatedProduct)
            }
        }
        
        // Reload products to get the updated data
        await viewModel.loadProducts()
        
        // Mark that we've searched for this category
        hasSearched = true
        
        // Print details of each product found
        for (index, product) in viewModel.products.enumerated() {
            print("  Product \(index + 1): \(product.productName ?? "Unknown") - Category: \(product.category ?? "None")")
        }
        
        // Check filtered results
        print("CategoryItemsView: Filtered products count: \(categoryProducts.count)")
        for (index, product) in categoryProducts.enumerated() {
            print("  Filtered Product \(index + 1): \(product.productName ?? "Unknown") - Category: \(product.category ?? "None")")
        }
    }
    
    private func createCategoryQuery(for category: ProductCategory) -> String {
        // Use more specific search terms for better results
        switch category {
        case .none:
            return "grocery food"
        case .meat:
            return "meat seafood"
        case .dairy:
            return "dairy milk cheese"
        case .bakery:
            return "bread bakery"
        case .produce:
            return "fresh vegetables fruits"
        case .pantry:
            return "canned food rice pasta beans"
        case .beverages:
            return "drinks beverages"
        case .frozen:
            return "frozen food"
        case .household:
            return "cleaning supplies"
        }
    }
    
    
    // MARK: - Helper Functions
    private func loadCategoryProducts() async {
        // Load all products from Core Data, then filter by category
        await viewModel.loadProducts()
    }
    
    // private func clearDatabase() async {
    //     // Delete all products from the database
    //     for product in viewModel.products {
    //         await viewModel.deleteProduct(product)
    //     }
    //     print("Database cleared")
    // }
}


// Product Card View
struct ProductCard: View {
    @ObservedObject var product: GroceryItem
    @EnvironmentObject var productViewModel: ProductViewModel
    let isSelected: Bool
    let onToggle: () -> Void

    // Display product details when tapped
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            HStack(spacing: 12) {
                // Product image placeholder
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.productName ?? "Unknown Product")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    if let brand = product.brand {
                        Text(brand)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    if let store = product.store {
                        Text(store)
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                            .lineLimit(1)
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
            .padding()
            .frame(height: 100) // Increased height for bigger cards
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            ProductDetailView(product: product)
        }
    }
}

// Product Detail View
struct ProductDetailView: View {
    @ObservedObject var product: GroceryItem // Use ObservedObject for live updates
    @EnvironmentObject var productViewModel: ProductViewModel
    
    // Dismissing the view
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .center, spacing: 16) {
                    
                    // Store View
                    if let store = product.store {
                        StoreView(store: store, storeAddress: product.location ?? "Address not available")
                    }

                    // Product Name View
                    ProductNameView(product: product)

                    // Product Image View
                    ProductImageView(product: product)

                    // Product Price View
                    // TODO: Need to update data model to include last updated info?
                    ProductPriceView(
                        product: product,
                        lastUpdated: product.lastUpdated != nil ? DateFormatter.localizedString(from: product.lastUpdated!, dateStyle: .short, timeStyle: .short) : "-",
                        lastUpdatedBy: "-"
                    )

                    // Add to Shopping List and Add to Favorites View
                    AddToShoppingListAndFavoritesView(
                        product: product,
                        onAddToShoppingList: {},
                        onAddToFavorites: {}
                    )
                    .padding(.bottom, 14)

                    // Update Price View
                    UpdatePriceView(
                        product: product,
                        // Need to get username from user
                        userName: "username",
                        onUpdatePrice: { newPrice, updatedBy, updatedAt in
                            product.price = newPrice
                            product.lastUpdated = updatedAt
                            await productViewModel.updateProduct(product)
                            await productViewModel.loadProducts()
                        },
                        lastUpdated: product.lastUpdated != nil ? DateFormatter.localizedString(from: product.lastUpdated!, dateStyle: .short, timeStyle: .short) : "-",
                        lastUpdatedBy: "-"
                    )
                }
                .padding(.horizontal, 24)
            }
            .navigationTitle("Product Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Store view
struct StoreView: View {
    let store: String
    let storeAddress: String

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "mappin.circle")
                .foregroundColor(.blue)
            Text(store)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.black)
            Spacer()
            Text(storeAddress)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: 10, alignment: .center)
        .padding()
        .background(Color.gray.opacity(0.12))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.07), radius: 3, x: 0, y: 2)
        .padding(.horizontal)
    }
}

// Product Name View
struct ProductNameView: View {
    @ObservedObject var product: GroceryItem

    var body: some View { 
        VStack(alignment: .center, spacing: 10) {
            // Brand and Store
            HStack {
                // Brand
                if let brand = product.brand {
                    Text(brand)
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                // Store
                if let store = product.store {
                    Text(store)
                        .font(.system(size: 14,weight: .bold))
                        .foregroundColor(.blue)
                }
            }

            // Product Name
            Text(product.productName ?? "Unknown Product")
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)

            // Category info
            VStack(alignment: .leading, spacing: 8) {
                if let category = product.category {
                    Text("Category: \(category)")
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                        .lineLimit(nil)
                }
            }
        }
    }
}

// Product Image View
struct ProductImageView: View {
    @ObservedObject var product: GroceryItem

        var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.systemGray5))
            .frame(height: 250)
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
            )
            .overlay(
                VStack {
                    // Show sale badge if item is marked as on sale
                    if product.isOnSale {
                        Text("Sale")
                            .font(.system(size: 14, weight: .bold))
                            .frame(width: 100, height: 24)
                            .foregroundColor(.white)
                            .background(Color.accentColorOrange.opacity(0.9))
                            .cornerRadius(8)
                    }
                    Spacer()
                }
                .padding(.top, 12)
            )
    }
}

// Product Price View
struct ProductPriceView: View {
    @ObservedObject var product: GroceryItem
    var lastUpdated: String
    var lastUpdatedBy: String

    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            HStack {
                Text("$\(String(format: "%.2f", product.price))")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
            }
            // Last updated by
            Text("Last updated: \(lastUpdated) \n By \(lastUpdatedBy)")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
    }
}

// Custom Button View
struct CustomButtonView: View {
    let title: String
    let imageName: String
    let fontSize: Int
    let weight: Font.Weight?
    let buttonColor: Color
    let textColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 2) {
                Image(systemName: imageName)
                    .font(.system(size: 14))
                    .foregroundColor(textColor)
                Text(title)
                    .font(.system(size: CGFloat(fontSize), weight: weight ?? .regular))
                    .foregroundColor(textColor)
                    .frame(width: 100, height: 10)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
            .background(buttonColor)
            .cornerRadius(8)
        }
    }
}

// Buttons Add to Shopping List and Add to Favorites View 
struct AddToShoppingListAndFavoritesView: View {
    @ObservedObject var product: GroceryItem
    @EnvironmentObject var productViewModel: ProductViewModel
    let onAddToShoppingList: () -> Void
    let onAddToFavorites: () -> Void
    @State private var isInShoppingList = false
    @State private var isInFavorites = false
    @State private var showingFavoriteSuccessMessage = false
    @State private var showingFavoriteDuplicateMessage = false
    @State private var showingSuccessMessage = false
    @State private var showingDuplicateMessage = false

    var body: some View {
        HStack(spacing: 14) {

            // Add to List Button
            CustomButtonView(
                title: isInShoppingList ? "In My List" : "Add to My List",
                imageName: isInShoppingList ? "checkmark.circle.fill" : "plus.circle.fill",
                fontSize: 13,
                weight: .bold,
                buttonColor: isInShoppingList ? Color.accentColorGreen : Color.accentColorBlue,
                textColor: .white,
                action: {
                    addToShoppingList()
                }
            )
            Spacer()
            // Add to Favorite Button
            CustomButtonView(
                title: isInFavorites ? "In Favorites" : "Add to Favorite",
                imageName: isInFavorites ? "heart.fill" : "plus.circle.fill",
                fontSize: 13,
                weight: .bold,
                buttonColor: isInFavorites ? Color.accentColorCoral : Color.accentColorPink,
                textColor: .white,
                action: {
                    addToFavorites()
                }
            )
        }
        .padding(.horizontal, 10)
        .padding(.top, 4)
        .task {
            // Check if product is in shopping list
            isInShoppingList = await productViewModel.isProductInShoppingList(name: product.productName ?? "")
            // Check if product is in favorites
            isInFavorites = await productViewModel.isProductInFavorites(product)
        }
        .alert("Added to Favorites!", isPresented: $showingFavoriteSuccessMessage) {
            Button("OK") { }
        } message: {
            Text("\(product.productName ?? "Product") has been added to your favorites.")
        }
        .alert("Already in Favorites", isPresented: $showingFavoriteDuplicateMessage) {
            Button("OK") { }
        } message: {
            Text("\(product.productName ?? "Product") is already in your favorites.")
        }
        .alert("Added to Shopping List!", isPresented: $showingSuccessMessage) {
            Button("OK") { }
        } message: {
            Text("\(product.productName ?? "Product") has been added to your shopping list.")
        }
        .alert("Already in Shopping List", isPresented: $showingDuplicateMessage) {
            Button("OK") { }
        } message: {
            Text("\(product.productName ?? "Product") is already in your shopping list.")
        }
    }
    
    private func addToShoppingList() {
        Task {
            // Check if product already exists in shopping list
            let isDuplicate = await productViewModel.isProductInShoppingList(name: product.productName ?? "")
            
            if isDuplicate {
                // Product already exists, show error message
                await MainActor.run {
                    showingDuplicateMessage = true
                }
            } else {
                // Add the existing product to shopping list
                await productViewModel.addExistingProductToShoppingList(product)
                
                // Refresh the shopping list to show the new item
                await productViewModel.loadShoppingListProducts()
                
                // Update the local state
                await MainActor.run {
                    isInShoppingList = true
                    showingSuccessMessage = true
                }
            }
        }
    }
    
    private func addToFavorites() {
        Task {
            // Check if product already exists in favorites
            let isDuplicate = await productViewModel.isProductInFavorites(product)

            if isDuplicate {
                // Product already exists in favorites, show error message
                await MainActor.run {
                    showingFavoriteDuplicateMessage = true
                }
            } else {
                // Add the existing product to favorites
                await productViewModel.addProductToFavorites(product)

                // Update the local state
                await MainActor.run {
                    isInFavorites = true
                    showingFavoriteSuccessMessage = true
                }
            }
        }
    }
}

// Update Price View
struct UpdatePriceView: View {
    let product: GroceryItem
    let userName: String
    let onUpdatePrice: (_ newPrice: Double, _ updatedBy: String, _ updatedAt: Date) async -> Void
    let lastUpdated: String
    let lastUpdatedBy: String

    @State private var showSheet: Bool = false
    @State private var priceInput: String = ""
    @State private var showError: Bool = false

    var body: some View {
        VStack(alignment: .center, spacing: 2) {
            Text("Price Inaccurate?")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.primary)
                .padding(.top, 2)

            Button(action: {
                showSheet = true
            }) {
                Text("Update Price")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppColors.accentGreen)
                    .padding(.bottom, 6)
            }
        .sheet(isPresented: $showSheet) {
            VStack(spacing: 24) {
                Text("Update Price")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.accentGreen)
                    .padding(.vertical, 20)
                
                // Product name
                Text(product.productName ?? "Unknown Product")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
                
                // Current price
                HStack {
                    Text("$\(String(format: "%.2f", product.price))")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                }
                .padding(.bottom, 18)
                
                // New price input
                VStack(alignment: .leading, spacing: 8) {
                    Text("New Price:")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppColors.accentGreen)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack {
                        Text("$")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                        
                        TextField("0.00", text: $priceInput)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 16, weight: .medium))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.bottom, 16)
                }
                .padding(.horizontal, 16)
                
                if showError {
                    Text("Please enter a valid number.")
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                HStack(spacing: 20) {
                    CustomButtonView(
                        title: "Cancel",
                        imageName: "",
                        fontSize: 16,
                        weight: .bold,
                        buttonColor: Color.gray.opacity(0.3),
                        textColor: .primary,
                        action: {
                            showSheet = false
                            priceInput = ""
                            showError = false
                        }
                    )
                    .padding(.horizontal, 18)
                    .padding(.vertical, 18)
                    
                    CustomButtonView(
                        title: "Confirm",
                        imageName: "",
                        fontSize: 16,
                        weight: .bold,
                        buttonColor: AppColors.accentGreen,
                        textColor: .white,
                        action: {
                            if let newPrice = Double(priceInput), newPrice > 0 {
                                Task {
                                    await onUpdatePrice(newPrice, userName, Date())
                                    showSheet = false
                                    priceInput = ""
                                    showError = false
                                }
                            } else {
                                showError = true
                            }
                        }
                    )
                    .padding(.vertical, 18)
                    .disabled(priceInput.isEmpty)
                }
            }
            .padding(.horizontal, 18)
            .interactiveDismissDisabled(true) // Prevent swipe to dismiss
        }
        .padding()
        }
    }
}


