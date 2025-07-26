//
//  FavoriteItemsView.swift
//  CartWise
//
//  Created by AI Assistant on 7/17/25.
//

import SwiftUI

struct FavoriteItemsView: View {
    @ObservedObject var productViewModel: ProductViewModel
    @State private var showingProductDetail = false
    @State private var selectedProduct: GroceryItem?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 20))
                
                Text("My Favorites")
                    .font(.poppins(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(productViewModel.favoriteProducts.count) items")
                    .font(.poppins(size: 14, weight: .regular))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            
            // Favorites List
            if productViewModel.favoriteProducts.isEmpty {
                // Empty State
                VStack(spacing: 16) {
                    Image(systemName: "heart")
                        .font(.system(size: 48))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("No favorite items yet")
                        .font(.poppins(size: 18, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Text("Add items to your favorites to see them here")
                        .font(.poppins(size: 14, weight: .regular))
                        .foregroundColor(.gray.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                // Favorites List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(productViewModel.favoriteProducts, id: \.objectID) { product in
                            FavoriteItemRow(
                                product: product,
                                onTap: {
                                    selectedProduct = product
                                    showingProductDetail = true
                                },
                                onRemoveFromFavorites: {
                                    Task {
                                        await productViewModel.removeProductFromFavorites(product)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxHeight: 300)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .sheet(isPresented: $showingProductDetail) {
            if let product = selectedProduct {
                ProductDetailView(product: product, productViewModel: productViewModel)
            }
        }
        .task {
            await productViewModel.loadFavoriteProducts()
        }
    }
}

struct FavoriteItemRow: View {
    let product: GroceryItem
    let onTap: () -> Void
    let onRemoveFromFavorites: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Product image placeholder
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.productName ?? "Unknown Product")
                        .font(.poppins(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    if let brand = product.brand, !brand.isEmpty {
                        Text(brand)
                            .font(.poppins(size: 14, weight: .regular))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                    
                    if let store = product.store, !store.isEmpty {
                        Text(store)
                            .font(.poppins(size: 12, weight: .regular))
                            .foregroundColor(.blue)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if product.price > 0 {
                        Text("$\(String(format: "%.2f", product.price))")
                            .font(.poppins(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    
                    // Remove from favorites button
                    Button(action: onRemoveFromFavorites) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 16))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    FavoriteItemsView(productViewModel: ProductViewModel(repository: ProductRepository()))
} 