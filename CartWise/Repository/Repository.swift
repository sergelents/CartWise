//
//  Repository.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/7/25.
//

import Foundation
import CoreData

protocol ProductRepositoryProtocol: Sendable {
    func fetchAllProducts() async throws -> [Product]
    func fetchRecentProducts(limit: Int) async throws -> [Product]
    func createProduct(barcode: String, name: String, brands: String?, imageURL: String?, nutritionGrade: String?, categories: String?, ingredients: String?) async throws -> Product
    func createProduct(name: String) async throws -> Product
    func updateProduct(_ product: Product) async throws
    func deleteProduct(_ product: Product) async throws
    func toggleProductCompletion(_ product: Product) async throws
    func addProductToShoppingList(_ product: Product) async throws
    func searchProducts(by name: String) async throws -> [Product]
    func fetchProductFromNetwork(by barcode: String) async throws -> Product?
}

final class ProductRepository: ProductRepositoryProtocol, @unchecked Sendable {
    private let coreDataContainer: CoreDataContainerProtocol
    private let networkService: NetworkServiceProtocol
    
    init(coreDataContainer: CoreDataContainerProtocol = CoreDataContainer(),
         networkService: NetworkServiceProtocol = NetworkService()) {
        self.coreDataContainer = coreDataContainer
        self.networkService = networkService
    }
    
    // MARK: - Cache-First Operations
    
    func fetchAllProducts() async throws -> [Product] {
        // Cache-first: return local data immediately
        return try await coreDataContainer.fetchAllProducts()
    }
    
    func fetchRecentProducts(limit: Int) async throws -> [Product] {
        // Cache-first: return local data immediately
        return try await coreDataContainer.fetchRecentProducts(limit: limit)
    }
    
    func createProduct(barcode: String, name: String, brands: String?, imageURL: String?, nutritionGrade: String?, categories: String?, ingredients: String?) async throws -> Product {
        // Create locally first
        return try await coreDataContainer.createProduct(
            barcode: barcode,
            name: name,
            brands: brands,
            imageURL: imageURL,
            nutritionGrade: nutritionGrade,
            categories: categories,
            ingredients: ingredients
        )
    }
    
    func createProduct(name: String) async throws -> Product {
        // Create locally with generated barcode
        return try await coreDataContainer.createProduct(name: name)
    }
    
    func updateProduct(_ product: Product) async throws {
        // Update local cache
        try await coreDataContainer.updateProduct(product)
    }
    
    func deleteProduct(_ product: Product) async throws {
        // Delete from local cache
        try await coreDataContainer.deleteProduct(product)
    }
    
    func toggleProductCompletion(_ product: Product) async throws {
        // Toggle completion status
        try await coreDataContainer.toggleProductCompletion(product)
    }
    
    func addProductToShoppingList(_ product: Product) async throws {
        // Add existing product to shopping list
        try await coreDataContainer.addProductToShoppingList(product)
    }
    
    func searchProducts(by name: String) async throws -> [Product] {
        // Local-only search for now
        return try await coreDataContainer.searchProducts(by: name)
    }
    
    // MARK: - Network Operations
    
    func fetchProductFromNetwork(by barcode: String) async throws -> Product? {
        // Check cache first
        let existingProducts = try await coreDataContainer.fetchAllProducts()
        if let existingProduct = existingProducts.first(where: { $0.barcode == barcode }) {
            return existingProduct
        }
        
        // Network-second: fetch from API with retry logic
        do {
            let networkProduct = try await networkService.fetchProductWithRetry(by: barcode, retries: 3)
            
            guard let networkProduct = networkProduct else {
                return nil
            }
            
            // Save to local cache
            let savedProduct = try await createProduct(
                barcode: networkProduct.code,
                name: networkProduct.productName ?? "Unknown Product",
                brands: networkProduct.brands,
                imageURL: networkProduct.imageURL,
                nutritionGrade: networkProduct.nutritionGrades,
                categories: networkProduct.categories,
                ingredients: networkProduct.ingredients?.map { $0.text }.joined(separator: ", ")
            )
            
            return savedProduct
        } catch NetworkError.productNotFound {
            // Product not found in API, return nil
            return nil
        } catch NetworkError.rateLimitExceeded {
            // Rate limited, return nil but could implement queue for later retry
            return nil
        } catch {
            // Other network errors, re-throw
            throw error
        }
    }
}

// This code was generated with the help of Claude, saving me 3 hours of research and development.
