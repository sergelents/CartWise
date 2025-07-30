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
    
    @State private var scannedBarcode: String = ""
    @State private var manualBarcode: String = ""
    @State private var showingCamera = false
    @State private var showingManualEntry = false
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
    // Tag selection state
    @State private var selectedTags: [Tag] = []
    @State private var showingTagPicker = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var isProcessing = false
    @State private var showingSuccess = false
    @State private var successMessage = ""
    
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
                                    .font(.system(size: 40))
                                    .foregroundColor(AppColors.accentGreen)
                                Text("Scan barcode")
                                    .font(.headline)
                                    .foregroundColor(AppColors.textPrimary)
                            }
                        )
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
                    
                    // Manual Entry Button
                    Button(action: {
                        showingManualEntry = true
                    }) {
                        HStack {
                            Image(systemName: "keyboard")
                                .font(.system(size: 18))
                            Text("Enter Barcode Manually")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(AppColors.accentGreen)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppColors.accentGreen.opacity(0.1))
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
                        Text("Scanned Barcode:")
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
            .sheet(isPresented: $showingManualEntry) {
                ManualBarcodeEntryView(
                    barcode: $manualBarcode,
                    onBarcodeEntered: { barcode in
                        pendingBarcode = barcode
                        showingBarcodeConfirmation = true
                        showingManualEntry = false
                    }
                )
            }
            .sheet(isPresented: $showingBarcodeConfirmation) {
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
                    onConfirm: { barcode, productName, company, price, category, isOnSale, location, tags in
                        showingBarcodeConfirmation = false
                        handleBarcodeProcessing(barcode: barcode, productName: productName, company: company, price: price, category: category, isOnSale: isOnSale, location: location, tags: tags)
                    },
                    onCancel: {
                        showingBarcodeConfirmation = false
                        resetPendingData()
                    }
                )
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
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
        }
    }
    
    private func handleBarcodeScanned(_ barcode: String) {
        pendingBarcode = barcode
        showingCamera = false
        showingBarcodeConfirmation = true
    }
    
    private func handleBarcodeProcessing(barcode: String, productName: String, company: String, price: String, category: ProductCategory, isOnSale: Bool, location: Location?, tags: [Tag]) {
        scannedBarcode = barcode
        isProcessing = true
        
        Task {
            // Convert price string to Double
            let priceValue = Double(price.replacingOccurrences(of: "$", with: "")) ?? 0.0
            
            // Create product directly without API call
            let newProduct = await createProductDirectly(
                barcode: barcode,
                productName: productName.isEmpty ? "Unknown Product" : productName,
                brand: company.isEmpty ? nil : company,
                category: category == .none ? nil : category.rawValue,
                price: priceValue,
                isOnSale: isOnSale
            )
            
            print("handleBarcodeProcessing - newProduct created: \(newProduct?.productName ?? "nil")")
            print("handleBarcodeProcessing - location: \(location?.name ?? "nil")")
            print("handleBarcodeProcessing - priceValue: \(priceValue)")
            
            // Associate tags with the new product
            if let newProduct = newProduct {
                await productViewModel.addTagsToProduct(newProduct, tags: tags)
                
                // Create location-specific price if location is selected
                if let location = location {
                    print("Location selected: \(location.name ?? "Unknown")")
                    await createLocationPrice(for: newProduct, at: location, price: priceValue)
                } else {
                    print("No location selected")
                }
            } else {
                print("newProduct is nil")
            }
            
            await MainActor.run {
                isProcessing = false
                if let error = productViewModel.errorMessage {
                    errorMessage = error
                    showingError = true
                } else {
                    // Success - show success message and clear the scanned barcode
                    successMessage = "Product added successfully!"
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
    
    private func createProductDirectly(barcode: String, productName: String, brand: String?, category: String?, price: Double, isOnSale: Bool) async -> GroceryItem? {
        do {
            let context = await CoreDataStack.shared.viewContext
            
            // Check if product already exists with this barcode
            let fetchRequest: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "barcode == %@", barcode)
            
            let existingProducts = try context.fetch(fetchRequest)
            if let existingProduct = existingProducts.first {
                // Product exists, update it with new information and return it
                print("Product with barcode '\(barcode)' already exists, updating...")
                
                // Update product information if provided
                if !productName.isEmpty && productName != "Unknown Product" {
                    existingProduct.productName = productName
                }
                if let brand = brand, !brand.isEmpty {
                    existingProduct.brand = brand
                }
                if let category = category, !category.isEmpty {
                    existingProduct.category = category
                }
                existingProduct.isOnSale = isOnSale
                existingProduct.updatedAt = Date()
                
                try context.save()
                print("Updated existing product: \(existingProduct.productName ?? "Unknown") with barcode: \(barcode)")
                return existingProduct
            }
            
            // Create new product if it doesn't exist
            let newProduct = GroceryItem(
                context: context,
                id: UUID().uuidString,
                productName: productName,
                brand: brand,
                category: category,
                price: price,
                currency: "USD",
                store: nil,
                location: nil,
                imageURL: nil,
                barcode: barcode,
                isOnSale: isOnSale
            )
            
            try context.save()
            print("Created new product: \(productName) with barcode: \(barcode)")
            return newProduct
            
        } catch {
            print("Error creating/updating product: \(error)")
            productViewModel.errorMessage = error.localizedDescription
            return nil
        }
    }
    
    private func createLocationPrice(for product: GroceryItem, at location: Location, price: Double) async {
        do {
            let context = await CoreDataStack.shared.viewContext
            
            print("createLocationPrice called for product: \(product.productName ?? "Unknown")")
            print("Product ID: \(product.id ?? "nil")")
            print("Location: \(location.name ?? "Unknown")")
            print("Price: $\(price)")
            
            // Get the product in the current context
            let productFetchRequest: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
            productFetchRequest.predicate = NSPredicate(format: "id == %@", product.id ?? "")
            productFetchRequest.fetchLimit = 1
            
            let products = try context.fetch(productFetchRequest)
            guard let productInContext = products.first else {
                print("Product not found in context")
                return
            }
            print("Found product in context: \(productInContext.productName ?? "Unknown")")
            
            // Get the location in the current context
            let locationFetchRequest: NSFetchRequest<Location> = Location.fetchRequest()
            locationFetchRequest.predicate = NSPredicate(format: "id == %@", location.id ?? "")
            locationFetchRequest.fetchLimit = 1
            
            let locations = try context.fetch(locationFetchRequest)
            guard let locationInContext = locations.first else {
                print("Location not found in context")
                return
            }
            print("Found location in context: \(locationInContext.name ?? "Unknown")")
            
            // Create new GroceryItemPrice with objects from the same context
            let locationPrice = GroceryItemPrice(
                context: context,
                id: UUID().uuidString,
                price: price,
                currency: "USD",
                store: locationInContext.name, // Use location name as store
                groceryItem: productInContext,
                location: locationInContext
            )
            
            try context.save()
            print("Created location price: $\(price) at \(locationInContext.name ?? "Unknown")")
            print("Location price ID: \(locationPrice.id ?? "nil")")
            print("Product ID: \(productInContext.id ?? "nil")")
            print("Location ID: \(locationInContext.id ?? "nil")")
            
            // Verify the relationship was created
            let verifyFetchRequest: NSFetchRequest<GroceryItemPrice> = GroceryItemPrice.fetchRequest()
            verifyFetchRequest.predicate = NSPredicate(format: "groceryItem == %@", productInContext)
            let verifyPrices = try context.fetch(verifyFetchRequest)
            print("Verification: Found \(verifyPrices.count) prices for this product after creation")
            
        } catch {
            print("Error creating location price: \(error)")
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
    let onConfirm: (String, String, String, String, ProductCategory, Bool, Location?, [Tag]) -> Void
    let onCancel: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 40))
                            .foregroundColor(AppColors.accentGreen)
                        
                        Text("Product Details")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Review and edit the product information")
                            .font(.body)
                            .foregroundColor(AppColors.textPrimary.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Form Fields
                    VStack(spacing: 16) {
                        // Barcode Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Barcode Number")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            TextField("Barcode", text: $barcode)
                                .font(.system(.body, design: .monospaced))
                                .padding()
                                .background(AppColors.backgroundSecondary)
                                .cornerRadius(8)
                                .keyboardType(.numberPad)
                        }
                        
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
                        
                        // Sale Checkbox
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Button(action: {
                                    isOnSale.toggle()
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: isOnSale ? "checkmark.square.fill" : "square")
                                            .foregroundColor(isOnSale ? AppColors.accentOrange : .gray)
                                            .font(.system(size: 28))
                                        Text("On Sale")
                                            .font(.headline)
                                            .foregroundColor(AppColors.textPrimary)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Spacer()
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
                            Text("Selected Tags")
                                .font(.headline)
                                .foregroundColor(AppColors.textPrimary)
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
                    
                    Spacer(minLength: 20)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            onConfirm(barcode, productName, company, price, selectedCategory, isOnSale, selectedLocation, selectedTags)
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
                            onCancel()
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
            }
            .navigationTitle("Product Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
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
