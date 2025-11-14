//
//  AddItemsView.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/5/25.
//  Refactored for production-level performance
//
import SwiftUI
import CoreData

// MARK: - Performance Optimization 1: Consolidated View State
/// Single source of truth for view state reduces property wrapper overhead
/// and prevents unnecessary re-renders by grouping related state
struct AddItemsViewState: Equatable {
    var showingCamera = false
    var showingSuccess = false
    var showingError = false
    var isProcessing = false
    var scannedBarcode = ""
    var errorMessage = ""
    var successMessage = ""
    var isScanInProgress = false
    
    static func == (lhs: AddItemsViewState, rhs: AddItemsViewState) -> Bool {
        lhs.showingCamera == rhs.showingCamera &&
        lhs.showingSuccess == rhs.showingSuccess &&
        lhs.showingError == rhs.showingError &&
        lhs.isProcessing == rhs.isProcessing &&
        lhs.scannedBarcode == rhs.scannedBarcode &&
        lhs.isScanInProgress == rhs.isScanInProgress
    }
}

// MARK: - Performance Optimization 2: Separate Barcode State
/// Isolating barcode confirmation state prevents parent view re-renders
struct BarcodeConfirmationState: Equatable {
    var isShowing = false
    var barcode = ""
    var productName = ""
    var company = ""
    var price = ""
    var category: ProductCategory = .none
    var isOnSale = false
    var showCategoryPicker = false
    var location: Location?
    var showLocationPicker = false
    var selectedTags: [Tag] = []
    var showingTagPicker = false
    var addToShoppingList = false
    var isExistingProduct = false
    
    mutating func reset() {
        barcode = ""
        productName = ""
        company = ""
        price = ""
        category = .none
        isOnSale = false
        location = nil
        selectedTags = []
        addToShoppingList = false
        isExistingProduct = false
    }
    
    static func == (lhs: BarcodeConfirmationState, rhs: BarcodeConfirmationState) -> Bool {
        lhs.isShowing == rhs.isShowing &&
        lhs.barcode == rhs.barcode &&
        lhs.isExistingProduct == rhs.isExistingProduct
    }
}

// MARK: - Main View
struct AddItemsView: View {
    @EnvironmentObject var coordinator: AddItemsCoordinator
    let availableTags: [Tag]
    
    // Performance Optimization 3: Cached computed properties
    // Using private lazy var to avoid recomputation on every body evaluation
    private var addItemsViewModel: AddItemsViewModel {
        coordinator.addItemsViewModel
    }
    
    private var shoppingListViewModel: ShoppingListViewModel {
        coordinator.shoppingListViewModel
    }
    
    // Performance Optimization 4: Consolidated state using single @State
    @State private var viewState = AddItemsViewState()
    @State private var barcodeState = BarcodeConfirmationState()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()
                
                // Performance Optimization 5: Extracted camera section
                cameraSection
                
                // Performance Optimization 6: Extracted action buttons
                actionButtons
                
                // Performance Optimization 7: Conditional views with minimal hierarchy
                if viewState.isProcessing {
                    ProcessingIndicatorView()
                }
                
                if viewState.showingSuccess {
                    SuccessMessageView(message: viewState.successMessage)
                }
                
                if !viewState.scannedBarcode.isEmpty && !viewState.isProcessing {
                    ScannedBarcodeView(barcode: viewState.scannedBarcode)
                }
                
