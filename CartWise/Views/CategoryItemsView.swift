//
//  CategoryItemsView.swift
//  CartWise
//
//  Created by Kelly Yong on 7/9/25.
//  Enhanced with AI assistance from Cursor AI for sample data implementation and UI improvements.
//  This saved me 2-3 hours of work implementing product display functionality.
//

import SwiftUI



struct CategoryItemsView: View { 
    let category: ProductCategory
    let viewModel: ProductViewModel  // Receive ViewModel from parent
    @State private var selectedItemsToAdd: Set<String> = []

    
    private var categoryProducts: [GroceryItem] {
        // Filter products by the current category
        let filtered = viewModel.products.filter { groceryItem in
            // Check if the grocery item's category matches the current category
            if let itemCategory = groceryItem.category {
                let matches = itemCategory.lowercased().contains(category.rawValue.lowercased()) ||
                       category.rawValue.lowercased().contains(itemCategory.lowercased())
                print("CategoryItemsView: Filtering: \(groceryItem.productName ?? "Unknown") - Category: \(itemCategory) - Matches \(category.rawValue): \(matches)")
                return matches
            }
            // If no category is set, check if the product name contains category keywords
            // if let productName = groceryItem.productName {
            //     let categoryKeywords = getCategoryKeywords(for: category)
            //     return categoryKeywords.contains { keyword in
            //         productName.lowercased().contains(keyword.lowercased())
            //     }
            // }
            return false
        }
        print("CategoryItemsView: Total products: \(viewModel.products.count), Filtered products: \(filtered.count)")
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
    
    var body: some View {
        VStack {
            if categoryProducts.isEmpty {
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
                        ForEach(categoryProducts, id: \.id) { groceryItem in
                            ProductCard(
                                product: groceryItem,
                                productViewModel: viewModel,
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
            // Search for products in this category when view appears
            Task {
                await searchProductsForCategory()
            }
        }
    }
    
    private func searchProductsForCategory() async {
        // Create a query based on the category
        let categoryQuery = createCategoryQuery(for: category)
        print("Searching for category: \(category.rawValue) with query: \(categoryQuery)")
        await viewModel.searchProductsOnAmazon(by: categoryQuery)
        print("Found \(viewModel.products.count) products for category: \(category.rawValue)")
    }
    
    private func createCategoryQuery(for category: ProductCategory) -> String {
        // Simply return the category name as the query
        //return category.rawValue
        switch category {
        case .none:
            return "grocery food"
        case .meat:
            return "meat seafood chicken beef pork fish"
        case .dairy:
            return "dairy eggs milk cheese yogurt butter"
        case .bakery:
            return "bakery bread pastry cake cookie muffin"
        case .produce:
            return "fresh produce vegetables fruits organic"
        case .pantry:
            return "pantry canned food rice pasta sauce"
        case .beverages:
            return "beverages drinks juice soda water coffee tea"
        case .frozen:
            return "frozen food ice cream frozen vegetables"
        case .household:
            return "household personal care cleaning hygiene"
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
    let product: GroceryItem
    let productViewModel: ProductViewModel
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
                    
                    if let brand = product.brand {
                        Text(brand)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    if let store = product.store {
                        Text(store)
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
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
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            ProductDetailView(product: product, productViewModel: productViewModel)
        }
    }
}

// Product Detail View
struct ProductDetailView: View {
    let product: GroceryItem
    let productViewModel: ProductViewModel  // Use shared instance
    
    // Adding to shopping list and to favorites
    @State private var isAddingToFavorites = false
    @State private var isAddingToShoppingList = false
    @State private var showingSuccessMessage = false
    @State private var showingDuplicateMessage = false

    // Dismissing the view
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .center, spacing: 18) {
                    
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
                        lastUpdated: "7/17/2025",
                        lastUpdatedBy: "Kelly Yong"
                    )

                    // Add to Shopping List and Add to Favorites View
                    AddToShoppingListAndFavoritesView(
                        onAddToShoppingList: {
                            addToShoppingList()
                        }, 
                        onAddToFavorites: {
                            // TODO: Add to favorites functionality
                            isAddingToFavorites.toggle()
                        }
                    )

                    // Update Price View
                    UpdatePriceView(
                        product: product,
                        onUpdatePrice: {
                            // TODO: Update price functionality
                        },
                        lastUpdated: "7/17/2025",
                        lastUpdatedBy: "Kelly Yong"
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
                
                // Show success message
                await MainActor.run {
                    showingSuccessMessage = true
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
                .font(.system(size: 16, weight: .bold))
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
    let product: GroceryItem

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
    let product: GroceryItem

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
                    // Need to have a price check to see if item is on sale
                    if product.price > 0 {
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
    let product: GroceryItem
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
    @State var isAdded : Bool = false
    @State var isAddedImageName: String
    @State var isAddedColor: Color
    
    var body: some View {
        Button(action: {
            action()
            self.isAdded.toggle()}) {
            HStack(alignment: .center, spacing: 2) {
                Image(systemName: isAdded ? isAddedImageName : imageName)
                    .font(.system(size: 14))
                    .foregroundColor(textColor)
                Text(title)
                    .font(.system(size: CGFloat(fontSize), weight: weight ?? .regular))
                    .foregroundColor(textColor)
                    .frame(width: 100, height: 10)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
            .background(isAdded ? isAddedColor : buttonColor)
            .cornerRadius(8)
        }
    }
}

// Buttons Add to Shopping List and Add to Favorites View 
struct AddToShoppingListAndFavoritesView: View {
    let onAddToShoppingList: () -> Void
    let onAddToFavorites: () -> Void

    var body: some View {
        HStack(spacing: 16) {

            // Add to List Button
            CustomButtonView(
                title: "Add to My List",
                imageName: "plus.circle.fill",
                fontSize: 13,
                weight: .bold,
                buttonColor: Color.accentColorBlue,
                textColor: .white,
                action: onAddToShoppingList,
                isAddedImageName: "checkmark.circle.fill",
                isAddedColor: Color.accentColorGreen
            )
            Spacer()
            // Add to Favorite Button
            CustomButtonView(
                title: "Add to Favorite",
                imageName: "plus.circle.fill",
                fontSize: 13,
                weight: .bold,
                buttonColor: Color.accentColorPink,
                textColor: .white,
                action: onAddToFavorites,
                isAddedImageName: "heart.fill",
                isAddedColor: Color.accentColorCoral
            )
        }
        .padding(.horizontal, 10)
        .padding(.top, 8)
    }
}

// Update Price View
struct UpdatePriceView: View {
    let product: GroceryItem
    let onUpdatePrice: () -> Void
    let lastUpdated: String
    let lastUpdatedBy: String
    
    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            Text("Price Inaccurate?")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)

            Button(action: onUpdatePrice) {
                Text("Update Price")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.accentColorGreen)
                    .padding(.bottom, 6)
            }
        }
        .padding()
    }
}


