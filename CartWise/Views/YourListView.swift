//
//  YourListView.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/5/25.
//  Edited by Brenna Wilson on 7/10/25 - 7/13/25
//  Enhanced with AI assistance from Cursor AI for UI improvements and functionality. 
//  This saved me 6-9 hours of work learning swift UI syntax.
//

import SwiftUI

struct YourListView: View {
    @StateObject private var productViewModel = ProductViewModel(repository: ProductRepository())
    @State private var suggestedStore: String = "Whole Foods Market"
    @State private var storeAddress: String = "1701 Wewatta St."
    @State private var total: Double = 0.00
    @State private var allItemsChecked: Bool = false
    @State private var isEditing: Bool = false
    @State private var selectedItemsForDeletion: Set<String> = []
    @State private var showingAddProductModal = false
    @State private var showingRatingPrompt: Bool = false
    @State private var showingDuplicateAlert = false
    @State private var duplicateProductName = ""
    
    var body: some View {
        NavigationStack {
            MainContentView(
                productViewModel: productViewModel,
                isEditing: $isEditing,
                allItemsChecked: $allItemsChecked,
                selectedItemsForDeletion: $selectedItemsForDeletion,
                suggestedStore: suggestedStore,
                storeAddress: storeAddress,
                total: total,
                showingRatingPrompt: $showingRatingPrompt,
                showingAddProductModal: $showingAddProductModal
            )
            .sheet(isPresented: $showingRatingPrompt) {
                RatingPromptView()
            }
            .sheet(isPresented: $showingAddProductModal) {
                SmartAddProductModal(productViewModel: productViewModel, onAdd: addProductToSystem)
            }
            .alert("Duplicate Product", isPresented: $showingDuplicateAlert) {
                Button("OK") {
                    showingDuplicateAlert = false
                }
            } message: {
                Text("A product named \"\(duplicateProductName)\" already exists in your list.")
            }
            .onAppear {
                Task {
                    await productViewModel.loadListProducts()
                }
            }
        }
    }
    
    private func addProductToSystem(name: String, brand: String?, category: String?) {
        Task {
            // Check for duplicate first
            if await productViewModel.isDuplicateProduct(name: name) {
                duplicateProductName = name
                showingDuplicateAlert = true
                return
            }
            
            // Proceed with creation if no duplicate
            if let brand = brand, !brand.isEmpty {
                await productViewModel.createProductForShoppingList(byName: name, brand: brand, category: category)
            } else {
                await productViewModel.createProductForShoppingList(byName: name, brand: nil, category: category)
            }
        }
    }
}

// Main Content View, edited by AI
struct MainContentView: View {
    @ObservedObject var productViewModel: ProductViewModel
    @Binding var isEditing: Bool
    @Binding var allItemsChecked: Bool
    @Binding var selectedItemsForDeletion: Set<String>
    let suggestedStore: String
    let storeAddress: String
    let total: Double
    @Binding var showingRatingPrompt: Bool
    @Binding var showingAddProductModal: Bool
    
    var body: some View {
        ZStack {
            // Background
            AppColors.backgroundSecondary
                .ignoresSafeArea()
            
            // Main Content
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Your Shopping List")
                                .font(.poppins(size:32, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text("\(productViewModel.products.count) items | $0.00")
                                .font(.poppins(size:15, weight: .regular))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 8)

                // Item List Card
                ShoppingListCard(
                    productViewModel: productViewModel,
                    isEditing: $isEditing,
                    allItemsChecked: $allItemsChecked,
                    selectedItemsForDeletion: $selectedItemsForDeletion,
                    showingRatingPrompt: $showingRatingPrompt,
                    showingAddProductModal: $showingAddProductModal
                )

                // TODO: Add store card functionality and price calculation
                // Store Card
                StoreCard(
                    suggestedStore: suggestedStore,
                    storeAddress: storeAddress,
                    total: 0.0 // Core Data products don't have price yet
                )

                Spacer()
            }
            .padding(.top)
        }
    }
}