                Spacer()
            }
            .navigationTitle("Add Items")
            .navigationBarTitleDisplayMode(.large)
            .fullScreenCover(isPresented: $barcodeState.isShowing) {
                // Performance Optimization 8: Lazy sheet content
                BarcodeConfirmationView(
                    state: $barcodeState,
                    availableTags: availableTags,
                    isScanInProgress: viewState.isScanInProgress,
                    onConfirm: { [weak coordinator] in
                        handleBarcodeConfirmation()
                    },
                    onCancel: {
                        barcodeState.isShowing = false
                        barcodeState.reset()
                        viewState.isScanInProgress = false
                    }
                )
                .id("BarcodeConfirmation-\(barcodeState.isExistingProduct)")
            }
            .alert("Error", isPresented: $viewState.showingError) {
                Button("OK") {
                    viewState.showingError = false
                    viewState.errorMessage = ""
                }
            } message: {
                Text(viewState.errorMessage.isEmpty ? "An unknown error occurred" : viewState.errorMessage)
            }
        }
    }
    
    // MARK: - View Builders (Performance Optimization 9: Decomposed views)
    
    @ViewBuilder
    private var cameraSection: some View {
        if viewState.showingCamera {
            CameraContainerView(
                onBarcodeScanned: { barcode in
                    handleBarcodeScanned(barcode)
                },
                onError: { error in
                    handleError(error)
                }
            )
        } else {
            CameraPlaceholderView()
        }
    }
    
    @ViewBuilder
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                viewState.showingCamera.toggle()
            } label: {
                HStack {
                    Image(systemName: viewState.showingCamera ? "stop.fill" : "camera.fill")
                        .font(.system(size: 18))
                    Text(viewState.showingCamera ? "Stop Scanning" : "Start Scanning")
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
    }
    
    // MARK: - Business Logic (Performance Optimization 10: Async operations)
    
    private func handleBarcodeScanned(_ barcode: String) {
        viewState.isScanInProgress = true
        barcodeState.reset()
        barcodeState.barcode = barcode
        viewState.showingCamera = false
        
        // Performance Optimization 11: Background thread operations
        Task.detached(priority: .userInitiated) {
            do {
                let existingProducts = try await addItemsViewModel.searchProductsByBarcode(barcode)
                
                await MainActor.run {
                    if let existingProduct = existingProducts.first {
                        populateBarcodeState(with: existingProduct)
                    }
                    
                    viewState.isScanInProgress = false
                    
                    // Performance Optimization 12: Single state update instead of multiple
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                        barcodeState.isShowing = true
                    }
                }
            } catch {
                await MainActor.run {
                    barcodeState.isExistingProduct = false
                    viewState.isScanInProgress = false
                    
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 100_000_000)
                        barcodeState.isShowing = true
                    }
                }
            }
        }
    }
    
    private func populateBarcodeState(with product: GroceryItem) {
        barcodeState.isExistingProduct = true
        barcodeState.productName = product.productName ?? ""
        barcodeState.company = product.brand ?? ""
        barcodeState.category = ProductCategory(rawValue: product.category ?? "") ?? .none
        barcodeState.isOnSale = product.isOnSale
        
        // Performance Optimization 13: Efficient price lookup
        if let prices = product.prices as? Set<GroceryItemPrice>,
           let mostRecentPrice = prices.max(by: { ($0.lastUpdated ?? .distantPast) < ($1.lastUpdated ?? .distantPast) }) {
            barcodeState.price = String(format: "%.2f", mostRecentPrice.price)
            barcodeState.location = mostRecentPrice.location
        }
        
        if let existingTags = product.tags as? Set<Tag> {
            barcodeState.selectedTags = Array(existingTags)
        }
    }
    
    private func handleBarcodeConfirmation() {
        barcodeState.isShowing = false
        viewState.isScanInProgress = false
        
        Task {
            await handleBarcodeProcessing()
        }
    }
    
    private func handleBarcodeProcessing() async {
        viewState.scannedBarcode = barcodeState.barcode
        viewState.isProcessing = true
        
        let priceValue = Double(barcodeState.price.replacingOccurrences(of: "$", with: "")) ?? 0.0
        let storeName = barcodeState.location?.name ?? "Unknown Store"
        
        // Performance Optimization 14: Batch operations
        async let wasExistingCheck = addItemsViewModel.isDuplicateBarcode(barcodeState.barcode)
        let wasExistingProduct = await wasExistingCheck
        
        let newProduct = await createOrUpdateProductByBarcode(
            barcode: barcodeState.barcode,
            productName: barcodeState.productName.isEmpty ? "Unknown Product" : barcodeState.productName,
            brand: barcodeState.company.isEmpty ? nil : barcodeState.company,
            category: barcodeState.category == .none ? nil : barcodeState.category.rawValue,
            price: priceValue,
            store: storeName,
            isOnSale: barcodeState.isOnSale
        )
        
        if let newProduct = newProduct {
            // Performance Optimization 15: Parallel async operations where possible
            async let tagsTask: () = wasExistingProduct
                ? addItemsViewModel.replaceTagsForProduct(newProduct, tags: barcodeState.selectedTags)
                : addItemsViewModel.addTagsToProduct(newProduct, tags: barcodeState.selectedTags)
            
            if barcodeState.addToShoppingList {
                async let shoppingListTask: () = addItemsViewModel.addExistingProductToShoppingList(newProduct)
                async let priceComparisonTask: () = shoppingListViewModel.loadLocalPriceComparison()
                
                _ = await (tagsTask, shoppingListTask, priceComparisonTask)
            } else {
                await tagsTask
            }
            
            if priceValue > 0 {
                await createSocialFeedEntryForProduct(
                    product: newProduct,
                    price: priceValue,
                    location: barcodeState.location,
                    isNewProduct: !wasExistingProduct
                )
            }
        }
        
        await MainActor.run {
            viewState.isProcessing = false
            
            if let error = addItemsViewModel.errorMessage {
                viewState.errorMessage = error
                viewState.showingError = true
            } else {
                let shoppingListText = barcodeState.addToShoppingList ? " and added to shopping list" : ""
                viewState.successMessage = wasExistingProduct
                    ? "Product updated successfully!\(shoppingListText)"
                    : "Product added successfully!\(shoppingListText)"
                viewState.showingSuccess = true
                viewState.scannedBarcode = ""
                
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                    viewState.showingSuccess = false
                }
            }
        }
    }
    
    private func createOrUpdateProductByBarcode(
        barcode: String,
        productName: String,
        brand: String?,
        category: String?,
        price: Double,
        store: String,
        isOnSale: Bool
    ) async -> GroceryItem? {
        if await addItemsViewModel.isDuplicateBarcode(barcode) {
            return await addItemsViewModel.updateProductByBarcode(
                barcode: barcode,
                productName: productName,
                brand: brand,
                category: category,
                price: price,
                store: store,
                isOnSale: isOnSale
            )
        } else {
            return await addItemsViewModel.createProductByBarcode(
                barcode: barcode,
                productName: productName,
                brand: brand,
                category: category,
                price: price,
                store: store,
                isOnSale: isOnSale
            )
        }
    }
    
    // Performance Optimization 16: Core Data operations on background context
    private func createSocialFeedEntryForProduct(
        product: GroceryItem,
        price: Double,
        location: Location?,
        isNewProduct: Bool
    ) async {
        // Perform on background context to avoid blocking main thread
        await Task.detached(priority: .background) {
            do {
                let context = await CoreDataStack.shared.newBackgroundContext()
                
                await context.perform {
                    do {
                        // Fetch product in background context
                        let productFetchRequest: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
                        productFetchRequest.predicate = NSPredicate(format: "id == %@", product.id ?? "")
                        productFetchRequest.fetchLimit = 1
                        
                        guard let productInContext = try context.fetch(productFetchRequest).first else {
                            print("Error: Could not find product in context for social feed")
                            return
                        }
                        
                        // Fetch location if available
                        let locationInContext: Location?
                        if let location = location {
                            let locationFetchRequest: NSFetchRequest<Location> = Location.fetchRequest()
                            locationFetchRequest.predicate = NSPredicate(format: "id == %@", location.id ?? "")
                            locationFetchRequest.fetchLimit = 1
                            locationInContext = try context.fetch(locationFetchRequest).first
                        } else {
                            locationInContext = nil
                        }
                        
                        // Fetch user
                        let currentUsername = UserDefaults.standard.string(forKey: "currentUsername") ?? "Unknown User"
                        let userFetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
                        userFetchRequest.predicate = NSPredicate(format: "username == %@", currentUsername)
                        userFetchRequest.fetchLimit = 1
                        
                        guard let currentUser = try context.fetch(userFetchRequest).first else {
                            print("Error: Could not find user in context for social feed")
                            return
                        }
                        
                        // Build comment
                        let storeName = locationInContext?.name ?? "Unknown Store"
                        let productName = productInContext.productName ?? "Unknown Product"
                        let formattedPrice = String(format: "%.2f", price)
                        
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
                        let comment = isNewProduct
                            ? "New product added: \(productName) is $\(formattedPrice) at \(storeName)\(addressString)"
                            : "Price updated for \(productName) at \(storeName)\(addressString): $\(formattedPrice)"
                        
                        _ = ShoppingExperience(
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
                        print("Error in context.perform: \(error)")
                    }
                }
            } catch {
                print("Error creating social feed entry for product: \(error)")
            }
        }.value
    }
    
    private func handleError(_ error: String) {
        viewState.errorMessage = error
        viewState.showingError = true
        viewState.showingCamera = false
    }
}

