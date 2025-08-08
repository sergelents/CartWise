//
//  SmartAddProductModal.swift
//  CartWise
//
//  Extracted from YourListView.swift
//

import SwiftUI

struct SmartAddProductModal: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var showCursor = false
    @State private var isCancelPressed = false
    @FocusState private var isSearchFocused: Bool
    @EnvironmentObject var productViewModel: ProductViewModel
    let onAdd: (String, String?, String?, Double?) -> Void
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Fixed Header with Search
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
                    .background(AppColors.backgroundSecondary)
                    // Scrollable Content Area
                    ScrollView {
                        VStack(spacing: 0) {
                            // Results Section
                            if searchText.isEmpty {
                                // Show empty state when search is empty
                                VStack(spacing: 16) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 48))
                                        .foregroundColor(.gray)
                                    Text("Search for products to add to your list")
                                        .font(.poppins(size: 18, weight: .semibold))
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity, minHeight: geometry.size.height * 0.4)
                                .padding(.top, 40)
                            } else {
                                // Show search results
                                SearchResultsSection(
                                    searchText: searchText,
                                    onAdd: { name, brand, category, price in
                                        onAdd(name, brand, category, price)
                                        dismiss()
                                    },
                                    onCreateNew: {
                                        // This is no longer used since we redirect to barcode scanner
                                    },
                                    dismiss: dismiss
                                )
                            }
                        }
                    }
                    .background(AppColors.backgroundSecondary)
                }
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
        }
    }
}