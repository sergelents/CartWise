//
//  ProductImageView.swift
//  CartWise
//
//  Created by Kelly Yong on 8/4/25.
//  Enhanced with AI assistance from Cursor AI for UI improvements and functionality.
//
//  Product image view with optional camera functionality

import SwiftUI
import UIKit

struct ProductImageView: View {
    // Properties
    @ObservedObject var product: GroceryItem
    let size: CGSize
    let cornerRadius: CGFloat
    let showSaleBadge: Bool
    let showCameraButton: Bool
    
    // State
    @State private var loadedImage: UIImage?
    @State private var isLoading = false
    @State private var hasError = false
    @State private var showingCamera = false
    @State private var userCapturedImage: UIImage?
    @State private var imageUpdateTrigger = false
    
    init(
        product: GroceryItem,
        size: CGSize = CGSize(width: 180, height: 180),
        cornerRadius: CGFloat = 12,
        showSaleBadge: Bool = true,
        showCameraButton: Bool = false
    ) {
        self.product = product
        self.size = size
        self.cornerRadius = cornerRadius
        self.showSaleBadge = showSaleBadge
        self.showCameraButton = showCameraButton
    }
    
    var body: some View {
        Group {
            if let productImage = product.productImage {
                // Product has an image entity
                if let imageData = productImage.imageData, let uiImage = UIImage(data: imageData) {
                    // Priority 1: Display cached image data from Core Data
                    displayImage(uiImage)
                } else if let imageURL = productImage.imageURL, !imageURL.isEmpty {
                    // Priority 2: Load from URL if no cached data
                    handleURLImageLoading(imageURL)
                } else {
                    // No image data or URL available
                    noImagePlaceholder
                }
            } else {
                // No product image entity exists
                noImagePlaceholder
            }
        }
        .onChange(of: product.productImage?.imageURL) { newURL in
            // Handle URL changes
            if let newURL = newURL, !newURL.isEmpty {
                loadImageFromURL(newURL)
            }
        }
        .onChange(of: product.productImage?.imageData) { _ in
            // Handle image data changes
            print("ProductImageView: imageData changed")
            if let imageData = product.productImage?.imageData,
               let image = UIImage(data: imageData) {
                print("ProductImageView: Creating UIImage from data, size: \(image.size)")
                loadedImage = image
                isLoading = false
                hasError = false
            } else {
                print("ProductImageView: No valid image data found")
            }
        }
        .onChange(of: imageUpdateTrigger) { _ in
            // Force refresh when trigger changes
            print("ProductImageView: imageUpdateTrigger changed")
            print("ProductImageView: productImage exists: \(product.productImage != nil)")
            if let productImage = product.productImage {
                print("ProductImageView: imageData exists: \(productImage.imageData != nil)")
                if let imageData = productImage.imageData {
                    print("ProductImageView: imageData size: \(imageData.count) bytes")
                    if let image = UIImage(data: imageData) {
                        print("ProductImageView: Creating UIImage from trigger, size: \(image.size)")
                        loadedImage = image
                        isLoading = false
                        hasError = false
                    } else {
                        print("ProductImageView: Failed to create UIImage from data")
                    }
                } else {
                    print("ProductImageView: No imageData found")
                }
            } else {
                print("ProductImageView: No productImage found")
            }
        }
        .sheet(isPresented: $showingCamera) {
            // Camera view
            PhotoCameraView { capturedImage in
                if let image = capturedImage {
                    userCapturedImage = image
                    saveUserImage(image)
                }
            }
        }
    }
    
    // Helper methods
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
    
    /// Displays an image with proper styling and overlays
    private func displayImage(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size.width, height: size.height)
            .cornerRadius(cornerRadius)
            .overlay(saleBadgeOverlay)
            .overlay(cameraButtonOverlay)
    }
    
    /// Handles the loading state for URL-based images
    @ViewBuilder
    private func handleURLImageLoading(_ imageURL: String) -> some View {
        if let loadedImage = loadedImage {
            // Display loaded image
            displayImage(loadedImage)
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
    }
    
    // View components
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
            .overlay(cameraButtonOverlay)
    }
    

    
    /// Error state view when image loading fails
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
            .overlay(cameraButtonOverlay)
    }
    
    /// Placeholder view when no image is available
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
            .overlay(cameraButtonOverlay)
    }
    
    /// Sale badge overlay for products on sale
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
    
    /// Camera button overlay for taking product photos (only shown in detail view)
    private var cameraButtonOverlay: some View {
        Group {
            if showCameraButton {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            showingCamera = true
                        }) {
                            Image(systemName: "camera")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .padding(.top, 8)
                        .padding(.trailing, 8)
                    }
                    Spacer()
                }
            }
        }
    }
    
    // Camera integration
    
    /// Saves a captured image to Core Data and updates the UI
    private func saveUserImage(_ image: UIImage) {
        // Save the captured image to Core Data
        Task {
            await MainActor.run {
                print("ProductImageView: saveUserImage called with image size: \(image.size)")
                if let imageData = image.jpegData(compressionQuality: 0.8) {
                    print("ProductImageView: Created JPEG data, size: \(imageData.count) bytes")
                    
                    // Ensure ProductImage entity exists
                    if product.productImage == nil {
                        print("ProductImageView: Creating new ProductImage entity")
                        let newProductImage = ProductImage(context: product.managedObjectContext!)
                        newProductImage.id = UUID().uuidString
                        newProductImage.createdAt = Date()
                        newProductImage.updatedAt = Date()
                        product.productImage = newProductImage
                    }
                    
                    // Update the product's image data
                    product.productImage?.imageData = imageData
                    product.productImage?.imageURL = nil // Clear URL since we have local data
                    product.productImage?.updatedAt = Date()
                    
                    // Save to Core Data
                    do {
                        try product.managedObjectContext?.save()
                        print("User image saved successfully to Core Data")
                        
                        // Force UI update
                        imageUpdateTrigger.toggle()
                        print("ProductImageView: Triggered UI update")
                    } catch {
                        print("Error saving user image: \(error)")
                    }
                } else {
                    print("ProductImageView: Failed to create JPEG data")
                }
            }
        }
    }
} 