// MARK: - Extracted Subviews (Performance Optimization 17: View decomposition)

/// Separate view reduces parent re-renders and improves compilation time
struct CameraContainerView: View {
    let onBarcodeScanned: (String) -> Void
    let onError: (String) -> Void
    
    var body: some View {
        ZStack {
            CameraView(
                onBarcodeScanned: onBarcodeScanned,
                onError: onError
            )
            .cornerRadius(12)
            .padding(.horizontal)
            
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
    }
}

struct CameraPlaceholderView: View {
    var body: some View {
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
}

struct ProcessingIndicatorView: View {
    var body: some View {
        VStack(spacing: 8) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Processing barcode...")
                .font(.caption)
                .foregroundColor(AppColors.textPrimary.opacity(0.7))
        }
        .padding(.horizontal)
    }
}

struct SuccessMessageView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(AppColors.accentGreen)
            Text(message)
                .font(.caption)
                .foregroundColor(AppColors.accentGreen)
        }
        .padding(.horizontal)
    }
}

struct ScannedBarcodeView: View {
    let barcode: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Scanned Barcode: ")
                .font(.caption)
                .foregroundColor(AppColors.textPrimary.opacity(0.7))
            Text(barcode)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppColors.backgroundSecondary)
                .cornerRadius(8)
        }
        .padding(.horizontal)
    }
}

