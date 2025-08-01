//
//  CoreDataContainer.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/7/25.
//

import Foundation
import CoreData
import SwiftUI

protocol CoreDataContainerProtocol: Sendable {
    func fetchAllProducts() async throws -> [GroceryItem]
    func fetchListProducts() async throws -> [GroceryItem]
    // func fetchRecentProducts(limit: Int) async throws -> [GroceryItem]
    func createProduct(id: String, productName: String, brand: String?, category: String?, price: Double, currency: String, store: String?, location: String?, imageURL: String?, barcode: String?, isInShoppingList: Bool, isOnSale: Bool) async throws -> GroceryItem
    func updateProduct(_ product: GroceryItem) async throws
    func deleteProduct(_ product: GroceryItem) async throws
    func toggleProductCompletion(_ product: GroceryItem) async throws
    func addProductToShoppingList(_ product: GroceryItem) async throws
    func fetchFavoriteProducts() async throws -> [GroceryItem]
    func addProductToFavorites(_ product: GroceryItem) async throws
    func removeProductFromFavorites(_ product: GroceryItem) async throws
    func toggleProductFavorite(_ product: GroceryItem) async throws
    func searchProducts(by name: String) async throws -> [GroceryItem]
    func removeProductFromShoppingList(_ product: GroceryItem) async throws
    
    // Tag-related methods
    func fetchAllTags() async throws -> [Tag]
    func createTag(id: String, name: String, color: String) async throws -> Tag
    func updateTag(_ tag: Tag) async throws
    func addTagsToProduct(_ product: GroceryItem, tags: [Tag]) async throws
    func removeTagsFromProduct(_ product: GroceryItem, tags: [Tag]) async throws
    func initializeDefaultTags() async throws
    

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
            let products = try context.fetch(request)
            
            print("CoreDataContainer: Fetched \(products.count) shopping list products")
            for (index, product) in products.enumerated() {
                print("CoreDataContainer: Product \(index + 1): '\(product.productName ?? "Unknown")' - Store: '\(product.store ?? "nil")' - Price: $\(product.price)")
            }
            
