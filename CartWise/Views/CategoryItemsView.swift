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
import Foundation
struct CategoryItemsView: View {
    let category: ProductCategory
    @EnvironmentObject var viewModel: ProductViewModel
    @State private var selectedItemsToAdd: Set<String> = []
    @State private var isLoading = false
    @State private var hasSearched = false
    // Location management
    @State private var userLocations: [Location] = []
    @State private var selectedLocation: Location?
    @State private var isLoadingLocations = false
    @State private var showingLocationPicker = false
    @State private var currentUsername: String = "Unknown User"
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
        // Don't know if Serg wants to keep show all products as fallback logic:
        // If no products found after filtering, but we have products from the search,
        // return all products as they were found for this category
        // if filtered.isEmpty && !allProducts.isEmpty {
        //     print("CategoryItemsView: No products found for category \(category.rawValue), showing all products as fallback")
        //     return allProducts
        // }
        // If no products match the category, return empty array
        if filtered.isEmpty {
            print("CategoryItemsView: No products found for category \(category.rawValue), showing empty list")
            return []
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
    // Already handles show filtered products
    private var displayProducts: [GroceryItem] {
        return categoryProducts
    }
    // Not sure if Serg wants to keep this logic for showing all products as fallback
    // private var displayProducts: [GroceryItem] {
    //     // If we have filtered products, show them
    //     if !categoryProducts.isEmpty {
    //         return categoryProducts
    //     }
    //     // If we've searched and have products, show all products as they were found for this category
    //     if hasSearched && !viewModel.products.isEmpty {
    //         return viewModel.products
    //     }
    //     // Otherwise, show filtered products (which might be empty)
    //     return categoryProducts
    // }
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
            } else if displayProducts.isEmpty {
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
                                },
                                selectedLocation: selectedLocation
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
                await loadUserLocations() // Add location loading
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
    private func loadUserLocations() async {
        await viewModel.loadLocations()
        userLocations = viewModel.locations
        // Set selected location to default or first favorited location
        selectedLocation = userLocations.first { $0.isDefault } ?? userLocations.first { $0.favorited } ?? userLocations.first
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
    let selectedLocation: Location?
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
                    // Store info removed since we removed store from GroceryItem
                }
                Spacer()
            }
            .padding()
            .frame(height: 100) // Increased height for bigger cards
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            ProductDetailView(product: product, selectedLocation: selectedLocation)
        }
    }
}
// Product Detail View
struct ProductDetailView: View {
    @ObservedObject var product: GroceryItem // Use ObservedObject for live updates
    @EnvironmentObject var productViewModel: ProductViewModel
    let selectedLocation: Location?
    // Dismissing the view
    @Environment(\.dismiss) private var dismiss
    // State for delete confirmation
    @State private var showDeleteConfirmation = false
    // Location picker state
    @State private var userLocations: [Location] = []
    @State private var currentSelectedLocation: Location?
    @State private var showingLocationPicker = false
    @State private var currentUsername: String = "Unknown User"
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .center, spacing: 16) {
                    // Store View
                    StoreView(
                        selectedLocation: currentSelectedLocation ?? selectedLocation,
                        onTap: {
                            showingLocationPicker = true
                        }
                    )
                    // Product Name View
                    ProductNameView(product: product)
                    // Product Image View
                    ProductImageView(product: product)
                    // Product Price View
                    // TODO: Need to update data model to include last updated info?
                    ProductPriceView(
                        product: product,
                        currentSelectedLocation: currentSelectedLocation ?? selectedLocation
                    )
                    // Update Price View - Moved up for better accessibility
                    UpdatePriceView(
                        product: product,
                        // Get actual username from user
                        userName: currentUsername,
                        onUpdatePrice: { newPrice, updatedBy, updatedAt in
                            // Update the product's lastUpdated
                            product.lastUpdated = updatedAt
                            // Create or update a GroceryItemPrice for this product at the current location
                            await updateProductPrice(product: product, newPrice: newPrice, location: currentSelectedLocation ?? selectedLocation)
                            // Create social feed entry for price update
                            await createSocialFeedEntry(product: product, newPrice: newPrice, location: currentSelectedLocation ?? selectedLocation, username: currentUsername)
                            await productViewModel.updateProduct(product)
                            await productViewModel.loadProducts()
                        },
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
                }
                .padding(.horizontal, 24)
            }
            .navigationTitle("Product Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Delete") {
                        // Show confirmation dialog
                        showDeleteConfirmation = true
                    }
                    .foregroundColor(.red)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Delete Product", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        await deleteProduct()
                    }
                }
            } message: {
                Text("Are you sure you want to delete this product? This action cannot be undone.")
            }
            .onAppear {
                Task {
                    await loadLocationsForDetail()
                    currentUsername = await getCurrentUsername()
                }
            }
        }
        .sheet(isPresented: $showingLocationPicker) {
            LocationPickerModal(
                locations: userLocations,
                product: product,
                selectedLocation: $currentSelectedLocation,
                onDismiss: { showingLocationPicker = false }
            )
        }
    }
    private func deleteProduct() async {
        do {
            // Permanently delete product from Core Data
            await productViewModel.permanentlyDeleteProduct(product)
            // Force reload products to update UI
            await productViewModel.loadProducts()
            // Dismiss detail view
            dismiss()
        } catch {
            print("Error deleting product: \(error)")
        }
    }
    private func updateProductPrice(product: GroceryItem, newPrice: Double, location: Location?) async {
        do {
            let context = await CoreDataStack.shared.viewContext
            // Get the product in the current context
            let productFetchRequest: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
            productFetchRequest.predicate = NSPredicate(format: "id == %@", product.id ?? "")
            productFetchRequest.fetchLimit = 1
            let products = try context.fetch(productFetchRequest)
            guard let productInContext = products.first else {
                print("Error: Could not find product in context")
                return
            }
            // Use the provided location or return if no location is selected
            guard let location = location else {
                print("Error: No location selected for price update")
                return
            }
            // Get the location in the current context
            let locationFetchRequest: NSFetchRequest<Location> = Location.fetchRequest()
            locationFetchRequest.predicate = NSPredicate(format: "id == %@", location.id ?? "")
            locationFetchRequest.fetchLimit = 1
            let locations = try context.fetch(locationFetchRequest)
            guard let locationInContext = locations.first else {
                print("Error: Could not find location in context")
                return
            }
            // Check if there's an existing price for this product and location
            let priceFetchRequest: NSFetchRequest<GroceryItemPrice> = GroceryItemPrice.fetchRequest()
            priceFetchRequest.predicate = NSPredicate(format: "groceryItem == %@ AND location.id == %@", productInContext, locationInContext.id ?? "")
            priceFetchRequest.fetchLimit = 1
            let existingPrices = try context.fetch(priceFetchRequest)
            if let existingPrice = existingPrices.first {
                // Update existing price for this location
                existingPrice.price = newPrice
                existingPrice.lastUpdated = Date()
                print("Updated existing price for location: \(locationInContext.name ?? "Unknown")")
            } else {
                // Create new price for this specific location
                let newPrice = GroceryItemPrice(
                    context: context,
                    id: UUID().uuidString,
                    price: newPrice,
                    currency: "USD",
                    store: locationInContext.name,
                    groceryItem: productInContext,
                    location: locationInContext,
                    updatedBy: await getCurrentUsername()
                )
                print("Created new price for location: \(locationInContext.name ?? "Unknown")")
            }
            try context.save()
            print("Successfully updated product price to $\(newPrice) for location: \(locationInContext.name ?? "Unknown")")
            
            // Update user reputation
            let currentUsername = await getCurrentUsername()
            if let currentUser = try context.fetch(NSFetchRequest<UserEntity>(entityName: "UserEntity")).first(where: { $0.username == currentUsername }) {
                // Use Task to avoid potential context issues
                Task {
                    await ReputationManager.shared.updateUserReputation(userId: currentUser.id ?? "")
                    print("Updated reputation for user: \(currentUsername)")
                }
            }
        } catch {
            print("Error updating product price: \(error)")
        }
    }
    private func loadLocationsForDetail() async {
        await productViewModel.loadLocations()
        userLocations = productViewModel.locations
        currentSelectedLocation = selectedLocation
    }
    private func getCurrentUsername() async -> String {
        do {
            let context = await CoreDataStack.shared.viewContext
            let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \UserEntity.createdAt, ascending: false)]
            fetchRequest.fetchLimit = 1
            let users = try context.fetch(fetchRequest)
            if let currentUser = users.first, let username = currentUser.username {
                return username
            }
        } catch {
            print("Error getting current username: \(error)")
        }
        return "Unknown User"
    }
    private func createSocialFeedEntry(product: GroceryItem, newPrice: Double, location: Location?, username: String) async {
        do {
            let context = await CoreDataStack.shared.viewContext
            // Get the product in the current context
            let productFetchRequest: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
            productFetchRequest.predicate = NSPredicate(format: "id == %@", product.id ?? "")
            productFetchRequest.fetchLimit = 1
            let products = try context.fetch(productFetchRequest)
            guard let productInContext = products.first else {
                print("Error: Could not find product in context for social feed")
                return
            }
            // Get location in the current context
            let locationInContext: Location?
            if let location = location {
                let locationFetchRequest: NSFetchRequest<Location> = Location.fetchRequest()
                locationFetchRequest.predicate = NSPredicate(format: "id == %@", location.id ?? "")
                locationFetchRequest.fetchLimit = 1
                let locations = try context.fetch(locationFetchRequest)
                locationInContext = locations.first
            } else {
                locationInContext = nil
            }
            // Get current user in the same context
            let userFetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
            userFetchRequest.predicate = NSPredicate(format: "username == %@", username)
            userFetchRequest.fetchLimit = 1
            let users = try context.fetch(userFetchRequest)
            guard let currentUser = users.first else {
                print("Error: Could not find user in context for social feed")
                return
            }
            // Create enhanced comment with all required information
            let storeName = locationInContext?.name ?? "Unknown Store"
            let productName = productInContext.productName ?? "Unknown Product"
            let formattedPrice = String(format: "%.2f", newPrice)
            // Format address
            var addressComponents: [String] = []
            if let address = locationInContext?.address, !address.isEmpty {
                addressComponents.append(address)
            }
            if let city = locationInContext?.city, !city.isEmpty {
                addressComponents.append(city)
            }
            if let state = locationInContext?.state, !state.isEmpty {
                addressComponents.append(state)
            }
            if let zipCode = locationInContext?.zipCode, !zipCode.isEmpty {
                addressComponents.append(zipCode)
            }
            let addressString = addressComponents.isEmpty ? "" : " (\(addressComponents.joined(separator: ", ")))"
            let comment = "Price updated: \(productName) is now $\(formattedPrice) at \(storeName)\(addressString)"
            // Create the social experience
            let experience = ShoppingExperience(
                context: context,
                id: UUID().uuidString,
                comment: comment,
                rating: 0,
                type: "price_update",
                user: currentUser,
                groceryItem: productInContext,
                location: locationInContext
            )
            try context.save()
            print("Successfully created social feed entry for price update: \(productName) at \(storeName)")
        } catch {
            print("Error creating social feed entry: \(error)")
        }
    }
}
// Store view
struct StoreView: View {
    let selectedLocation: Location?
    let onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: "mappin.circle")
                    .foregroundColor(.blue)
                Text(selectedLocation?.name ?? "Select Location")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
                Spacer()
                Text(formatAddress(selectedLocation))
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.gray)
                // Add chevron to indicate it's tappable
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, maxHeight: 10, alignment: .center)
            .padding()
            .background(Color.gray.opacity(0.12))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.07), radius: 3, x: 0, y: 2)
            .padding(.horizontal)
        }
        .buttonStyle(PlainButtonStyle())
    }
    private func formatAddress(_ location: Location?) -> String {
        guard let location = location else { return "No location selected" }
        var components: [String] = []
        if let city = location.city, !city.isEmpty {
            components.append(city)
        }
        if let state = location.state, !state.isEmpty {
            components.append(state)
        }
        if let zipCode = location.zipCode, !zipCode.isEmpty {
            components.append(zipCode)
        }
        return components.isEmpty ? "No address" : components.joined(separator: ", ")
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
                // Store info removed since we removed store from GroceryItem
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
    let currentSelectedLocation: Location?
    @State private var locationPrice: GroceryItemPrice?
    @State private var isLoading = true
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            } else if let locationPrice = locationPrice {
                // Show price for selected location
                VStack(spacing: 8) {
                    Text("$\(String(format: "%.2f", locationPrice.price))")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    Text("at \(currentSelectedLocation?.name ?? "Unknown Location")")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    // Last updated info from GroceryItemPrice
                    if let lastUpdated = locationPrice.lastUpdated {
                        VStack(spacing: 2) {
                            Text("Last Updated: \(DateFormatter.localizedString(from: lastUpdated, dateStyle: .short, timeStyle: .short))")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.gray)
                            if let updatedBy = locationPrice.updatedBy {
                                Text("By: \(updatedBy)")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            } else {
                // No price available for selected location
                VStack(spacing: 8) {
                    Text("No price available")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                    Text("at \(currentSelectedLocation?.name ?? "Unknown Location")")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    Text("Tap 'Update Price' to add a price for this location")
                        .font(.system(size: 12))
                        .foregroundColor(.gray.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
            }
        }
        .task {
            await loadPriceForSelectedLocation()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { _ in
            Task {
                await loadPriceForSelectedLocation()
            }
        }
        .onChange(of: currentSelectedLocation) { newLocation in
            Task {
                print("ProductPriceView: Location changed to: \(newLocation?.name ?? "nil")")
                await loadPriceForSelectedLocation(newLocation: newLocation)
            }
        }
    }
    private func loadPriceForSelectedLocation(newLocation: Location? = nil) async {
        isLoading = true
        let locationToSearch = newLocation ?? currentSelectedLocation
        guard let locationToSearch = locationToSearch else {
            await MainActor.run {
                self.locationPrice = nil
                self.isLoading = false
            }
            return
        }
        do {
            let context = await CoreDataStack.shared.viewContext
            let fetchRequest: NSFetchRequest<GroceryItemPrice> = GroceryItemPrice.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "groceryItem == %@ AND location.id == %@", product, locationToSearch.id ?? "")
            // Debug: Let's also check what prices exist for this product
            let allPricesFetchRequest: NSFetchRequest<GroceryItemPrice> = GroceryItemPrice.fetchRequest()
            allPricesFetchRequest.predicate = NSPredicate(format: "groceryItem == %@", product)
            let allPrices = try context.fetch(allPricesFetchRequest)
            print("ProductPriceView: All prices for this product: ")
            for price in allPrices {
                print("  - Location: \(price.location?.name ?? "nil"), ID: \(price.location?.id ?? "nil"), Price: $\(price.price)")
            }
            fetchRequest.fetchLimit = 1
            print("ProductPriceView: Searching for location ID: \(locationToSearch.id ?? "nil")")
            print("ProductPriceView: Searching for location name: \(locationToSearch.name ?? "nil")")
            let prices = try context.fetch(fetchRequest)
            let price = prices.first
            print("ProductPriceView: Found \(prices.count) prices for location \(locationToSearch.name ?? "Unknown")")
            await MainActor.run {
                // Only set locationPrice if we actually found a price
                if let price = price {
                    print("ProductPriceView: Setting price to $\(price.price)")
                    self.locationPrice = price
                } else {
                    print("ProductPriceView: No price found, setting locationPrice to nil")
                    self.locationPrice = nil
                }
                self.isLoading = false
            }
        } catch {
            print("Error loading price for selected location: \(error)")
            await MainActor.run {
                self.locationPrice = nil
                self.isLoading = false
            }
        }
    }
}
// Location Price Row
struct LocationPriceRow: View {
    let price: GroceryItemPrice
    var body: some View {
        HStack(spacing: 12) {
            // Location Icon
            ZStack {
                Circle()
                    .fill(AppColors.accentGreen.opacity(0.1))
                    .frame(width: 32, height: 32)
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.accentGreen)
            }
            // Location and Price Info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(price.location?.name ?? "Unknown Location")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    if let store = price.store, !store.isEmpty {
                        Text("• \(store)")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.gray)
                    }
                }
                // Last updated info from GroceryItemPrice
                if let lastUpdated = price.lastUpdated {
                    VStack(spacing: 2) {
                        Text("Last Updated: \(DateFormatter.localizedString(from: lastUpdated, dateStyle: .short, timeStyle: .short))")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.gray)
                        if let updatedBy = price.updatedBy {
                            Text("By: \(updatedBy)")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            Spacer()
            // Price
            Text("$\(String(format: "%.2f", price.price))")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
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
                // No current price display since prices vary by store
                .padding(.bottom, 18)
                // New price input
                VStack(alignment: .leading, spacing: 8) {
                    Text("New Price: ")
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
// Location Picker Modal
struct LocationPickerModal: View {
    let locations: [Location]
    let product: GroceryItem
    @Binding var selectedLocation: Location?
    let onDismiss: () -> Void
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Header
                VStack(spacing: 8) {
                    Text("Select Location")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    Text("Choose from your favorite locations to see different prices")
                        .multilineTextAlignment(.center)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                .padding(.horizontal, 20)
                // Locations List
                if locations.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "mappin.slash")
                            .font(.system(size: 40))
                            .foregroundColor(.gray.opacity(0.7))
                        Text("No locations found")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                        Text("Add locations in your profile to see them here")
                            .font(.system(size: 14))
                            .foregroundColor(.gray.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 20)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(locations, id: \.id) { location in
                                LocationPickerRowView(
                                    location: location,
                                    product: product,
                                    isSelected: selectedLocation?.id == location.id,
                                    onTap: {
                                        selectedLocation = location
                                        onDismiss()
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                }
                Spacer()
            }
            .padding(.bottom, 20)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
            }
        }
    }
}
// Location Row View for the picker
struct LocationPickerRowView: View {
    let location: Location
    let product: GroceryItem
    let isSelected: Bool
    let onTap: () -> Void
    @State private var locationPrice: GroceryItemPrice?
    @State private var isLoading = true
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Location Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? AppColors.accentGreen.opacity(0.2) : Color.gray.opacity(0.1))
                        .frame(width: 40, height: 40)
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "mappin.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? AppColors.accentGreen : .gray)
                }
                // Location Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(location.name ?? "Unknown Location")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        if location.isDefault {
                            Text("Default")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppColors.accentGreen)
                                .cornerRadius(4)
                        }
                    }
                    Text(formatAddress(location))
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                // Price display
                VStack(alignment: .trailing, spacing: 2) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.6)
                    } else if let locationPrice = locationPrice {
                        Text("$\(String(format: "%.2f", locationPrice.price))")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(isSelected ? AppColors.accentGreen : .primary)
                    } else {
                        Text("No price")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AppColors.accentGreen)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSelected ? AppColors.accentGreen.opacity(0.1) : Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppColors.accentGreen : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .task {
            await loadPriceForLocation()
        }
    }
    private func formatAddress(_ location: Location) -> String {
        var components: [String] = []
        if let city = location.city, !city.isEmpty {
            components.append(city)
        }
        if let state = location.state, !state.isEmpty {
            components.append(state)
        }
        if let zipCode = location.zipCode, !zipCode.isEmpty {
            components.append(zipCode)
        }
        return components.isEmpty ? "No address" : components.joined(separator: ", ")
    }
    private func loadPriceForLocation() async {
        isLoading = true
        do {
            let context = await CoreDataStack.shared.viewContext
            let fetchRequest: NSFetchRequest<GroceryItemPrice> = GroceryItemPrice.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "groceryItem == %@ AND location.id == %@", product, location.id ?? "")
            fetchRequest.fetchLimit = 1
            let prices = try context.fetch(fetchRequest)
            let price = prices.first
            await MainActor.run {
                self.locationPrice = price
                self.isLoading = false
            }
        } catch {
            print("Error loading price for location: \(error)")
            await MainActor.run {
                self.locationPrice = nil
                self.isLoading = false
            }
        }
    }
}
