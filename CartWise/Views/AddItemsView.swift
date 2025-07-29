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
                    showCategoryPicker: $showCategoryPicker,
                    availableTags: availableTags,
                    selectedTags: $selectedTags,
                    showingTagPicker: $showingTagPicker,
                    onConfirm: { barcode, productName, company, price, category, isOnSale, tags in
                        showingBarcodeConfirmation = false
                        handleBarcodeProcessing(barcode: barcode, productName: productName, company: company, price: price, category: category, isOnSale: isOnSale, tags: tags)
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
    
    private func handleBarcodeProcessing(barcode: String, productName: String, company: String, price: String, category: ProductCategory, isOnSale: Bool, tags: [Tag]) {
        scannedBarcode = barcode
        isProcessing = true
        
        Task {
            // Convert price string to Double
            let priceValue = Double(price.replacingOccurrences(of: "$", with: "")) ?? 0.0
            let newProduct = await productViewModel.createProductByBarcode(
                barcode,
                isOnSale: isOnSale,
                productName: productName.isEmpty ? "Unknown Product" : productName,
                brand: company.isEmpty ? nil : company,
                category: category == .none ? nil : category.rawValue,
                price: priceValue
            )
            // Associate tags with the new product
            if let newProduct = newProduct {
                await productViewModel.addTagsToProduct(newProduct, tags: tags)
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
    
    private func resetPendingData() {
        pendingBarcode = ""
        pendingProductName = ""
        pendingCompany = ""
        pendingPrice = ""
        pendingCategory = .none
        pendingIsOnSale = false
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
    @Binding var showCategoryPicker: Bool
    let availableTags: [Tag]
    @Binding var selectedTags: [Tag]
    @Binding var showingTagPicker: Bool
    let onConfirm: (String, String, String, String, ProductCategory, Bool, [Tag]) -> Void
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
                            onConfirm(barcode, productName, company, price, selectedCategory, isOnSale, selectedTags)
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
