//
//  AddItemsView.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/5/25.
//
import SwiftUI
import CoreData
struct AddItemsView: View {
    @StateObject private var productViewModel = ProductViewModel(repository: ProductRepository())
    let availableTags: [Tag] // Pass tags as parameter
    @State private var showingCamera = false
    @State private var showingSuccess = false
    @State private var showingError = false
    @State private var isProcessing = false
    @State private var scannedBarcode = ""
    @State private var errorMessage = ""
    @State private var successMessage = ""
    // Barcode confirmation state
    @State private var showingBarcodeConfirmation = false
    @State private var pendingBarcode: String = ""
    @State private var pendingProductName: String = ""
    @State private var pendingCompany: String = ""
    @State private var pendingPrice: String = ""
    @State private var pendingCategory: ProductCategory = .none
    @State private var pendingIsOnSale: Bool = false
    @State private var showCategoryPicker = false
    @State private var pendingLocation: Location? = nil
    @State private var showLocationPicker = false
    @State private var selectedTags: [Tag] = []
    @State private var showingTagPicker = false
    @State private var addToShoppingList = false
    @State private var isExistingProduct = false
    @State private var isScanInProgress = false
    

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()
                // Camera View
                if showingCamera {
                    ZStack {
                        CameraView(
                            onBarcodeScanned: { barcode in
                                handleBarcodeScanned(barcode)
                            },
                            onError: { error in
                                handleError(error)
                            }
                        )
                        .cornerRadius(12)
                        .padding(.horizontal)
                        // Overlay for camera instructions
                        VStack {
                            Spacer()
                            Text("Position barcode within the frame")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(8)
                                .padding(.bottom, 40)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Placeholder when camera is not showing
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.backgroundSecondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .overlay(
                            VStack(spacing: 12) {
                                Image(systemName: "barcode.viewfinder")
                                    .font(.system(size: 60))
                                    .foregroundColor(AppColors.accentGreen)
                                Text("Scan a barcode to add or edit it")
                                    .font(.body)
                                    .foregroundColor(AppColors.textPrimary.opacity(0.7))
                                    .multilineTextAlignment(.center)
                            }
                        )
                        .padding(.top, 40)
                        .padding(.horizontal)
                }
                // Action Buttons
                VStack(spacing: 12) {
                    // Scan Button
                    Button(action: {
                        showingCamera.toggle()
                    }) {
                        HStack {
                            Image(systemName: showingCamera ? "stop.fill" : "camera.fill")
                                .font(.system(size: 18))
                            Text(showingCamera ? "Stop Scanning" : "Start Scanning")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppColors.accentGreen)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                // Processing Indicator
                if isProcessing {
                    VStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Processing barcode...")
                            .font(.caption)
                            .foregroundColor(AppColors.textPrimary.opacity(0.7))
                    }
                    .padding(.horizontal)
                }
                // Success Message
                if showingSuccess {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppColors.accentGreen)
                        Text(successMessage)
                            .font(.caption)
                            .foregroundColor(AppColors.accentGreen)
                    }
                    .padding(.horizontal)
                }
                // Scanned Result
                if !scannedBarcode.isEmpty && !isProcessing {
                    VStack(spacing: 8) {
                        Text("Scanned Barcode: ")
                            .font(.caption)
                            .foregroundColor(AppColors.textPrimary.opacity(0.7))
                        Text(scannedBarcode)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(AppColors.backgroundSecondary)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }
                Spacer()
            }
            .navigationTitle("Add Items")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                // Tags are now passed as parameter, no need to fetch
            }
                                        .fullScreenCover(isPresented: $showingBarcodeConfirmation) {
                BarcodeConfirmationView(
                    barcode: $pendingBarcode,
                    productName: $pendingProductName,
                    company: $pendingCompany,
                    price: $pendingPrice,
                    selectedCategory: $pendingCategory,
                    isOnSale: $pendingIsOnSale,
                    selectedLocation: $pendingLocation,
                    showLocationPicker: $showLocationPicker,
                    showCategoryPicker: $showCategoryPicker,
                    availableTags: availableTags,
                    selectedTags: $selectedTags,
                    showingTagPicker: $showingTagPicker,
                    addToShoppingList: $addToShoppingList,
                    isExistingProduct: $isExistingProduct,
                    isScanInProgress: isScanInProgress,
                    onConfirm: { barcode, productName, company, price, category, isOnSale, location, tags, addToShoppingList in
                        showingBarcodeConfirmation = false
                        isScanInProgress = false
                        Task {
                            await handleBarcodeProcessing(barcode: barcode, productName: productName, company: company, price: price, category: category, isOnSale: isOnSale, location: location, tags: tags, addToShoppingList: addToShoppingList)
                        }
                    },
                    onCancel: {
                        showingBarcodeConfirmation = false
                        resetPendingData()
                        isScanInProgress = false
                    }
                )
                .id("BarcodeConfirmation-\(isExistingProduct)")
                .sheet(isPresented: $showCategoryPicker) {
                    CategoryPickerView(selectedCategory: $pendingCategory)
                }
                .sheet(isPresented: $showingTagPicker) {
                    TagPickerView(
                        allTags: availableTags,
                        selectedTags: $selectedTags,
                        onDone: { showingTagPicker = false }
                    )
                }
                .sheet(isPresented: $showLocationPicker) {
                    LocationPickerView(selectedLocation: $pendingLocation)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {
                    showingError = false
                    errorMessage = ""
                }
            } message: {
                Text(errorMessage.isEmpty ? "An unknown error occurred" : errorMessage)
            }
        }
    }
    private func handleBarcodeScanned(_ barcode: String) {
        // Set scan in progress to disable button
        isScanInProgress = true
        
        // Reset all pending data first to ensure clean state
        resetPendingData()
        pendingBarcode = barcode
        showingCamera = false
        
        // Check if product already exists and fetch its data
        Task {
            do {
                let existingProducts = try await productViewModel.searchProductsByBarcode(barcode)
                await MainActor.run {
                    if let existingProduct = existingProducts.first {
                        // Auto-fill with existing data
                        isExistingProduct = true
                        pendingProductName = existingProduct.productName ?? ""
                        pendingCompany = existingProduct.brand ?? ""
                        pendingCategory = ProductCategory(rawValue: existingProduct.category ?? "") ?? .none
                        pendingIsOnSale = existingProduct.isOnSale
                        
                        // Get the most recent price and location
                        if let prices = existingProduct.prices as? Set<GroceryItemPrice>,
                           let mostRecentPrice = prices.max(by: { ($0.lastUpdated ?? Date.distantPast) < ($1.lastUpdated ?? Date.distantPast) }) {
                            pendingPrice = String(format: "%.2f", mostRecentPrice.price)
                            pendingLocation = mostRecentPrice.location
                        }
                        
                        // Load existing tags
                        if let existingTags = existingProduct.tags as? Set<Tag> {
                            selectedTags = Array(existingTags)
                        } else {
                            selectedTags = []
                        }
                        
                    } else {
                        isExistingProduct = false
                        // Keep fields empty for new product
                    }
                    // Reset scan in progress after data is loaded
                    isScanInProgress = false
                    // Small delay to ensure state is set before showing sheet
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showingBarcodeConfirmation = true
                    }
                }
            } catch {
                await MainActor.run {
                    isExistingProduct = false
                    // Reset scan in progress after error
                    isScanInProgress = false
                    // Small delay to ensure state is set before showing sheet
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showingBarcodeConfirmation = true
                    }
                }
            }
        }
    }
    private func handleBarcodeProcessing(barcode: String, productName: String, company: String, price: String, category: ProductCategory, isOnSale: Bool, location: Location?, tags: [Tag], addToShoppingList: Bool) async {
        scannedBarcode = barcode
        isProcessing = true
        Task {
            // Convert price string to Double
            let priceValue = Double(price.replacingOccurrences(of: "$", with: "")) ?? 0.0
            // Get store name from location or use a default
            let storeName = location?.name ?? "Unknown Store"
            // Check if product already exists before processing
            let wasExistingProduct = await productViewModel.isDuplicateBarcode(barcode)
            // Use ViewModel to create or update product
            let newProduct = await createOrUpdateProductByBarcode(
                barcode: barcode,
                productName: productName.isEmpty ? "Unknown Product" : productName,
                brand: company.isEmpty ? nil : company,
                category: category == .none ? nil : category.rawValue,
                price: priceValue,
                store: storeName,
                isOnSale: isOnSale
            )
            // Associate tags with the new product
            if let newProduct = newProduct {
                // For existing products, replace tags instead of adding to them
                if wasExistingProduct {
                    await productViewModel.replaceTagsForProduct(newProduct, tags: tags)
                } else {
                    await productViewModel.addTagsToProduct(newProduct, tags: tags)
                }
                
                // Add to shopping list if requested
                if addToShoppingList {
                    await productViewModel.addExistingProductToShoppingList(newProduct)
                }
                // Refresh price comparison after adding product
                await productViewModel.loadLocalPriceComparison()
                // Create social feed entry for new product with price
                if priceValue > 0 {
                    await createSocialFeedEntryForProduct(product: newProduct, price: priceValue, location: location, isNewProduct: !wasExistingProduct)
                }
                
                // Note: Reputation is updated in CoreDataContainer.createProduct() and updateProductWithPrice()
                // No need to update here to avoid double incrementing
            }
            await MainActor.run {
                isProcessing = false
                if let error = productViewModel.errorMessage {
                    errorMessage = error
                    showingError = true
                } else {
                    // Success - show success message and clear the scanned barcode
                    let shoppingListText = addToShoppingList ? " and added to shopping list" : ""
                    successMessage = wasExistingProduct ? "Product updated successfully!\(shoppingListText)" : "Product added successfully!\(shoppingListText)"
                    showingSuccess = true
                    scannedBarcode = ""
                    // Hide success message after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        showingSuccess = false
                    }
                }
            }
        }
    }
    
    private func createOrUpdateProductByBarcode(barcode: String, productName: String, brand: String?, category: String?, price: Double, store: String, isOnSale: Bool) async -> GroceryItem? {
        // First check if product already exists with this barcode
        if await productViewModel.isDuplicateBarcode(barcode) {
            // Product exists, update it
            if let updatedProduct = await productViewModel.updateProductByBarcode(
                barcode: barcode,
                productName: productName,
                brand: brand,
                category: category,
                price: price,
                store: store,
                isOnSale: isOnSale
            ) {
                return updatedProduct
            }
        } else {
            // Product doesn't exist, create new product
            return await productViewModel.createProductByBarcode(
                barcode: barcode,
                productName: productName,
                brand: brand,
                category: category,
                price: price,
                store: store,
                isOnSale: isOnSale
            )
        }
        return nil
    }
    

    private func createSocialFeedEntryForProduct(product: GroceryItem, price: Double, location: Location?, isNewProduct: Bool) async {
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
            let currentUsername = UserDefaults.standard.string(forKey: "currentUsername") ?? "Unknown User"
            let userFetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
            userFetchRequest.predicate = NSPredicate(format: "username == %@", currentUsername)
            userFetchRequest.fetchLimit = 1
            let users = try context.fetch(userFetchRequest)
            guard let currentUser = users.first else {
                print("Error: Could not find user in context for social feed")
                return
            }
            // Create enhanced comment with all required information
            let storeName = locationInContext?.name ?? "Unknown Store"
            let productName = productInContext.productName ?? "Unknown Product"
            let formattedPrice = String(format: "%.2f", price)
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
            let comment: String
            if isNewProduct {
                comment = "New product added: \(productName) is $\(formattedPrice) at \(storeName)\(addressString)"
            } else {
                comment = "Price updated for \(productName) at \(storeName)\(addressString): $\(formattedPrice)"
            }
            // Create the social experience
            let experience = ShoppingExperience(
                context: context,
                id: UUID().uuidString,
                comment: comment,
                rating: 0,
                type: isNewProduct ? "new_product" : "price_update",
                user: currentUser,
                groceryItem: productInContext,
                location: locationInContext
            )
            try context.save()
            print("Successfully created social feed entry for product: \(productName) at \(storeName)")
        } catch {
            print("Error creating social feed entry for product: \(error)")
        }
    }
    private func resetPendingData() {
        pendingBarcode = ""
        pendingProductName = ""
        pendingCompany = ""
        pendingPrice = ""
        pendingCategory = .none
        pendingIsOnSale = false
        pendingLocation = nil
        selectedTags = []
        addToShoppingList = false
        isExistingProduct = false
    }
    private func handleError(_ error: String) {
        errorMessage = error
        showingError = true
        showingCamera = false
    }
}
// MARK: - Tag Picker View
struct TagPickerView: View {
    let allTags: [Tag]
    @Binding var selectedTags: [Tag]
    let onDone: () -> Void
    @State private var searchText = ""
    var filteredTags: [Tag] {
        if searchText.isEmpty {
            return allTags
        } else {
            return allTags.filter { tag in
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
                            if selectedTags.contains(where: { $0.id == tag.id }) {
                                selectedTags.removeAll { $0.id == tag.id }
                            } else {
                                selectedTags.append(tag)
                            }
                        }) {
                            HStack {
                                Text(tag.displayName)
                                Spacer()
                                if selectedTags.contains(where: { $0.id == tag.id }) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Tags")
            .navigationBarItems(trailing: Button("Done") { onDone() })
        }
    }
}
// MARK: - Tag Chip View
struct TagChipView: View {
    let tag: Tag
    let onRemove: () -> Void
    var body: some View {
        HStack {
            Text(tag.displayName)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(hex: tag.displayColor))
                .foregroundColor(.white)
                .cornerRadius(16)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white)
            }
        }
        .padding(4)
    }
}
// MARK: - Barcode Confirmation View
struct BarcodeConfirmationView: View {
    @Binding var barcode: String
    @Binding var productName: String
    @Binding var company: String
    @Binding var price: String
    @Binding var selectedCategory: ProductCategory
    @Binding var isOnSale: Bool
    @Binding var selectedLocation: Location?
    @Binding var showLocationPicker: Bool
    @Binding var showCategoryPicker: Bool
    let availableTags: [Tag]
    @Binding var selectedTags: [Tag]
    @Binding var showingTagPicker: Bool
    @Binding var addToShoppingList: Bool
    @Binding var isExistingProduct: Bool
    let isScanInProgress: Bool
    let onConfirm: (String, String, String, String, ProductCategory, Bool, Location?, [Tag], Bool) -> Void
    let onCancel: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    // Form validation
    private var isFormValid: Bool {
        !barcode.isEmpty && 
        !productName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !company.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !price.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        selectedLocation != nil &&
        selectedCategory != .none
    }
    