// Shopping List Card
struct ShoppingListCard: View {
    @ObservedObject var productViewModel: ProductViewModel
    @Binding var isEditing: Bool
    @Binding var allItemsChecked: Bool
    @Binding var selectedItemsForDeletion: Set<String>
    @Binding var showingRatingPrompt: Bool
    @Binding var showingAddProductModal: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                if isEditing {
                    HStack(spacing: 16) {
                        Button(action: {
                            // Remove selected items from shopping list
                            for barcode in selectedItemsForDeletion {
                                if let product = productViewModel.products.first(where: { $0.barcode == barcode }) {
                                    Task {
                                        await productViewModel.removeProduct(product)
                                    }
                                }
                            }
                            isEditing = false
                            selectedItemsForDeletion.removeAll()
                        }) {
                            Text("Delete")
                                .font(.poppins(size:15, weight: .regular))
                                .underline()
                                .foregroundColor(.red)
                        }
                        Button(action: {
                            if selectedItemsForDeletion.count == productViewModel.products.count {
                                selectedItemsForDeletion.removeAll()
                            } else {
                                selectedItemsForDeletion = Set(productViewModel.products.compactMap { $0.barcode })
                            }
                        }) {
                            Text(selectedItemsForDeletion.count == productViewModel.products.count ? "Deselect All" : "Select All")
                                .font(.poppins(size:15, weight: .regular))
                                .underline()
                                .foregroundColor(.blue)
                        }
                    }
                    Spacer()
                    Button(action: {
                        isEditing = false
                        selectedItemsForDeletion.removeAll()
                    }) {
                        Text("Cancel")
                            .font(.poppins(size:15, weight: .regular))
                            .underline()
                            .foregroundColor(.gray)
                    }
                } else {
                    Text("\(productViewModel.products.count) Items")
                        .font(.poppins(size:15, weight: .regular))
                        .foregroundColor(.gray)
                    Spacer()
                    Button(action: {
                        isEditing.toggle()
                    }) {
                        Text("Edit")
                            .font(.poppins(size:15, weight: .regular))
                            .underline()
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal)

            Divider()
            
            // Item List
            if productViewModel.products.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "basket")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(AppColors.accentGreen.opacity(0.7))
                    Text("You have nothing on your list!")
                        .font(.poppins(size: 18, weight: .semibold))
                        .foregroundColor(.gray)
                    HStack(spacing: 4) {
                        Text("Tap the")
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(AppColors.accentGreen)
                            .font(.system(size: 16))
                        Text("button to add your first item.")
                    }
                        .font(.poppins(size: 15, weight: .regular))
                        .foregroundColor(.gray.opacity(0.7))

                }
                .frame(maxWidth: .infinity, minHeight: 120)
                .padding(.vertical, 24)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(productViewModel.products, id: \.objectID) { product in
                            ShoppingListItemRow(
                                product: product,
                                isEditing: isEditing,
                                isSelected: selectedItemsForDeletion.contains(product.barcode ?? ""),
                                onToggle: {
                                    if isEditing {
                                        if let barcode = product.barcode {
                                            if selectedItemsForDeletion.contains(barcode) {
                                                selectedItemsForDeletion.remove(barcode)
                                            } else {
                                                selectedItemsForDeletion.insert(barcode)
                                            }
                                        }
                                    } else {
                                        // Toggle completion status
                                        Task {
                                            await productViewModel.toggleProductCompletion(product)
                                            // Check if all products are completed after toggling
                                            if productViewModel.allProductsCompleted {
                                                showingRatingPrompt = true
                                            }
                                        }
                                    }
                                },
                                onDelete: {
                                    Task {
                                        await productViewModel.removeProduct(product)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.top, 8)
                }
                .frame(maxHeight: 200)
            }

            // Add Button & Check All Button 
            HStack(spacing: 56) {
                Button(action: {
                    showingAddProductModal = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(AppColors.accentGreen)
                        .shadow(color: AppColors.accentGreen.opacity(0.3), radius: 8, x: 0, y: 4)
                )
                
                Button(action: {
                    Task {
                        await productViewModel.toggleAllProductsCompletion()
                        // Show rating prompt after completing all items
                        showingRatingPrompt = true
                    }
                }) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(AppColors.accentOrange)
                        .shadow(color: AppColors.accentOrange.opacity(0.3), radius: 8, x: 0, y: 4)
                )
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
        }
        .padding()
        .background(AppColors.backgroundPrimary)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.07), radius: 3, x: 0, y: 2)
        .padding(.horizontal)
    }
}

