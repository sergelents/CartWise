//
//  CoreDataContainer.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/7/25.
//

import Foundation
import CoreData

protocol CoreDataContainerProtocol: Sendable {
    func fetchAllProducts() async throws -> [Product]
    func createProduct(barcode: String, name: String, brands: String?, imageURL: String?, nutritionGrade: String?, categories: String?, ingredients: String?) async throws -> Product
    func createProduct(name: String) async throws -> Product
    func updateProduct(_ product: Product) async throws
    func deleteProduct(_ product: Product) async throws
    func toggleProductCompletion(_ product: Product) async throws
    func addProductToShoppingList(_ product: Product) async throws
    func searchProducts(by name: String) async throws -> [Product]
}

final class CoreDataContainer: CoreDataContainerProtocol, @unchecked Sendable {
    private let coreDataStack: CoreDataStack
    
    init(coreDataStack: CoreDataStack = CoreDataStack.shared) {
        self.coreDataStack = coreDataStack
    }
    
    func fetchAllProducts() async throws -> [Product] {
        // Use viewContext through the actor
        let context = await coreDataStack.viewContext
        return try await context.perform {
            let request: NSFetchRequest<Product> = Product.fetchRequest()
            request.predicate = NSPredicate(format: "isInShoppingList == YES")
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Product.createdAt, ascending: false)]
            return try context.fetch(request)
        }
    }
    
    func createProduct(barcode: String, name: String, brands: String?, imageURL: String?, nutritionGrade: String?, categories: String?, ingredients: String?) async throws -> Product {
        try await coreDataStack.performBackgroundTask { context in
            print("DEBUG: CoreDataContainer - Creating product with name: '\(name)', barcode: '\(barcode)'")
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
            
            print("DEBUG: CoreDataContainer - Product created, name: '\(product.name ?? "nil")', barcode: '\(product.barcode ?? "nil")'")
            try context.save()
            print("DEBUG: CoreDataContainer - Context saved successfully")
            return product
        }
    }
    
    func createProduct(name: String) async throws -> Product {
        try await coreDataStack.performBackgroundTask { context in
            let product = Product(
                context: context,
                barcode: UUID().uuidString, // Generate a unique identifier
                name: name,
                brands: nil,
                imageURL: nil,
                nutritionGrade: nil,
                categories: nil,
                ingredients: nil
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
            let productInContext = try context.existingObject(with: objectID) as! Product
            productInContext.isInShoppingList = false
            try context.save()
        }
    }
    
    func toggleProductCompletion(_ product: Product) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let objectID = product.objectID
            let productInContext = try context.existingObject(with: objectID) as! Product
            productInContext.isCompleted.toggle()
            try context.save()
        }
    }
    
    func addProductToShoppingList(_ product: Product) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let objectID = product.objectID
            let productInContext = try context.existingObject(with: objectID) as! Product
            productInContext.isInShoppingList = true
            productInContext.isCompleted = false // Reset completion status when adding to list
            try context.save()
        }
    }
    
    func searchProducts(by name: String) async throws -> [Product] {
        // Use viewContext through the actor
        let context = await coreDataStack.viewContext
        return try await context.perform {
            let request: NSFetchRequest<Product> = Product.fetchRequest()
            request.predicate = NSPredicate(format: "name CONTAINS[cd] %@", name)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Product.name, ascending: true)]
            return try context.fetch(request)
        }
    }
} 