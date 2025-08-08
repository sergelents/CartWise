//
//  AmazonPriceComponents.swift
//  CartWise
//
//  Extracted from YourListView.swift
//

import SwiftUI

// Amazon Price Results View
struct AmazonPriceResultsView: View {
    let results: [GroceryItem]
    let onSelectPrice: (Double) -> Void
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Text("Amazon Price Results")
                        .font(.poppins(size: 24, weight: .bold))
                        .padding(.top)
                    Text("Select a price from Amazon")
                        .font(.poppins(size: 16, weight: .regular))
                        .foregroundColor(.gray)
                }
                .padding(.bottom)
                // Results List
                if results.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("No price results found")
                            .font(.poppins(size: 18, weight: .semibold))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(results, id: \.objectID) { product in
                                AmazonPriceResultRow(
                                    product: product,
                                    onSelect: {
                                        onSelectPrice(product.price)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.poppins(size: 16, weight: .regular))
                    .foregroundColor(.gray)
                }
            }
        }
    }
}

// Amazon Price Result Row
struct AmazonPriceResultRow: View {
    @ObservedObject var product: GroceryItem
    let onSelect: () -> Void
    var body: some View {
        Button(action: onSelect) {
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
                    if let store = product.store, !store.isEmpty {
                        Text(store)
                            .font(.poppins(size: 12, weight: .regular))
                            .foregroundColor(.gray.opacity(0.7))
                    }
                }
                Spacer()
                // Price display - always on the right
                HStack(spacing: 8) {
                    if product.price > 0 {
                        Text("$\(String(format: "%.2f", product.price))")
                            .font(.poppins(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.accentGreen)
                            .frame(minWidth: 60, alignment: .trailing)
                    } else {
                        // Empty space to maintain alignment
                        Text("")
                            .font(.poppins(size: 16, weight: .semibold))
                            .frame(minWidth: 60, alignment: .trailing)
                    }
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}