//
//  CoreDataContainer.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/7/25.
//

import Foundation
import CoreData

protocol CoreDataContainerProtocol: Sendable {
    func fetchAllProducts() async throws -> [GroceryItem]
    func fetchListProducts() async throws -> [GroceryItem]
    func fetchRecentProducts(limit: Int) async throws -> [GroceryItem]
    func createProduct(id: String, productName: String, brand: String?, category: String?, price: Double, currency: String, store: String?, location: String?, imageURL: String?, barcode: String?) async throws -> GroceryItem
    func updateProduct(_ product: GroceryItem) async throws
    func deleteProduct(_ product: GroceryItem) async throws
    func toggleProductCompletion(_ product: GroceryItem) async throws
    func addProductToShoppingList(_ product: GroceryItem) async throws
    func searchProducts(by name: String) async throws -> [GroceryItem]
    func removeProductFromShoppingList(_ product: GroceryItem) async throws
}

final class CoreDataContainer: CoreDataContainerProtocol, @unchecked Sendable {
    private let coreDataStack: CoreDataStack
    
    init(coreDataStack: CoreDataStack = CoreDataStack.shared) {
        self.coreDataStack = coreDataStack
    }
    
    func fetchAllProducts() async throws -> [GroceryItem] {
        // Use viewContext through the actor
        let context = await coreDataStack.viewContext
        return try await context.perform {
            let request: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \GroceryItem.createdAt, ascending: false)]
            return try context.fetch(request)
        }
    }
    
    func fetchListProducts() async throws -> [GroceryItem] {
        // Use viewContext through the actor
        let context = await coreDataStack.viewContext
        return try await context.perform {
            let request: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
            request.predicate = NSPredicate(format: "isInShoppingList == YES")
            request.sortDescriptors = [NSSortDescriptor(keyPath: \GroceryItem.createdAt, ascending: false)]
            return try context.fetch(request)
        }
    }
    
    func fetchRecentProducts(limit: Int) async throws -> [GroceryItem] {
        // Use viewContext through the actor
        let context = await coreDataStack.viewContext
        return try await context.perform {
            let request: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
            // Get all products (not just shopping list) sorted by creation date
            request.sortDescriptors = [NSSortDescriptor(keyPath: \GroceryItem.createdAt, ascending: false)]
            request.fetchLimit = limit
            return try context.fetch(request)
        }
    }
    
    // createProduct was creating GroceryItem objects in background Core Data context, but ViewModel expecting objects from main context.
    func createProduct(id: String, productName: String, brand: String?, category: String?, price: Double, currency: String, store: String?, location: String?, imageURL: String?, barcode: String?) async throws -> GroceryItem {
        // Create in background context first
        let objectID = try await coreDataStack.performBackgroundTask { context in
            let product = GroceryItem(
                context: context,
                id: id,
                productName: productName,
                brand: brand,
                category: category,
                price: price,
                currency: currency,
                store: store,
                location: location,
                imageURL: imageURL,
                barcode: barcode
            )
            
            // Don't add to shopping list by default - only when user explicitly adds
            product.isInShoppingList = false
            
            try context.save()
            return product.objectID
        }
        
        // Then fetch from main context to ensure proper access
        let viewContext = await coreDataStack.viewContext
        return try await viewContext.perform {
            return try viewContext.existingObject(with: objectID) as! GroceryItem
        }
    }
    
    func updateProduct(_ product: GroceryItem) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let objectID = product.objectID
            let productInContext = try context.existingObject(with: objectID) as! GroceryItem
            productInContext.updatedAt = Date()
            try context.save()
        }
    }
    
    func deleteProduct(_ product: GroceryItem) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let objectID = product.objectID
            let productInContext = try context.existingObject(with: objectID) as! GroceryItem
            context.delete(productInContext)
            try context.save()
        }
    }
    
    func removeProductFromShoppingList(_ product: GroceryItem) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let objectID = product.objectID
            let productInContext = try context.existingObject(with: objectID) as! GroceryItem
            productInContext.isInShoppingList = false
            try context.save()
        }
    }
    
    func toggleProductCompletion(_ product: GroceryItem) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let objectID = product.objectID
            let productInContext = try context.existingObject(with: objectID) as! GroceryItem
            productInContext.isCompleted.toggle()
            try context.save()
        }
    }
    
    func addProductToShoppingList(_ product: GroceryItem) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let objectID = product.objectID
            let productInContext = try context.existingObject(with: objectID) as! GroceryItem
            productInContext.isInShoppingList = true
            productInContext.isCompleted = false // Reset completion status when adding to list
            try context.save()
        }
    }
    
    func searchProducts(by name: String) async throws -> [GroceryItem] {
        // Use viewContext through the actor
        let context = await coreDataStack.viewContext
        return try await context.perform {
            let request: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
            request.predicate = NSPredicate(format: "productName CONTAINS[cd] %@", name)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \GroceryItem.productName, ascending: true)]
            return try context.fetch(request)
        }
    }
} 