// Store Card
struct StoreCard: View {
    let suggestedStore: String
    let storeAddress: String
    let total: Double
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Running Total at Suggested Store")
                .font(.poppins(size:13, weight: .regular))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
            Divider()
            Text("$\(Int(total))")
                .font(.poppins(size:35, weight: .bold))

            Text(suggestedStore)
                .font(.poppins(size:19, weight: .semibold))

            Text(storeAddress)
                .font(.poppins(size:15, weight: .regular))
                .foregroundColor(.gray)

            Button("Change Store") {
                // TODO: Store changer functionality
            }
            .font(.poppins(size:15, weight: .bold))
            .padding(.vertical, 4)
            .padding(.horizontal, 30)
            .background(.gray.opacity(0.15))
            .foregroundColor(AppColors.accentGreen)
            .cornerRadius(20)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.07), radius: 3, x: 0, y: 2)
        .padding(.horizontal)
    }
}

struct SmartAddProductModal: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var productBrand = ""
    @State private var selectedCategory: ProductCategory = .none
    @State private var showCategoryPicker = false
    @State private var isCreatingNew = false
    @State private var showCursor = false
    @State private var isCancelPressed = false
    @FocusState private var isSearchFocused: Bool
    @ObservedObject var productViewModel: ProductViewModel
    let onAdd: (String, String?, String?) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Header
                VStack(spacing: 16) {
                    Text("Add to Your List")
                        .font(.poppins(size: 24, weight: .bold))
                        .padding(.top)
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        ZStack(alignment: .leading) {
                            TextField("", text: $searchText)
                                .font(.poppins(size: 16, weight: .regular))
                                .focused($isSearchFocused)
                                .onChange(of: searchText) {
                                    isCreatingNew = false
                                }
                                .onChange(of: isSearchFocused) { _, focused in
                                    if focused && searchText.isEmpty {
                                        showCursor = true
                                    } else {
                                        showCursor = false
                                    }
                                }
                            
                            // Placeholder text when not focused
                            if searchText.isEmpty && !isSearchFocused {
                                Text("Search products...")
                                    .font(.poppins(size: 16, weight: .regular))
                                    .foregroundColor(.gray)
                                    .allowsHitTesting(false)
                            }
                            
                            // Solid cursor when focused
                            if searchText.isEmpty && isSearchFocused {
                                Rectangle()
                                    .fill(AppColors.accentGreen)
                                    .frame(width: 2, height: 20)
                                    .allowsHitTesting(false)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .padding(.bottom)
                
                // Results Section
                if searchText.isEmpty {
                    // Show recent products when search is empty
                    RecentProductsSection(productViewModel: productViewModel, onAdd: onAdd, dismiss: dismiss)
                } else {
                    // Show search results
                    SearchResultsSection(
                        searchText: searchText,
                        onAdd: { name, brand, category in
                            onAdd(name, brand, category)
                            dismiss()
                        },
                        onCreateNew: {
                            isCreatingNew = true
                        },
                        productViewModel: productViewModel,
                        dismiss: dismiss
                    )
                }
                
                // Create New Product Section (when creating new)
                if isCreatingNew {
                    CreateNewProductSection(
                        productName: searchText,
                        productBrand: $productBrand,
                        selectedCategory: $selectedCategory,
                        showCategoryPicker: $showCategoryPicker,
                        onAdd: { name, brand, category in
                            onAdd(name, brand, category)
                            dismiss()
                        }
                    )
                }
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Cancel")
                        .font(.poppins(size: 16, weight: .regular))
                        .foregroundColor(isCancelPressed ? .gray.opacity(0.5) : .gray)
                        .underline()
                        .padding(.leading, 8)
                        .padding(.top, 4)
                        .onTapGesture {
                            isCancelPressed = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isCancelPressed = false
                                dismiss()
                            }
                        }
                }
            }
            .sheet(isPresented: $showCategoryPicker) {
                CategoryPickerView(selectedCategory: $selectedCategory)
            }
        }
    }
}

