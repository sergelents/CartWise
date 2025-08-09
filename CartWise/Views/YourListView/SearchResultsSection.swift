//
//  SearchResultsSection.swift
//  CartWise
//
//  Extracted from YourListView.swift
//

import SwiftUI

struct SearchResultsSection: View {
    let searchText: String
    let onAdd: (String, String?, String?, Double?) -> Void
    let onCreateNew: () -> Void
    @EnvironmentObject var productViewModel: ProductViewModel
    let dismiss: DismissAction
    @State private var searchResults: [GroceryItem] = []
    @State private var isSearching = false
    @State private var showingBarcodeScanner = false
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
                // No results found - redirect to barcode scanner
                VStack(spacing: 16) {
                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 48))
                        .foregroundColor(AppColors.accentGreen)
                    Text("No products found")
                        .font(.poppins(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    Text("Use the barcode scanner to add \"\(searchText)\" to your list")
                        .font(.poppins(size: 14, weight: .regular))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    Button(action: {
                        showingBarcodeScanner = true
                    }) {
                        HStack {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 18))
                            Text("Open Barcode Scanner")
                                .font(.poppins(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppColors.accentGreen)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 20)
            } else {
                // Show search results in a scrollable container
                ScrollView {
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
                }
                .frame(maxHeight: UIScreen.main.bounds.height * 0.6) // Larger scroll area for full-screen modal
                // Divider and barcode scanner option
                Divider()
                    .padding(.horizontal)
                Button(action: {
                    showingBarcodeScanner = true
                }) {
                    HStack {
                        Image(systemName: "barcode.viewfinder")
                            .foregroundColor(AppColors.accentGreen)
                        Text("Scan barcode for \"\(searchText)\"")
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
        .sheet(isPresented: $showingBarcodeScanner) {
            AddItemsView(availableTags: productViewModel.tags)
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
    @ObservedObject var product: GroceryItem
    let onAdd: () -> Void
    var body: some View {
        Button(action: onAdd) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.productName ?? "Unknown Product")
                        .font(.poppins(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    if let brand = product.brand, !brand.isEmpty {
                        Text(brand)
                            .font(.poppins(size: 14, weight: .regular))
                            .foregroundColor(.gray)
                    }
                    if let category = product.category, !category.isEmpty {
                        Text(category)
                            .font(.poppins(size: 12, weight: .regular))
                            .foregroundColor(.gray.opacity(0.7))
                    }
                }
                Spacer()
                Spacer()
                // Add button - no price display since prices vary by store
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
