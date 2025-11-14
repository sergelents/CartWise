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
    @EnvironmentObject var coordinator: ShoppingListCoordinator
    let dismiss: DismissAction
    @State private var searchResults: [GroceryItem] = []
    @State private var isSearching = false
    
    private var viewModel: ShoppingListViewModel {
        coordinator.shoppingListViewModel
    }
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
                    Text("Try scanning a barcode in the Add Items tab to create this product")
                        .font(.poppins(size: 14, weight: .regular))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
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
                                    await viewModel.addExistingProductToShoppingList(product)
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
                // TODO: Barcode scanner requires AddItemsCoordinator - navigate to AddItems tab instead
                Text("Or use the Add Items tab to scan barcodes")
                    .font(.poppins(size: 14, weight: .regular))
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                    .padding(.top, 8)
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
            // TODO: This needs SearchViewModel to properly search all products
            // For now, just show empty results
            await MainActor.run {
                searchResults = []
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