struct RecentProductsSection: View {
    @ObservedObject var productViewModel: ProductViewModel
    let onAdd: (String, String?, String?) -> Void
    let dismiss: DismissAction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Products")
                .font(.poppins(size: 18, weight: .semibold))
                .padding(.horizontal)
            
            if productViewModel.recentProducts.isEmpty {
                Text("No recent products yet")
                    .font(.poppins(size: 14, weight: .regular))
                    .foregroundColor(.gray)
                    .padding(.horizontal)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(productViewModel.recentProducts.prefix(5), id: \.objectID) { product in
                        RecentProductRow(product: product) {
                            Task {
                                await productViewModel.addExistingProductToShoppingList(product)
                                await productViewModel.loadListProducts()
                            }
                            dismiss()
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .onAppear {
            Task {
                await productViewModel.loadRecentProducts(limit: 10)
            }
        }
    }
}

struct SearchResultsSection: View {
    let searchText: String
    let onAdd: (String, String?, String?) -> Void
    let onCreateNew: () -> Void
    @ObservedObject var productViewModel: ProductViewModel
    let dismiss: DismissAction
    @State private var searchResults: [Product] = []
    @State private var isSearching = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Search Results")
                .font(.poppins(size: 18, weight: .semibold))
                .padding(.horizontal)
            
            if isSearching {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Searching...")
                        .font(.poppins(size: 14, weight: .regular))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
            } else if searchResults.isEmpty {
                // No results found - show create new option
                Button(action: onCreateNew) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(AppColors.accentGreen)
                        Text("Add \"\(searchText)\" as new product")
                            .font(.poppins(size: 16, weight: .regular))
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            } else {
                // Show search results
                LazyVStack(spacing: 8) {
                    ForEach(searchResults, id: \.objectID) { product in
                        SearchResultRow(product: product) {
                            // Add existing product to shopping list
                            Task {
                                await productViewModel.addExistingProductToShoppingList(product)
                            }
                            dismiss()
                        }
                    }
                }
                .padding(.horizontal)
                
                // Divider and create new option
                Divider()
                    .padding(.horizontal)
                
                Button(action: onCreateNew) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(AppColors.accentGreen)
                        Text("Add \"\(searchText)\" as new product")
                            .font(.poppins(size: 16, weight: .regular))
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }
        }
        .onChange(of: searchText) { _, newValue in
            if !newValue.isEmpty {
                performSearch()
            } else {
                searchResults = []
            }
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        Task {
            // Store current products to restore them later
            let currentProducts = productViewModel.products
            
            // Perform search
            await productViewModel.searchProducts(by: searchText)
            
            await MainActor.run {
                // Store search results and restore original products
                searchResults = productViewModel.products
                productViewModel.products = currentProducts
                isSearching = false
            }
        }
    }
    

}

struct SearchResultRow: View {
    let product: Product
    let onAdd: () -> Void
    
