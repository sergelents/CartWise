//
//  ProductImageView.swift
//  CartWise
//
//  Created by Kelly Yong on 8/4/25.
//  Enhanced with AI assistance from Cursor AI for UI improvements and functionality.
//

import SwiftUI
import UIKit

struct ProductImageView: View {
    @ObservedObject var product: GroceryItem
    let size: CGSize
    let cornerRadius: CGFloat
    let showSaleBadge: Bool
    @State private var loadedImage: UIImage?
    @State private var isLoading = false
    @State private var hasError = false
    
    init(
        product: GroceryItem,
        size: CGSize = CGSize(width: 180, height: 180),
        cornerRadius: CGFloat = 12,
        showSaleBadge: Bool = true
    ) {
        self.product = product
        self.size = size
        self.cornerRadius = cornerRadius
        self.showSaleBadge = showSaleBadge
    }
    
    var body: some View {
        Group {
            if let productImage = product.productImage {
                if let imageData = productImage.imageData, let uiImage = UIImage(data: imageData) {
                    // Display cached image data
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: size.width, height: size.height)
                        .cornerRadius(cornerRadius)
                        .overlay(saleBadgeOverlay)
                } else if let imageURL = productImage.imageURL, !imageURL.isEmpty {
                    // Fallback to loading from URL if no cached data
                    if let loadedImage = loadedImage {
                        // Display loaded image
                        Image(uiImage: loadedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: size.width, height: size.height)
                            .cornerRadius(cornerRadius)
                            .overlay(saleBadgeOverlay)
                    } else if isLoading {
                        loadingView
                    } else if hasError {
                        failureView
                    } else {
                        // Start loading
                        loadingView
                            .onAppear {
                                loadImageFromURL(imageURL)
                            }
                    }
                } else {
                    noImagePlaceholder
                }
            } else {
                noImagePlaceholder
            }
        }
        .onChange(of: product.productImage?.imageURL) { newURL in
            if let newURL = newURL, !newURL.isEmpty {
                loadImageFromURL(newURL)
            }
        }
    }
    
    private func loadImageFromURL(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            hasError = true
            return
        }
        
        isLoading = true
        hasError = false
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        self.loadedImage = image
                        self.isLoading = false
                    }
                } else {
                    await MainActor.run {
                        self.hasError = true
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.hasError = true
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var loadingView: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color(.systemGray5))
            .frame(width: size.width, height: size.height)
            .overlay(
                VStack {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading image...")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                }
            )
            .overlay(saleBadgeOverlay)
    }
    

    
    private var failureView: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color(.systemGray5))
            .frame(width: size.width, height: size.height)
            .overlay(
                VStack(spacing: 4) {
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                        .font(.system(size: min(size.width, size.height) * 0.3))
                    Text("Image unavailable")
                        .font(.system(size: min(size.width, size.height) * 0.08))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 8)
            )
            .overlay(saleBadgeOverlay)
    }
    
    private var noImagePlaceholder: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color(.systemGray5))
            .frame(width: size.width, height: size.height)
            .overlay(
                VStack(spacing: 4) {
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                        .font(.system(size: min(size.width, size.height) * 0.3))
                    Text("No image available")
                        .font(.system(size: min(size.width, size.height) * 0.08))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 8)
            )
            .overlay(saleBadgeOverlay)
    }
    
    private var saleBadgeOverlay: some View {
        VStack {
            if product.isOnSale && showSaleBadge {
                Text("Sale")
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 100, height: 24)
                    .foregroundColor(.white)
                    .background(Color.accentColorOrange.opacity(0.9))
                    .cornerRadius(8)
            }
            Spacer()
        }
        .padding(.top, 12)
    }
} 