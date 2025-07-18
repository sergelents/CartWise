//
//  CoreDataContainer.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/7/25.
//  Updated by Brenna Wilson on 7/17/25 -7/18/25
//

import Foundation
import CoreData

protocol CoreDataContainerProtocol: Sendable {
    func fetchAllProducts() async throws -> [Product]
    func fetchListProducts() async throws -> [Product]
    func fetchRecentProducts(limit: Int) async throws -> [Product]
    func createProduct(barcode: String, name: String, brands: String?, imageURL: String?, nutritionGrade: String?, categories: String?, ingredients: String?) async throws -> Product
    func updateProduct(_ product: Product) async throws
    func deleteProduct(_ product: Product) async throws
    func toggleProductCompletion(_ product: Product) async throws
    func addProductToShoppingList(_ product: Product) async throws
    func searchProducts(by name: String) async throws -> [Product]
    func removeProductFromShoppingList(_ product: Product) async throws
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
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Product.createdAt, ascending: false)]
            return try context.fetch(request)
        }
    }
    
    func fetchListProducts() async throws -> [Product] {
        // Use viewContext through the actor
        let context = await coreDataStack.viewContext
        return try await context.perform {
            let request: NSFetchRequest<Product> = Product.fetchRequest()
            request.predicate = NSPredicate(format: "isInShoppingList == YES")
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Product.createdAt, ascending: false)]
            return try context.fetch(request)
        }
    }
    
    func fetchRecentProducts(limit: Int) async throws -> [Product] {
        // Use viewContext through the actor
        let context = await coreDataStack.viewContext
        return try await context.perform {
            let request: NSFetchRequest<Product> = Product.fetchRequest()
            // Get all products (not just shopping list) sorted by creation date
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Product.createdAt, ascending: false)]
            request.fetchLimit = limit
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
            let productInContext = try context.existingObject(with: objectID) as! Product
            context.delete(productInContext)
            try context.save()
        }
    }
    
    func removeProductFromShoppingList(_ product: Product) async throws {
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