    private var validationMessages: [String] {
        var messages: [String] = []
        
        if barcode.isEmpty {
            messages.append("Barcode is required")
        }
        if productName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            messages.append("Product name is required")
        }
        if company.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            messages.append("Company/Brand is required")
        }
        if price.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            messages.append("Price is required")
        }
        if selectedLocation == nil {
            messages.append("Location is required")
        }
        if selectedCategory == .none {
            messages.append("Category is required")
        }
        
        return messages
    }
    
    private func shouldShowActionButton() -> Bool {
        // Don't show button during scan processing
        if isScanInProgress {
            return false
        }
        
        // Always show button when form is valid
        return true
    }
    
    private func shouldShowUpdateButton() -> Bool {
        return isExistingProduct
    }
    
    private var buttonText: String {
        return isExistingProduct ? "Update" : "Add"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {

                    // Form Fields
                    VStack(spacing: 16) {
                        // Barcode Field
                        VStack(spacing: 8) {
                            Text("Barcode Number")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                            Text(barcode)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(AppColors.textPrimary.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 16)
                        // Product Name Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Product Name")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                            TextField("Enter product name...", text: $productName)
                                .font(.body)
                                .padding()
                                .background(AppColors.backgroundSecondary)
                                .cornerRadius(8)
                        }
                        // Company Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Company/Brand")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                            TextField("Enter company or brand...", text: $company)
                                .font(.body)
                                .padding()
                                .background(AppColors.backgroundSecondary)
                                .cornerRadius(8)
                        }
                        // Category Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                            Button(action: {
                                showCategoryPicker = true
                            }) {
                                HStack {
                                    Text(selectedCategory.rawValue)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(AppColors.backgroundSecondary)
                                .cornerRadius(8)
                            }
                        }
                        // Price Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Price")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                            TextField("Enter price...", text: $price)
                                .font(.body)
                                .padding()
                                .background(AppColors.backgroundSecondary)
                                .cornerRadius(8)
                                .keyboardType(.decimalPad)
                        }
                        // Location Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Location")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                            Button(action: {
                                showLocationPicker = true
                            }) {
                                HStack {
                                    Text(selectedLocation?.name ?? "Select location...")
                                        .font(.body)
                                        .foregroundColor(selectedLocation == nil ? .gray : .primary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(AppColors.backgroundSecondary)
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                    // Tag Selection Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags")
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.bottom, 4)
                        Button(action: {
                            showingTagPicker = true
                        }) {
                            HStack {
                                Text(selectedTags.isEmpty ? "Select tags..." : "\(selectedTags.count) tags selected")
                                    .font(.body)
                                    .foregroundColor(selectedTags.isEmpty ? .gray : .primary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(AppColors.backgroundSecondary)
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                    // Selected Tags Display
                    if !selectedTags.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Selected Tags")
                                    .font(.headline)
                                    .foregroundColor(AppColors.textPrimary)
                                Spacer()
                                Button("Edit") {
                                    showingTagPicker = true
                                }
                                .font(.subheadline)
                                .foregroundColor(AppColors.accentGreen)
                            }
                            .padding(.bottom, 4)
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                ForEach(selectedTags, id: \.id) { tag in
                                    TagChipView(tag: tag) {
                                        selectedTags.removeAll { $0.id == tag.id }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    // On Sale Toggle
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("On Sale")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                            Toggle("", isOn: $isOnSale)
                                .toggleStyle(SwitchToggleStyle(tint: AppColors.accentOrange))
                        }
                        .padding(.horizontal)
                    }
                    // Shopping List Toggle
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Add to Shopping List")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                            Toggle("", isOn: $addToShoppingList)
                                .toggleStyle(SwitchToggleStyle(tint: AppColors.accentGreen))
                        }
                        .padding(.horizontal)
                        if addToShoppingList {
                            Text("This item will be added to your shopping list")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                        }
                    }
                    
                    // Action Buttons - Center Bottom
                    VStack(spacing: 16) {
                        // Always show for testing
                        Button(action: {
                            onConfirm(barcode, productName, company, price, selectedCategory, isOnSale, selectedLocation, selectedTags, addToShoppingList)
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: isExistingProduct ? "arrow.clockwise" : "plus")
                                    .font(.system(size: 18, weight: .semibold))
                                Text(isExistingProduct ? "Update Item" : "Add Item")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppColors.accentGreen)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)


                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }





        }
    }

}
// MARK: - Manual Barcode Entry View
struct ManualBarcodeEntryView: View {
    @Binding var barcode: String
    let onBarcodeEntered: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 40))
                        .foregroundColor(AppColors.accentGreen)
                    Text("Enter Barcode")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Type the barcode number manually")
                        .font(.body)
                        .foregroundColor(AppColors.textPrimary.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Barcode Number")
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    TextField("Enter barcode...", text: $barcode)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .background(AppColors.backgroundSecondary)
                        .cornerRadius(8)
                        .keyboardType(.numberPad)
                }
                .padding(.horizontal)
                Spacer()
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        if !barcode.isEmpty {
                            onBarcodeEntered(barcode)
                        }
                    }) {
                        Text("Add Item")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(barcode.isEmpty ? Color.gray : AppColors.accentGreen)
                            .cornerRadius(12)
                    }
                    .disabled(barcode.isEmpty)
                    .padding(.horizontal)
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Cancel")
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.accentGreen)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppColors.accentGreen.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Manual Entry")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
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
#Preview {
    AddItemsView(availableTags: []) // Pass an empty array for preview
}