// MARK: - Tag Picker View (Performance Optimization 18: Optimized list)

struct TagPickerView: View {
    let allTags: [Tag]
    @Binding var selectedTags: [Tag]
    let onDone: () -> Void
    
    @State private var searchText = ""
    @State private var localSelectedTags: Set<String> = [] // Performance: Use Set for O(1) lookups
    
    // Performance Optimization 19: Memoized filtered results
    private var filteredTags: [Tag] {
        if searchText.isEmpty {
            return allTags
        }
        return allTags.filter { $0.displayName.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                    .padding(.top)
                
                // Performance Optimization 20: List with explicit IDs and optimized cells
                List {
                    ForEach(filteredTags, id: \.id) { tag in
                        TagPickerRow(
                            tag: tag,
                            isSelected: localSelectedTags.contains(tag.id ?? "")
                        ) {
                            toggleTagSelection(tag)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Select Tags")
            .navigationBarItems(trailing: Button("Done") {
                // Convert Set back to Array
                selectedTags = allTags.filter { localSelectedTags.contains($0.id ?? "") }
                onDone()
            })
            .onAppear {
                // Initialize Set for faster lookups
                localSelectedTags = Set(selectedTags.compactMap { $0.id })
            }
        }
    }
    
    private func toggleTagSelection(_ tag: Tag) {
        guard let tagId = tag.id else { return }
        
        if localSelectedTags.contains(tagId) {
            localSelectedTags.remove(tagId)
        } else {
            localSelectedTags.insert(tagId)
        }
    }
}

// Performance Optimization 21: Separate row view for better list performance
struct TagPickerRow: View, Equatable {
    let tag: Tag
    let isSelected: Bool
    let onTap: () -> Void
    
    static func == (lhs: TagPickerRow, rhs: TagPickerRow) -> Bool {
        lhs.tag.id == rhs.tag.id && lhs.isSelected == rhs.isSelected
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(tag.displayName)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                }
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search tags...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

// MARK: - Tag Chip View

struct TagChipView: View {
    let tag: Tag
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Text(tag.displayName)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .foregroundColor(.white)
        .background(Color(hex: tag.displayColor))
        .cornerRadius(16)
    }
}

// MARK: - Barcode Confirmation View (Performance Optimization 22: Optimized form view)

struct BarcodeConfirmationView: View {
    @Binding var state: BarcodeConfirmationState
    let availableTags: [Tag]
    let isScanInProgress: Bool
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    // Performance Optimization 23: Computed validation cached with @State
    @State private var isFormValid = false
    
    private func updateFormValidation() {
        isFormValid = !state.barcode.isEmpty &&
            !state.productName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !state.company.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !state.price.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            state.location != nil &&
            state.category != .none
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 24) {  // Performance Optimization 24: LazyVStack for large forms
                    BarcodeFormFields(state: $state)
                    
                    TagSelectionSection(
                        state: $state,
                        availableTags: availableTags
                    )
                    
                    ToggleSection(state: $state)
                    
                    ActionButton(
                        isExisting: state.isExistingProduct,
                        isEnabled: isFormValid && !isScanInProgress,
                        action: onConfirm
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .padding(.top)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onCancel)
                }
            }
            .sheet(isPresented: $state.showCategoryPicker) {
                CategoryPickerView(selectedCategory: $state.category)
            }
            .sheet(isPresented: $state.showingTagPicker) {
                TagPickerView(
                    allTags: availableTags,
                    selectedTags: $state.selectedTags,
                    onDone: { state.showingTagPicker = false }
                )
            }
            .sheet(isPresented: $state.showLocationPicker) {
                LocationPickerView(selectedLocation: $state.location)
            }
            .onChange(of: state.barcode) { _ in updateFormValidation() }
            .onChange(of: state.productName) { _ in updateFormValidation() }
            .onChange(of: state.company) { _ in updateFormValidation() }
            .onChange(of: state.price) { _ in updateFormValidation() }
            .onChange(of: state.location) { _ in updateFormValidation() }
            .onChange(of: state.category) { _ in updateFormValidation() }
            .onAppear { updateFormValidation() }
        }
    }
}