            return products
        }
    }
    
    // func fetchRecentProducts(limit: Int) async throws -> [GroceryItem] {
    //     // Use viewContext through the actor
    //     let context = await coreDataStack.viewContext
    //     return try await context.perform {
    //         let request: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
    //     // Get all products (not just shopping list) sorted by creation date
    //         request.sortDescriptors = [NSSortDescriptor(keyPath: \GroceryItem.createdAt, ascending: false)]
    //         request.fetchLimit = limit
    //         return try context.fetch(request)
    //     }
    // }
    
    // createProduct was creating GroceryItem objects in background Core Data context, but ViewModel expecting objects from main context.
    func createProduct(id: String, productName: String, brand: String?, category: String?, price: Double, currency: String, store: String?, location: String?, imageURL: String?, barcode: String?, isInShoppingList: Bool = false, isOnSale: Bool = false) async throws -> GroceryItem {
        print("CoreDataContainer: Creating product with store: '\(store ?? "nil")'")
        
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
                barcode: barcode,
                isOnSale: isOnSale
            )
            
            print("CoreDataContainer: Product created, store set to: '\(product.store ?? "nil")'")
            
            // Set shopping list status based on parameter
            product.isInShoppingList = isInShoppingList
            
            try context.save()
            print("CoreDataContainer: Context saved, final store: '\(product.store ?? "nil")'")
            return product.objectID
        }
        
        // Then fetch from main context to ensure proper access
        let viewContext = await coreDataStack.viewContext
        return try await viewContext.perform {
            let fetchedProduct = try viewContext.existingObject(with: objectID) as! GroceryItem
            print("CoreDataContainer: Fetched product from main context, store: '\(fetchedProduct.store ?? "nil")'")
            return fetchedProduct
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
            
            // Remove tag relationships before deletion
            // tags property defined as NSSet, which is immutable (read-only)
            // and removeAllObjects() is a method that only exists on NSMutableSet (mutable)
            productInContext.tags = NSSet()
            
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
    
    func fetchFavoriteProducts() async throws -> [GroceryItem] {
        // Use viewContext through the actor
        let context = await coreDataStack.viewContext
        return try await context.perform {
            let request: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
            request.predicate = NSPredicate(format: "isFavorite == YES")
            request.sortDescriptors = [NSSortDescriptor(keyPath: \GroceryItem.createdAt, ascending: false)]
            return try context.fetch(request)
        }
    }
    
    func addProductToFavorites(_ product: GroceryItem) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let objectID = product.objectID
            let productInContext = try context.existingObject(with: objectID) as! GroceryItem
            productInContext.isFavorite = true
            try context.save()
        }
    }
    
    func removeProductFromFavorites(_ product: GroceryItem) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let objectID = product.objectID
            let productInContext = try context.existingObject(with: objectID) as! GroceryItem
            productInContext.isFavorite = false
            try context.save()
        }
    }
    
    func toggleProductFavorite(_ product: GroceryItem) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let objectID = product.objectID
            let productInContext = try context.existingObject(with: objectID) as! GroceryItem
            productInContext.isFavorite.toggle()
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
    
    // MARK: - Tag Methods
    
    func fetchAllTags() async throws -> [Tag] {
        // Ensure tags are seeded before fetching
        try await coreDataStack.ensureTagsSeeded()
        
        let context = await coreDataStack.viewContext
        return try await context.perform {
            let request: NSFetchRequest<Tag> = Tag.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Tag.name, ascending: true)]
            return try context.fetch(request)
        }
    }
    
    func createTag(id: String, name: String, color: String) async throws -> Tag {
        let objectID = try await coreDataStack.performBackgroundTask { context in
            let tag = Tag(context: context, id: id, name: name, color: color)
            try context.save()
            return tag.objectID
        }
        
        let viewContext = await coreDataStack.viewContext
        return try await viewContext.perform {
            return try viewContext.existingObject(with: objectID) as! Tag
        }
    }
    
    func updateTag(_ tag: Tag) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let objectID = tag.objectID
            let tagInContext = try context.existingObject(with: objectID) as! Tag
            tagInContext.updatedAt = Date()
            try context.save()
        }
    }
    
    func addTagsToProduct(_ product: GroceryItem, tags: [Tag]) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let objectID = product.objectID
            let productInContext = try context.existingObject(with: objectID) as! GroceryItem
            
            // Get the tags in the current context
            let tagObjectIDs = tags.map { $0.objectID }
            let tagsInContext = try tagObjectIDs.map { try context.existingObject(with: $0) as! Tag }
            
            // Add tags to product
            let currentTags = productInContext.tags as? Set<Tag> ?? Set()
            let newTags = currentTags.union(Set(tagsInContext))
            productInContext.tags = NSSet(set: newTags)
            
            try context.save()
        }
    }
    
    func removeTagsFromProduct(_ product: GroceryItem, tags: [Tag]) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let objectID = product.objectID
            let productInContext = try context.existingObject(with: objectID) as! GroceryItem
            
            // Get the tags in the current context
            let tagObjectIDs = tags.map { $0.objectID }
            let tagsInContext = try tagObjectIDs.map { try context.existingObject(with: $0) as! Tag }
            
            // Remove tags from product
            let currentTags = productInContext.tags as? Set<Tag> ?? Set()
            let newTags = currentTags.subtracting(Set(tagsInContext))
            productInContext.tags = NSSet(set: newTags)
            
            try context.save()
        }
    }
    
    func initializeDefaultTags() async throws {
        // Use the new seeded data approach
        try await coreDataStack.performBackgroundTask { context in
            try TagSeedData.seedTags(in: context)
        }
    }
    

} 