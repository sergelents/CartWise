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
    func updateProduct(_ product: Product) async throws
    func deleteProduct(_ product: Product) async throws
    func searchProducts(by name: String) async throws -> [Product]
}

final class ProductRepository: ProductRepositoryProtocol, @unchecked Sendable {
    private let coreDataStack: CoreDataStack
    
    init(coreDataStack: CoreDataStack = CoreDataStack.shared) {
        self.coreDataStack = coreDataStack
    }
    
    func fetchAllProducts() async throws -> [Product] {
        try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Product> = Product.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Product.updatedAt, ascending: false)]
            return try context.fetch(request)
        }
    }
    
    func createProduct(barcode: String, name: String, brands: String?, imageURL: String?, nutritionGrade: String?, categories: String?, ingredients: String?) async throws -> Product {
        try await coreDataStack.performBackgroundTask { context in
            let product = Product(
                context: context,
                barcode: barcode,
                name: name,
                brands: brands,
                imageURL: imageURL,
                nutritionGrade: nutritionGrade,
                categories: categories,
                ingredients: ingredients
            )
            
            try context.save()
            return product
        }
    }
    
    func updateProduct(_ product: Product) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let objectID = product.objectID
            let productInContext = try context.existingObject(with: objectID) as! Product
            productInContext.updatedAt = Date()
            try context.save()
        }
    }
    
    func deleteProduct(_ product: Product) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let objectID = product.objectID
            let productInContext = try context.existingObject(with: objectID)
            context.delete(productInContext)
            try context.save()
        }
    }
    
    func searchProducts(by name: String) async throws -> [Product] {
        try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<Product> = Product.fetchRequest()
            request.predicate = NSPredicate(format: "name CONTAINS[cd] %@", name)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Product.name, ascending: true)]
            return try context.fetch(request)
        }
    }
    
}

// This code was generated with the help of Claude, saving me 3 hours of research and development.