    var body: some View {
        Button(action: onAdd) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.name ?? "Unknown Product")
                        .font(.poppins(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    if let brands = product.brands, !brands.isEmpty {
                        Text(brands)
                            .font(.poppins(size: 14, weight: .regular))
                            .foregroundColor(.gray)
                    }
                    
                    if let categories = product.categories, !categories.isEmpty {
                        Text(categories)
                            .font(.poppins(size: 12, weight: .regular))
                            .foregroundColor(.gray.opacity(0.7))
                    }
                }
                
                Spacer()
                
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(AppColors.accentGreen)
                    .font(.system(size: 20))
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CreateNewProductSection: View {
    let productName: String
    @Binding var productBrand: String
    @Binding var selectedCategory: ProductCategory
    @Binding var showCategoryPicker: Bool
    let onAdd: (String, String?, String?) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Divider()
                .padding(.horizontal)
            
            Text("Create New Product")
                .font(.poppins(size: 18, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            VStack(spacing: 16) {
                // Product Name (pre-filled from search)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Product Name")
                        .font(.poppins(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(productName)
                        .font(.poppins(size: 16, weight: .regular))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                // Brand
                VStack(alignment: .leading, spacing: 8) {
                    Text("Brand (Optional)")
                        .font(.poppins(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    TextField("e.g., Happy Hens", text: $productBrand)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.poppins(size: 16, weight: .regular))
                }
                
                // Category
                VStack(alignment: .leading, spacing: 8) {
                    Text("Category")
                        .font(.poppins(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Button(action: {
                        showCategoryPicker = true
                    }) {
                        HStack {
                            Text(selectedCategory.rawValue)
                                .font(.poppins(size: 16, weight: .regular))
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal)
            
            // Add Button
            Button("Add to List") {
                let brand = productBrand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : productBrand.trimmingCharacters(in: .whitespacesAndNewlines)
                let category = selectedCategory == .none ? nil : selectedCategory.rawValue
                onAdd(productName, brand, category)
            }
            .font(.poppins(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppColors.accentGreen)
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
}

struct CategoryPickerView: View {
    @Binding var selectedCategory: ProductCategory
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(ProductCategory.allCases, id: \.self) { category in
                Button(action: {
                    selectedCategory = category
                    dismiss()
                }) {
                    HStack {
                        Text(category.rawValue)
                            .font(.poppins(size: 16, weight: .regular))
                            .foregroundColor(category == .none ? .gray : .primary)
                        Spacer()
                        if selectedCategory == category && category != .none {
                            Image(systemName: "checkmark")
                                .foregroundColor(AppColors.accentGreen)
                        }
                    }
                }
            }
            .navigationTitle("Select Category")
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

// Shopping List circle logic
struct ShoppingListItemRow: View {
    let product: Product
    let isEditing: Bool
    let isSelected: Bool
    let onToggle: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(alignment: .center) {
            Button(action: onToggle) {
                if isEditing {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 20))
                    } else {
                        Image(systemName: "circle")
                            .foregroundColor(.red)
                            .font(.system(size: 20))
                    }
                } else {
                    // Show completion status
                    if product.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppColors.accentGreen)
                            .font(.system(size: 20))
                    } else {
                        Image(systemName: "circle")
                            .foregroundColor(AppColors.accentGreen)
                            .font(.system(size: 20))
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .frame(width: 20, height: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(product.name ?? "Unknown Product")
                    .font(.poppins(size:15, weight: .regular))
                    .foregroundColor(product.isCompleted ? .gray : .primary)
                    .strikethrough(product.isCompleted)

                if let brands = product.brands, !brands.isEmpty {
                    Text(brands)
                        .font(.poppins(size:12, weight: .regular))
                        .foregroundColor(.gray)
                }
                if let categories = product.categories, !categories.isEmpty {
                    Text(categories)
                        .font(.poppins(size:10, weight: .regular))
                        .foregroundColor(.gray.opacity(0.7))
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.07), radius: 3, x: 0, y: 2)
        )
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        .padding(.horizontal, 2)
    }
}

// Rating Prompt View
struct RatingPromptView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showRatingScreen = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(AppColors.accentGreen)
                
                Text("Have you finished shopping?")
                    .font(.poppins(size:24, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Rate your experience")
                    .font(.poppins(size:16, weight: .regular))
                    .foregroundColor(.gray)
            }
            .padding(.top, 40)
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 12) {
                Button(action: {
                    showRatingScreen = true
                }) {
                    Text("Rate my experience")
                        .font(.poppins(size:16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(AppColors.accentGreen)
                        .cornerRadius(12)
                        .contentShape(Rectangle())
                }
                
                Button(action: {
                    dismiss()
                }) {
                    Text("No thanks")
                        .font(.poppins(size:16, weight: .regular))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .contentShape(Rectangle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(AppColors.backgroundSecondary)
        .sheet(isPresented: $showRatingScreen) {
            ShoppingExperienceRatingView(dismissAll: {
                dismiss() 
                showRatingScreen = false 
            })
        }
    }
}

// Shopping Experience Rating View
struct ShoppingExperienceRatingView: View {
    var dismissAll: () -> Void
    @State private var pricingRating: Int = 0
    @State private var overallRating: Int = 0
    
    var body: some View {
        VStack(spacing: 32) {
            Text("Rate your shopping Experience!")
                .font(.poppins(size:28, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.top, 32)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Grocery Store")
                    .font(.poppins(size:20, weight: .bold))
                // TODO: Connect to Google Maps API for live store info
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(AppColors.accentGreen)
                    Text("Whole Foods Market")
                        .font(.poppins(size:17, weight: .semibold))
                    Spacer()
                    Text("1701 Wewatta St.")
                        .font(.poppins(size:15, weight: .regular))
                        .foregroundColor(.gray)
                }
                .padding(12)
                .background(Color.gray.opacity(0.10))
                .cornerRadius(16)
            }
            .padding(.horizontal, 16)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Pricing Accuracy")
                    .font(.poppins(size:20, weight: .bold))
                StarRatingView(rating: $pricingRating, accentColor: AppColors.accentGreen)
            }
            .padding(.horizontal, 16)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Overall Experience")
                    .font(.poppins(size:20, weight: .bold))
                StarRatingView(rating: $overallRating, accentColor: AppColors.accentGreen)
            }
            .padding(.horizontal, 16)
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 12) {
                Button(action: {
                    // TODO: Handle submit logic
                    dismissAll()
                }) {
                    Text("Submit")
                        .font(.poppins(size:16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(AppColors.accentGreen)
                        .cornerRadius(12)
                        .contentShape(Rectangle())
                }
                
                Button(action: {
                    dismissAll()
                }) {
                    Text("Cancel")
                        .font(.poppins(size:16, weight: .regular))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .contentShape(Rectangle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(AppColors.backgroundSecondary)
        .cornerRadius(24)
        .padding(8)
    }
}

// Star Rating View
struct StarRatingView: View {
    @Binding var rating: Int
    var accentColor: Color = .yellow
    let maxRating = 5
    
    var body: some View {
        HStack(spacing: 16) {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: rating >= index ? "star.fill" : "star")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 36, height: 36)
                    .foregroundColor(accentColor)
                    .onTapGesture {
                        rating = index
                    }
            }
        }
    }
}

struct RecentProductRow: View {
    let product: Product
    let onAdd: () -> Void
    
    var body: some View {
        Button(action: onAdd) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.name ?? "Unknown Product")
                        .font(.poppins(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    if let brands = product.brands, !brands.isEmpty {
                        Text(brands)
                            .font(.poppins(size: 14, weight: .regular))
                            .foregroundColor(.gray)
                    }
                    
                    if let categories = product.categories, !categories.isEmpty {
                        Text(categories)
                            .font(.poppins(size: 12, weight: .regular))
                            .foregroundColor(.gray.opacity(0.7))
                    }
                }
                
                Spacer()
                
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(AppColors.accentGreen)
                    .font(.system(size: 20))
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}




#Preview {
    YourListView()
}