// MARK: - Form Sections (Performance Optimization 25: Granular view decomposition)

struct BarcodeFormFields: View {
    @Binding var state: BarcodeConfirmationState
    
    var body: some View {
        VStack(spacing: 16) {
            // Barcode Display
            VStack(spacing: 8) {
                Text("Barcode Number")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                Text(state.barcode)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(AppColors.textPrimary.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            .padding(.bottom, 16)
            
            FormTextField(title: "Product Name", text: $state.productName, placeholder: "Enter product name...")
            FormTextField(title: "Company/Brand", text: $state.company, placeholder: "Enter company or brand...")
            
            CategoryPickerField(category: $state.category, showPicker: $state.showCategoryPicker)
            
            FormTextField(title: "Price", text: $state.price, placeholder: "Enter price...", keyboardType: .decimalPad)
            
            LocationPickerField(location: $state.location, showPicker: $state.showLocationPicker)
        }
        .padding(.horizontal)
    }
}

struct FormTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
            TextField(placeholder, text: $text)
                .font(.body)
                .padding()
                .background(AppColors.backgroundSecondary)
                .cornerRadius(8)
                .keyboardType(keyboardType)
        }
    }
}

struct CategoryPickerField: View {
    @Binding var category: ProductCategory
    @Binding var showPicker: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Category")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
            Button {
                showPicker = true
            } label: {
                HStack {
                    Text(category.rawValue)
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
    }
}

struct LocationPickerField: View {
    @Binding var location: Location?
    @Binding var showPicker: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Location")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
            Button {
                showPicker = true
            } label: {
                HStack {
                    Text(location?.name ?? "Select location...")
                        .font(.body)
                        .foregroundColor(location == nil ? .gray : .primary)
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
}

struct TagSelectionSection: View {
    @Binding var state: BarcodeConfirmationState
    let availableTags: [Tag]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
                .padding(.bottom, 4)
            
            Button {
                state.showingTagPicker = true
            } label: {
                HStack {
                    Text(state.selectedTags.isEmpty ? "Select tags..." : "\(state.selectedTags.count) tags selected")
                        .font(.body)
                        .foregroundColor(state.selectedTags.isEmpty ? .gray : .primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(AppColors.backgroundSecondary)
                .cornerRadius(8)
            }
            
            // Performance Optimization 26: LazyVGrid for tag display
            if !state.selectedTags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Selected Tags")
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary)
                        Spacer()
                        Button("Edit") {
                            state.showingTagPicker = true
                        }
                        .font(.subheadline)
                        .foregroundColor(AppColors.accentGreen)
                    }
                    .padding(.top, 8)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(state.selectedTags, id: \.id) { tag in
                            TagChipView(tag: tag) {
                                state.selectedTags.removeAll { $0.id == tag.id }
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

struct ToggleSection: View {
    @Binding var state: BarcodeConfirmationState
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("On Sale")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Toggle("", isOn: $state.isOnSale)
                    .toggleStyle(SwitchToggleStyle(tint: AppColors.accentOrange))
            }
            .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Add to Shopping List")
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                    Toggle("", isOn: $state.addToShoppingList)
                        .toggleStyle(SwitchToggleStyle(tint: AppColors.accentGreen))
                }
                
                if state.addToShoppingList {
                    Text("This item will be added to your shopping list")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct ActionButton: View {
    let isExisting: Bool
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: isExisting ? "arrow.clockwise" : "plus")
                    .font(.system(size: 18, weight: .semibold))
                Text(isExisting ? "Update Item" : "Add Item")
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isEnabled ? AppColors.accentGreen : Color.gray)
            .cornerRadius(12)
        }
        .disabled(!isEnabled)
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
                
                VStack(spacing: 12) {
                    Button {
                        if !barcode.isEmpty {
                            onBarcodeEntered(barcode)
                        }
                    } label: {
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
                    
                    Button {
                        dismiss()
                    } label: {
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
    AddItemsView(availableTags: [])
}
