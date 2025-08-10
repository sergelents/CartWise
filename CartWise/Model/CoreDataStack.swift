//
//  CoreDataStack.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/7/25.
//
import Foundation
import CoreData
import UIKit
import SwiftUI
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
    
    // MARK: - Sample Data Seeding
    
    /// Seeds the database with sample data for testing and demonstration
    func seedSampleData() async {
        await persistentContainer.performBackgroundTask { context in
            do {
                print("CoreDataStack: Starting sample data seeding...")
                
                // Create sample locations
                let locations = self.createSampleLocations(in: context)
                
                // Seed existing tags from TagSeedData
                try TagSeedData.seedTags(in: context)
                
                // Get all available tags for assignment
                let tagFetchRequest: NSFetchRequest<Tag> = Tag.fetchRequest()
                let tags = try context.fetch(tagFetchRequest)
                
                // Create sample products with prices and tags
                let products = self.createSampleProducts(in: context, locations: locations, tags: tags)
                
                // Create sample shopping list items
                self.createSampleShoppingListItems(products: products, in: context)
                
                // Create sample favorite items
                self.createSampleFavoriteItems(products: products, in: context)
                
                // Create sample social feed entries
                self.createSampleSocialFeedEntries(products: products, locations: locations, in: context)
                
                try context.save()
                print("CoreDataStack: Sample data seeding completed successfully")
                print("CoreDataStack: Created \(products.count) products, \(locations.count) locations, \(tags.count) tags")
                
            } catch {
                print("CoreDataStack: Error seeding sample data: \(error.localizedDescription)")
            }
        }
        
        // After Core Data operations are complete, fetch images for all sample products
        await fetchImagesForSampleProducts()
    }
    
    /// Clears all sample data from the database
    func clearSampleData() async {
        await persistentContainer.performBackgroundTask { [self] context in
            do {
                print("CoreDataStack: Clearing sample data...")
                
                // Delete each entity type individually to ensure proper cleanup
                let entityNames = ["GroceryItem", "Location", "GroceryItemPrice", "ProductImage", "ShoppingExperience", "UserEntity", "Tag"]
                
                for entityName in entityNames {
                    let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
                    let objects = try context.fetch(fetchRequest)
                    
                    for object in objects {
                        context.delete(object)
                    }
                    
                    print("CoreDataStack: Deleted \(objects.count) \(entityName) objects")
                }
                
                try context.save()
                print("CoreDataStack: Sample data cleared successfully")
                
            } catch {
                print("CoreDataStack: Error clearing sample data: \(error.localizedDescription)")
            }
        }
        
        // Notify UI to refresh after background task is complete
        await MainActor.run {
            NotificationCenter.default.post(name: NSNotification.Name("SampleDataCleared"), object: nil)
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func createSampleLocations(in context: NSManagedObjectContext) -> [Location] {
        let locationData = [
            ("Safeway", "123 Main St, Portland, OR"),
            ("Fred Meyer", "456 Oak Ave, Portland, OR"),
            ("Trader Joe's", "789 Pine St, Portland, OR"),
            ("Whole Foods", "321 Market St, Portland, OR"),
            ("WinCo Foods", "654 Division St, Portland, OR")
        ]
        
        // Get or create current user
        let userFetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        userFetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \UserEntity.createdAt, ascending: false)]
        userFetchRequest.fetchLimit = 1
        
        let currentUser: UserEntity
        do {
            let users = try context.fetch(userFetchRequest)
            if let existingUser = users.first {
                currentUser = existingUser
            } else {
                // Create a sample user if none exists
                currentUser = UserEntity(context: context)
                currentUser.id = UUID().uuidString
                currentUser.username = "SampleUser"
                currentUser.createdAt = Date()
            }
        } catch {
            // Create a sample user if fetch fails
            currentUser = UserEntity(context: context)
            currentUser.id = UUID().uuidString
            currentUser.username = "SampleUser"
            currentUser.createdAt = Date()
        }
        
        var locations: [Location] = []
        
        for (name, address) in locationData {
            let location = Location(context: context)
            location.id = UUID().uuidString
            location.name = name
            location.address = address
            location.city = "Portland"
            location.state = "OR"
            location.zipCode = "97201"
            location.createdAt = Date()
            location.user = currentUser // Assign to current user
            locations.append(location)
        }
        
        print("CoreDataStack: Created \(locations.count) sample locations for user: \(currentUser.username ?? "Unknown")")
        return locations
    }
    
    private func createSampleProducts(in context: NSManagedObjectContext, locations: [Location], tags: [Tag]) -> [GroceryItem] {
        let productData = [
            // Dairy & Eggs
            ("Organic Whole Milk", "Organic Valley", "Dairy & Eggs", 4.99),
            ("Large Eggs", "Farm Fresh", "Dairy & Eggs", 3.49),
            ("Greek Yogurt", "Chobani", "Dairy & Eggs", 5.99),
            ("Cheddar Cheese", "Tillamook", "Dairy & Eggs", 6.99),
            
            // Produce
            ("Fresh Spinach", "Earthbound Farm", "Produce", 3.49),
            ("Organic Apples", "Honeycrisp", "Produce", 4.99),
            ("Avocados", "Hass", "Produce", 3.99),
            
            // Beverages
            ("Pepsi Cola", "Pepsi", "Beverages", 2.49),
            ("Starry Lemon Lime Soda", "PepsiCo", "Beverages", 2.49),
            ("Sparkling Water", "LaCroix", "Beverages", 5.99),
            
            // Pantry Items
            ("Olive Oil", "Bertolli", "Pantry Items", 8.99),
            ("Pasta", "Barilla", "Pantry Items", 2.99),
            ("Tomato Sauce", "Rao's", "Pantry Items", 4.99),
            
            // Bakery
            ("Sourdough Bread", "Artisan Bakery", "Bakery", 4.99),
            ("Chocolate Chip Cookies", "Grandma's", "Bakery", 3.99),
            ("Croissants", "French Bakery", "Bakery", 5.99),
            
            // Meat & Seafood
            ("Chicken Breast", "Organic Valley", "Meat & Seafood", 12.99),
            ("Salmon Fillet", "Wild Alaskan", "Meat & Seafood", 18.99),
            ("Ground Beef", "Grass Fed", "Meat & Seafood", 8.99),
            
            // Frozen Foods
            ("Frozen Pizza", "DiGiorno", "Frozen Foods", 7.99),
            ("Ice Cream", "Ben & Jerry's", "Frozen Foods", 5.99),
            ("Frozen Vegetables", "Bird's Eye", "Frozen Foods", 3.99),
            
            // Household & Personal Care
            ("Laundry Detergent", "Tide", "Household & Personal Care", 12.99),
            ("Toothpaste", "Colgate", "Household & Personal Care", 3.99),
            ("Shampoo", "Head & Shoulders", "Household & Personal Care", 6.99)
        ]
        
        var products: [GroceryItem] = []
        
        for (name, brand, category, basePrice) in productData {
            let product = GroceryItem(context: context)
            product.id = UUID().uuidString
            product.productName = name
            product.brand = brand
            product.category = category
            product.barcode = String(format: "%013d", Int.random(in: 1000000000000...9999999999999))
            product.isOnSale = Bool.random()
            product.createdAt = Date()
            
            // Create product image without URL - let the app fetch real images
            let productImage = ProductImage(context: context)
            productImage.id = UUID().uuidString
            productImage.imageURL = nil // Let the app fetch real images from API
            productImage.createdAt = Date()
            product.productImage = productImage
            
            // Add prices at different locations
            for location in locations {
                let priceVariation = Double.random(in: -1.0...1.0)
                let price = GroceryItemPrice(context: context)
                price.id = UUID().uuidString
                price.price = basePrice + priceVariation
                price.currency = "USD"
                price.location = location
                price.groceryItem = product
                price.createdAt = Date()
            }
            
            // Assign relevant tags to products
            assignTagsToProduct(product: product, tags: tags, category: category, brand: brand, isOnSale: product.isOnSale)
            
            products.append(product)
        }
        
        print("CoreDataStack: Created \(products.count) sample products")
        return products
    }
    
    private func createSampleShoppingListItems(products: [GroceryItem], in context: NSManagedObjectContext) {
        // Add 8 random products to shopping list
        let shoppingListProducts = Array(products.shuffled().prefix(8))
        
        for product in shoppingListProducts {
            product.isInShoppingList = true
        }
        
        print("CoreDataStack: Added \(shoppingListProducts.count) items to shopping list")
    }
    
    private func createSampleFavoriteItems(products: [GroceryItem], in context: NSManagedObjectContext) {
        // Add 6 random products to favorites
        let favoriteProducts = Array(products.shuffled().prefix(6))
        
        for product in favoriteProducts {
            product.isFavorite = true
        }
        
        print("CoreDataStack: Added \(favoriteProducts.count) items to favorites")
    }
    
    private func createSampleSocialFeedEntries(products: [GroceryItem], locations: [Location], in context: NSManagedObjectContext) {
        let sampleEntries = [
            ("Found great deals on organic produce at %@!", 5, 0),
            ("%@ has the best prices on dairy products", 4, 1),
            ("Love the fresh bread selection at %@", 5, 2),
            ("%@ organic section is amazing", 5, 3),
            ("Great value for money at %@", 4, 4)
        ]
        
        for (commentTemplate, rating, locationIndex) in sampleEntries {
            let experience = ShoppingExperience(context: context)
            experience.id = UUID().uuidString
            experience.groceryItem = products.randomElement()
            
            // Use the specific location for this entry
            let location = locations[locationIndex % locations.count]
            experience.location = location
            
            // Format the comment with the actual location name
            let locationName = location.name ?? "Unknown Store"
            let comment = String(format: commentTemplate, locationName)
            
            experience.rating = Int16(rating) // Store as simple integer rating (1-5)
            experience.comment = comment
            experience.createdAt = Date()
        }
        
        print("CoreDataStack: Created \(sampleEntries.count) sample social feed entries")
    }
    
    private func assignTagsToProduct(product: GroceryItem, tags: [Tag], category: String?, brand: String?, isOnSale: Bool) {
        var assignedTags: [Tag] = []
        
        // Assign tags based on product characteristics
        for tag in tags {
            let tagName = tag.name?.lowercased() ?? ""
            
            // Organic products
            if (product.productName?.lowercased().contains("organic") == true || 
                brand?.lowercased().contains("organic") == true) && 
                tagName.contains("organic") {
                assignedTags.append(tag)
            }
            
            // Sale items
            if isOnSale && tagName.contains("on sale") {
                assignedTags.append(tag)
            }
            
            // Category-based tags
            if let category = category?.lowercased() {
                if category.contains("dairy") && tagName.contains("dairy") {
                    assignedTags.append(tag)
                }
                if category.contains("meat") && tagName.contains("meat") {
                    assignedTags.append(tag)
                }
                if category.contains("produce") && (tagName.contains("fruits") || tagName.contains("vegetables")) {
                    assignedTags.append(tag)
                }
                if category.contains("beverages") && tagName.contains("beverages") {
                    assignedTags.append(tag)
                }
                if category.contains("bakery") && tagName.contains("bread") {
                    assignedTags.append(tag)
                }
                if category.contains("pantry") && (tagName.contains("pasta") || tagName.contains("rice") || tagName.contains("oils")) {
                    assignedTags.append(tag)
                }
                if category.contains("frozen") && tagName.contains("frozen") {
                    assignedTags.append(tag)
                }
                if category.contains("household") && (tagName.contains("kitchen") || tagName.contains("bathroom") || tagName.contains("laundry")) {
                    assignedTags.append(tag)
                }
            }
        }
        
        // Assign the tags to the product
        product.tags = NSSet(array: assignedTags)
        
        if !assignedTags.isEmpty {
            print("CoreDataStack: Assigned \(assignedTags.count) tags to '\(product.productName ?? "Unknown")'")
        }
    }
    
    // MARK: - Image Fetching for Sample Data
    
    /// Fetches images for sample products using the same API as new items
    private func fetchImagesForSampleProducts() async {
        print("CoreDataStack: Starting image fetch for sample products")
        
        // Get all products from Core Data
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
        
        do {
            let products = try context.fetch(fetchRequest)
            print("CoreDataStack: Found \(products.count) products to fetch images for")
            
            // Create ImageService instance
            let imageService = ImageService()
            
            // Fetch images for each product
            for product in products {
                do {
                    let productName = product.productName ?? ""
                    let brand = product.brand
                    let category = product.category
                    
                    print("CoreDataStack: Fetching image for '\(productName)'")
                    
                    if let imageURL = try await imageService.fetchImageURL(for: productName, brand: brand, category: category) {
                        print("CoreDataStack: Got image URL for '\(productName)': \(imageURL)")
                        
                        // Download image data
                        if let url = URL(string: imageURL) {
                            let (imageData, _) = try await URLSession.shared.data(from: url)
                            
                            // Update product with image data on main thread
                            await MainActor.run {
                                // Save image to Core Data
                                if let productImage = product.productImage {
                                    productImage.imageURL = imageURL
                                    productImage.imageData = imageData
                                    productImage.updatedAt = Date()
                                }
                                
                                // Force a UI update
                                product.objectWillChange.send()
                            }
                            
                            print("CoreDataStack: Successfully saved image for '\(productName)'")
                        }
                    } else {
                        print("CoreDataStack: No image URL found for '\(productName)'")
                    }
                } catch {
                    print("CoreDataStack: Error fetching image for '\(product.productName ?? "")': \(error.localizedDescription)")
                }
            }
            
            print("CoreDataStack: Completed image fetching for sample products")
            
        } catch {
            print("CoreDataStack: Error fetching products for image update: \(error.localizedDescription)")
        }
    }
}
