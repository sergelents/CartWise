//
//  CoreDataStack.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/7/25.
//

import CoreData
import Foundation


actor CoreDataStack {
    static let shared = CoreDataStack()
    
    private init() {}
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "ProductModel")
        
        // Configure migration options
        let description = container.persistentStoreDescriptions.first
        description?.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        description?.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        
        // Load persistent stores
        container.loadPersistentStores { _, error in
            if let error = error {
                print("Core Data failed to load: \(error.localizedDescription)")
                // Instead of fatal error, try to delete and recreate
                self.handleCoreDataError(error)
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        // Seed tags after container is loaded
        Task {
            try? await seedTagsIfNeeded()
        }
        
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func save() async throws {
        let context = persistentContainer.viewContext
        
        if context.hasChanges {
            try await context.perform {
                try context.save()
            }
        }
    }
    
    func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            persistentContainer.performBackgroundTask { context in
                do {
                    let result = try block(context)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func seedTagsIfNeeded() async throws {
        try await performBackgroundTask { context in
            try TagSeedData.seedTags(in: context)
        }
    }
    
    func ensureTagsSeeded() async throws {
        try await seedTagsIfNeeded()
    }
    
    private func handleCoreDataError(_ error: Error) {
        print("Core Data error: \(error.localizedDescription)")
        print("Attempting to delete and recreate persistent store...")
        
        // Delete the existing store
        guard let storeURL = persistentContainer.persistentStoreDescriptions.first?.url else {
            fatalError("Could not get store URL")
        }
        
        do {
            // Remove the store from the container first
            if let store = persistentContainer.persistentStoreCoordinator.persistentStores.first {
                try persistentContainer.persistentStoreCoordinator.remove(store)
            }
            
            // Delete the file
            try FileManager.default.removeItem(at: storeURL)
            print("Successfully deleted old store")
            
            // Try to load again
            persistentContainer.loadPersistentStores { _, error in
                if let error = error {
                    print("Failed to load after deletion: \(error.localizedDescription)")
                    fatalError("Core Data failed to load after store deletion: \(error.localizedDescription)")
                } else {
                    print("Successfully loaded new store")
                }
            }
        } catch {
            print("Failed to delete store: \(error.localizedDescription)")
            fatalError("Could not delete and recreate Core Data store: \(error.localizedDescription)")
        }
    }
}
