//
//  SearchViewModel.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 11/7/25.
//
import SwiftUI
import Combine
import CoreData
import Foundation

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var products: [GroceryItem] = []
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
    
    // MARK: - Product Loading
    
    func loadProducts() async {
        do {
            products = try await repository.fetchAllProducts()
            // Fetch images for products that don't have them
            await fetchImagesForProducts()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // Fetch all products without mutating the published `products` array
    // Useful for views that need a read-only snapshot without triggering UI-wide reloads
    func fetchAllProducts() async -> [GroceryItem] {
        do {
            return try await repository.fetchAllProducts()
        } catch {
            // Surface the error but do not mutate state; return an empty list on failure
            errorMessage = error.localizedDescription
            return []
        }
    }
    
    // MARK: - Search Operations
    
    func searchProducts(by name: String) async {
        do {
            products = try await repository.searchProducts(by: name)
            // Fetch images for search results
            await fetchImagesForProducts()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // Search without mutating the published `products` array
    func searchProductsQuiet(by name: String) async -> [GroceryItem] {
        do {
            return try await repository.searchProducts(by: name)
        } catch {
            errorMessage = error.localizedDescription
            return []
        }
    }
    
    // MARK: - Add to Shopping List
    
    func addExistingProductToShoppingList(_ product: GroceryItem) async {
        do {
            try await repository.addProductToShoppingList(product)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // Quiet version that doesn't reload lists - for UI components
    func addExistingProductToShoppingListQuiet(_ product: GroceryItem) async {
        do {
            try await repository.addProductToShoppingList(product)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Helper Methods
    
    func clearSearch() {
        products = []
    }
    
    func filterProductsByCategory(_ category: String) -> [GroceryItem] {
        guard !category.isEmpty else { return products }
        return products.filter { $0.category?.lowercased() == category.lowercased() }
    }
    
    func filterProductsByBrand(_ brand: String) -> [GroceryItem] {
        guard !brand.isEmpty else { return products }
        return products.filter { $0.brand?.lowercased() == brand.lowercased() }
    }
    
    func sortProductsByName(ascending: Bool = true) -> [GroceryItem] {
        return products.sorted { product1, product2 in
            let name1 = product1.productName?.lowercased() ?? ""
            let name2 = product2.productName?.lowercased() ?? ""
            return ascending ? name1 < name2 : name1 > name2
        }
    }
    
    func sortProductsByPrice(ascending: Bool = true) -> [GroceryItem] {
        return products.sorted { product1, product2 in
            return ascending ? product1.price < product2.price : product1.price > product2.price
        }
    }
    
    // MARK: - Image Fetching
    
    private func fetchImagesForProducts() async {
        await fetchImagesForProductArray(products)
    }
    
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
                        print("SearchViewModel: Error saving image data: \(error.localizedDescription)")
                    }
                }
            }
        } catch {
            print("SearchViewModel: Error fetching image for '\(product.productName ?? "")': " +
                  "\(error.localizedDescription)")
        }
    }
}

