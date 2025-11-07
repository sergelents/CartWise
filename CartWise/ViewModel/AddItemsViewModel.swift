//
//  AddItemsViewModel.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 11/7/25.
//
import SwiftUI
import Combine
import CoreData
import Foundation

@MainActor
final class AddItemsViewModel: ObservableObject {
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
    
    // MARK: - Product Creation
    
    func createProductForShoppingList(
        byName name: String,
        brand: String? = nil,
        category: String? = nil,
        isOnSale: Bool = false
    ) async -> GroceryItem? {
        do {
            if await isDuplicateProduct(name: name) {
                errorMessage = "Product '\(name)' already exists in your list"
                return nil
            }
            let id = UUID().uuidString
            // Capture the created product to fetch its image
            let savedProduct = try await repository.createProduct(
                id: id,
                productName: name,
                brand: brand,
                category: category,
                price: 0.0, // Default price - will be stored in GroceryItemPrice if > 0
                currency: "USD",
                store: nil,
                location: nil,
                imageURL: nil,
                barcode: nil,
                isInShoppingList: true,
                isOnSale: isOnSale
            )
            
            // Fetch image for the newly created product
            await fetchImageForProduct(savedProduct)
            
            errorMessage = nil
            return savedProduct
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
    
    // MARK: - Barcode Operations
    
    func searchProductsByBarcode(_ barcode: String) async throws -> [GroceryItem] {
        return try await repository.searchProductsByBarcode(barcode)
    }
    
    func createProductByBarcode(
        barcode: String,
        productName: String,
        brand: String?,
        category: String?,
        price: Double,
        store: String,
        isOnSale: Bool = false
    ) async -> GroceryItem? {
        do {
            print("AddItemsViewModel: Creating product with barcode: \(barcode)")
            print("AddItemsViewModel: Store value: '\(store)'")
            
            // Check if product already exists with this barcode
            if await isDuplicateBarcode(barcode) {
                errorMessage = "Product with barcode '\(barcode)' already exists"
                return nil
            }
            
            let id = UUID().uuidString
            // Capture the created product to fetch its image
            let savedProduct = try await repository.createProduct(
                id: id,
                productName: productName,
                brand: brand,
                category: category,
                price: price,
                currency: "USD",
                store: store, // Set store for price comparison
                location: nil,
                imageURL: nil,
                barcode: barcode,
                isInShoppingList: false, // Don't automatically add to shopping list
                isOnSale: isOnSale
            )
            
            print("AddItemsViewModel: Product created successfully")
            print("AddItemsViewModel: Saved product store: '\(savedProduct.store ?? "nil")'")
            
            // Fetch image for the newly created product
            await fetchImageForProduct(savedProduct)
            
            errorMessage = nil
            return savedProduct
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
    
    func updateProductByBarcode(
        barcode: String,
        productName: String?,
        brand: String?,
        category: String?,
        price: Double?,
        store: String?,
        isOnSale: Bool?
    ) async -> GroceryItem? {
        do {
            print("AddItemsViewModel: Updating product with barcode: \(barcode)")
            print("AddItemsViewModel: Update store value: '\(store ?? "nil")'")
            
            let existingProducts = try await repository.searchProductsByBarcode(barcode)
            guard let existingProduct = existingProducts.first(
                where: { $0.barcode?.lowercased() == barcode.lowercased() }) else {
                // This should not happen if we checked isDuplicateBarcode first
                // But handle gracefully just in case
                errorMessage = "Unable to update product with barcode '\(barcode)' - product not found in database"
                return nil
            }
            
            print("AddItemsViewModel: Found existing product, current store: '\(existingProduct.store ?? "nil")'")
            
            // Update only provided values
            if let productName = productName {
                existingProduct.productName = productName
            }
            if let brand = brand {
                existingProduct.brand = brand
            }
            if let category = category {
                existingProduct.category = category
            }
            if let isOnSale = isOnSale {
                existingProduct.isOnSale = isOnSale
            }
            
            // Handle price and store updates
            if let price = price, let store = store, price > 0 {
                try await repository.updateProductWithPrice(
                    product: existingProduct,
                    price: price,
                    store: store,
                    location: nil
                )
            } else {
                // Just update the product without price changes
                try await repository.updateProduct(existingProduct)
            }
            
            print("AddItemsViewModel: Product updated successfully")
            print("AddItemsViewModel: Final product store: '\(existingProduct.store ?? "nil")'")
            
            errorMessage = nil
            return existingProduct
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
    
    // MARK: - Duplicate Checking
    
    func isDuplicateProduct(name: String) async -> Bool {
        do {
            let existingProducts = try await repository.searchProducts(by: name)
            return existingProducts.contains { product in
                product.productName?.lowercased() == name.lowercased()
            }
        } catch {
            return false // If search fails, allow creation
        }
    }
    
    func isProductInShoppingList(name: String) async -> Bool {
        do {
            // Only check shopping list products, not all products
            let shoppingListProducts = try await repository.fetchListProducts()
            return shoppingListProducts.contains { product in
                product.productName?.lowercased() == name.lowercased()
            }
        } catch {
            return false // If search fails, allow adding
        }
    }
    
    func isDuplicateBarcode(_ barcode: String) async -> Bool {
        do {
            let existingProducts = try await repository.searchProductsByBarcode(barcode)
            return existingProducts.contains { product in
                product.barcode?.lowercased() == barcode.lowercased()
            }
        } catch {
            return false // If search fails, allow creation
        }
    }
    
    // MARK: - Post-Creation Operations
    
    func addTagsToProduct(_ product: GroceryItem, tags: [Tag]) async {
        do {
            try await repository.addTagsToProduct(product, tags: tags)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func replaceTagsForProduct(_ product: GroceryItem, tags: [Tag]) async {
        do {
            try await repository.replaceTagsForProduct(product, tags: tags)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func addExistingProductToShoppingList(_ product: GroceryItem) async {
        do {
            try await repository.addProductToShoppingList(product)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Image Fetching
    
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
                    } catch {
                        print("AddItemsViewModel: Error saving image data: \(error.localizedDescription)")
                    }
                }
            }
        } catch {
            print("AddItemsViewModel: Error fetching image for '\(product.productName ?? "")': " +
                  "\(error.localizedDescription)")
        }
    }
}

