//
//  ProfileViewModel.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 11/7/25.
//
import SwiftUI
import Combine
import CoreData
import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var favoriteProducts: [GroceryItem] = []
    @Published var recentProducts: [GroceryItem] = []
    @Published var errorMessage: String?
    
    private let repository: ProductRepositoryProtocol
    private let imageService: ImageServiceProtocol
    
    init(
        repository: ProductRepositoryProtocol,
        imageService: ImageServiceProtocol = ImageService()
    ) {
        self.repository = repository
        self.imageService = imageService
    }
    
    // MARK: - Favorites Management
    
    func loadFavoriteProducts() async {
        do {
            favoriteProducts = try await repository.fetchFavoriteProducts()
            
            // Fetch images for favorite products that don't have them
            await fetchImagesForProductArray(favoriteProducts)
            
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func addProductToFavorites(_ product: GroceryItem) async {
        do {
            try await repository.addProductToFavorites(product)
            await loadFavoriteProducts()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // Quiet version that doesn't reload lists - for UI components
    func addProductToFavoritesQuiet(_ product: GroceryItem) async {
        do {
            try await repository.addProductToFavorites(product)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func removeProductFromFavorites(_ product: GroceryItem) async {
        do {
            try await repository.removeProductFromFavorites(product)
            await loadFavoriteProducts()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // Quiet version that doesn't reload lists - for UI components
    func removeProductFromFavoritesQuiet(_ product: GroceryItem) async {
        do {
            try await repository.removeProductFromFavorites(product)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func toggleProductFavorite(_ product: GroceryItem) async {
        do {
            try await repository.toggleProductFavorite(product)
            await loadFavoriteProducts()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func isProductInFavorites(_ product: GroceryItem) async -> Bool {
        do {
            let favorites = try await repository.fetchFavoriteProducts()
            return favorites.contains { favorite in
                favorite.id == product.id
            }
        } catch {
            return false
        }
    }
    
    // MARK: - Helper Methods
    
    func getFavoritesCount() -> Int {
        return favoriteProducts.count
    }
    
    func sortFavoritesByName(ascending: Bool = true) -> [GroceryItem] {
        return favoriteProducts.sorted { product1, product2 in
            let name1 = product1.productName?.lowercased() ?? ""
            let name2 = product2.productName?.lowercased() ?? ""
            return ascending ? name1 < name2 : name1 > name2
        }
    }
    
    func sortFavoritesByDateAdded(ascending: Bool = false) -> [GroceryItem] {
        return favoriteProducts.sorted { product1, product2 in
            let date1 = product1.createdAt ?? Date.distantPast
            let date2 = product2.createdAt ?? Date.distantPast
            return ascending ? date1 < date2 : date1 > date2
        }
    }
    
    func filterFavoritesByCategory(_ category: String) -> [GroceryItem] {
        guard !category.isEmpty else { return favoriteProducts }
        return favoriteProducts.filter { $0.category?.lowercased() == category.lowercased() }
    }
    
    func clearAllFavorites() async {
        do {
            for product in favoriteProducts {
                try await repository.removeProductFromFavorites(product)
            }
            favoriteProducts = []
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Image Fetching
    
    private func fetchImagesForProductArray(_ productArray: [GroceryItem]) async {
        // Get products that don't have image URLs
        let productsWithoutImages = productArray.filter { $0.imageURL == nil || $0.imageURL?.isEmpty == true }
        
        if productsWithoutImages.isEmpty {
            return
        }
        
        // Fetch images for each product
        for product in productsWithoutImages {
            await fetchImageForProduct(product)
        }
    }
    
    private func fetchImageForProduct(_ product: GroceryItem) async {
        do {
            let productName = product.productName ?? ""
            let brand = product.brand
            let category = product.category
            
            if let imageURL = try await imageService.fetchImageURL(for: productName, brand: brand, category: category) {
                // Download image data
                if let url = URL(string: imageURL) {
                    let (imageData, _) = try await URLSession.shared.data(from: url)
                    
                    // Save image to Core Data using new ProductImage entity
                    do {
                        try await repository.saveProductImage(
                            for: product,
                            imageURL: imageURL,
                            imageData: imageData
                        )
                        // Force a UI update by triggering objectWillChange
                        objectWillChange.send()
                    } catch {
                        print("ProfileViewModel: Error saving image data: \(error.localizedDescription)")
                    }
                }
            }
        } catch {
            print("ProfileViewModel: Error fetching image for '\(product.productName ?? "")': " +
                  "\(error.localizedDescription)")
        }
    }
}

