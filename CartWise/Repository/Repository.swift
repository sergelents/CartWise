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
    func createProduct(barcode: String, name: String, brands: String?, imageURL: String?, nutritionGrade: String?, categories: String?, ingredients: String?) async throws -> Product
    func createProduct(name: String) async throws -> Product
    func updateProduct(_ product: Product) async throws
    func deleteProduct(_ product: Product) async throws
    func searchProducts(by name: String) async throws -> [Product]
}

final class ProductRepository: ProductRepositoryProtocol, @unchecked Sendable {
    private let coreDataContainer: CoreDataContainerProtocol
    
    init(coreDataContainer: CoreDataContainerProtocol = CoreDataContainer()) {
        self.coreDataContainer = coreDataContainer
    }
    
    func fetchAllProducts() async throws -> [Product] {
        try await coreDataContainer.fetchAllProducts()
    }
    
    func createProduct(barcode: String, name: String, brands: String?, imageURL: String?, nutritionGrade: String?, categories: String?, ingredients: String?) async throws -> Product {
        try await coreDataContainer.createProduct(
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
        try await coreDataContainer.createProduct(name: name)
    }
    
    func updateProduct(_ product: Product) async throws {
        try await coreDataContainer.updateProduct(product)
    }
    
    func deleteProduct(_ product: Product) async throws {
        try await coreDataContainer.deleteProduct(product)
    }
    
    func searchProducts(by name: String) async throws -> [Product] {
        try await coreDataContainer.searchProducts(by: name)
    }
}

// This code was generated with the help of Claude, saving me 3 hours of research and development.
