//
//  FavoriteItemsView.swift
//  CartWise
//
//  Created by AI Assistant on 7/17/25.
//

import SwiftUI

struct FavoriteItemsView: View {
    @EnvironmentObject var productViewModel: ProductViewModel
    @State private var showingProductDetail = false
    @State private var selectedProduct: GroceryItem?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Enhanced Header
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    AppColors.accentGreen.opacity(0.2),
                                    AppColors.accentGreen.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "heart.fill")
                        .foregroundColor(AppColors.accentGreen)
                        .font(.system(size: 18, weight: .medium))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("My Favorite Items")
                        .font(.poppins(size: 22, weight: .bold))
                        .foregroundColor(.primary)
                        .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                    
                    Text("Manage your favorite shopping items")
                        .font(.poppins(size: 14, weight: .regular))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text("\(productViewModel.favoriteProducts.count) items")
                    .font(.poppins(size: 15, weight: .medium))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.1))
                    )
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            
            // Divider line
            Divider()
                .background(Color.gray.opacity(0.3))
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            
            // Enhanced Favorites List
            if productViewModel.favoriteProducts.isEmpty {
                // Enhanced Empty State
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.gray.opacity(0.1),
                                        Color.gray.opacity(0.05)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "heart")
                            .font(.system(size: 36, weight: .light))
                            .foregroundColor(.gray.opacity(0.6))
                    }
                    
                    VStack(spacing: 8) {
                        Text("No favorite items yet")
                            .font(.poppins(size: 20, weight: .semibold))
                            .foregroundColor(.gray)
                        
                        Text("Add items to your favorites to see them here")
                            .font(.poppins(size: 15, weight: .regular))
                            .foregroundColor(.gray.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                // Enhanced Favorites List
                ScrollView {
                    LazyVStack(spacing: 16) {
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
                    .padding(.horizontal, 20)
                }
                .frame(maxHeight: 320)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
        )
        .padding(.vertical, 16)
        .sheet(isPresented: $showingProductDetail) {
            if let product = selectedProduct {
                ProductDetailView(product: product, selectedLocation: nil)
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
            HStack(spacing: 16) {
                // Enhanced Product image placeholder
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(.systemGray5),
                                Color(.systemGray6)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray.opacity(0.6))
                            .font(.system(size: 20, weight: .light))
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(product.productName ?? "Unknown Product")
                        .font(.poppins(size: 17, weight: .semibold))
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
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.accentGreen)
                            Text(store)
                                .font(.poppins(size: 12, weight: .medium))
                                .foregroundColor(AppColors.accentGreen)
                                .lineLimit(1)
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    if product.price > 0 {
                        Text("$\(String(format: "%.2f", product.price))")
                            .font(.poppins(size: 17, weight: .bold))
                            .foregroundColor(AppColors.accentGreen)
                    }
                    
                    // Enhanced Remove from favorites button
                    Button(action: onRemoveFromFavorites) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            AppColors.accentGreen.opacity(0.2),
                                            AppColors.accentGreen.opacity(0.1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "heart.fill")
                                .foregroundColor(AppColors.accentGreen)
                                .font(.system(size: 14, weight: .medium))
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    FavoriteItemsView()
} 