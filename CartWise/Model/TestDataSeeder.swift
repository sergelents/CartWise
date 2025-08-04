//
//  TestDataSeeder.swift
//  CartWise
//
//  Created by AI Assistant on 12/19/24.
//
import Foundation
import CoreData

struct TestDataSeeder {
    static let shared = TestDataSeeder()
    
    // Store data
    let stores = [
        ("Walmart", "123 Main St", "Springfield", "IL", "62701"),
        ("Target", "456 Oak Ave", "Springfield", "IL", "62702"),
        ("Kroger", "789 Pine Rd", "Springfield", "IL", "62703"),
        ("Safeway", "321 Elm St", "Springfield", "IL", "62704"),
        ("Whole Foods", "654 Maple Dr", "Springfield", "IL", "62705"),
        ("Trader Joe's", "987 Cedar Ln", "Springfield", "IL", "62706")
    ]
    
    // Grocery items with fake barcodes (name, barcode, category, price, unit)
    let groceryItems = [
        // Dairy & Eggs
        ("Milk 2%", "1234567890123", "Dairy", 3.99, "Gallon"),
        ("Eggs Large", "1234567890124", "Dairy", 4.99, "Dozen"),
        ("Cheese Cheddar", "1234567890125", "Dairy", 5.99, "8oz"),
        ("Yogurt Greek", "1234567890126", "Dairy", 6.99, "32oz"),
        ("Butter Unsalted", "1234567890127", "Dairy", 4.49, "1lb"),
        ("Cream Cheese", "1234567890128", "Dairy", 3.49, "8oz"),
        ("Sour Cream", "1234567890129", "Dairy", 2.99, "16oz"),
        ("Heavy Cream", "1234567890130", "Dairy", 4.99, "16oz"),
        
        // Produce
        ("Bananas", "1234567890131", "Produce", 1.99, "Bunch"),
        ("Apples Red", "1234567890132", "Produce", 3.99, "2lb"),
        ("Oranges", "1234567890133", "Produce", 4.99, "Bag"),
        ("Tomatoes", "1234567890134", "Produce", 2.99, "1lb"),
        ("Lettuce Iceberg", "1234567890135", "Produce", 1.49, "Head"),
        ("Carrots", "1234567890136", "Produce", 1.99, "2lb"),
        ("Broccoli", "1234567890137", "Produce", 2.49, "Head"),
        ("Spinach", "1234567890138", "Produce", 3.99, "10oz"),
        
        // Meat & Seafood
        ("Chicken Breast", "1234567890139", "Meat", 8.99, "1lb"),
        ("Ground Beef", "1234567890140", "Meat", 6.99, "1lb"),
        ("Salmon Fillet", "1234567890141", "Seafood", 12.99, "1lb"),
        ("Pork Chops", "1234567890142", "Meat", 7.99, "1lb"),
        ("Turkey Breast", "1234567890143", "Meat", 9.99, "2lb"),
        ("Bacon", "1234567890144", "Meat", 5.99, "12oz"),
        ("Hot Dogs", "1234567890145", "Meat", 3.99, "8ct"),
        ("Deli Ham", "1234567890146", "Deli", 6.99, "1lb"),
        
        // Pantry
        ("Bread White", "1234567890147", "Bakery", 2.99, "Loaf"),
        ("Rice White", "1234567890148", "Pantry", 3.99, "5lb"),
        ("Pasta Spaghetti", "1234567890149", "Pantry", 1.99, "16oz"),
        ("Olive Oil", "1234567890150", "Pantry", 8.99, "16oz"),
        ("Sugar Granulated", "1234567890151", "Pantry", 2.99, "5lb"),
        ("Flour All Purpose", "1234567890152", "Pantry", 3.99, "5lb"),
        ("Salt", "1234567890153", "Pantry", 1.99, "26oz"),
        ("Black Pepper", "1234567890154", "Pantry", 4.99, "8oz"),
        
        // Snacks
        ("Potato Chips", "1234567890155", "Snacks", 3.99, "8oz"),
        ("Popcorn", "1234567890156", "Snacks", 2.99, "12oz"),
        ("Crackers", "1234567890157", "Snacks", 3.49, "8oz"),
        ("Nuts Mixed", "1234567890158", "Snacks", 6.99, "16oz"),
        ("Granola Bars", "1234567890159", "Snacks", 4.99, "8ct"),
        ("Cookies Chocolate", "1234567890160", "Snacks", 3.99, "12oz"),
        ("Pretzels", "1234567890161", "Snacks", 2.99, "16oz"),
        ("Trail Mix", "1234567890162", "Snacks", 5.99, "12oz"),
        
        // Beverages
        ("Orange Juice", "1234567890163", "Beverages", 4.99, "64oz"),
        ("Apple Juice", "1234567890164", "Beverages", 3.99, "64oz"),
        ("Coffee Ground", "1234567890165", "Beverages", 8.99, "12oz"),
        ("Tea Bags", "1234567890166", "Beverages", 4.99, "100ct"),
        ("Soda Cola", "1234567890167", "Beverages", 5.99, "12pk"),
        ("Water Bottles", "1234567890168", "Beverages", 4.99, "24pk"),
        ("Beer Domestic", "1234567890169", "Beverages", 12.99, "6pk"),
        ("Wine Red", "1234567890170", "Beverages", 15.99, "750ml"),
        
        // Frozen Foods
        ("Frozen Pizza", "1234567890171", "Frozen", 6.99, "14in"),
        ("Ice Cream Vanilla", "1234567890172", "Frozen", 4.99, "48oz"),
        ("Frozen Vegetables", "1234567890173", "Frozen", 2.99, "16oz"),
        ("Frozen French Fries", "1234567890174", "Frozen", 3.99, "32oz"),
        ("Frozen Chicken Nuggets", "1234567890175", "Frozen", 5.99, "24oz"),
        ("Frozen Fish Sticks", "1234567890176", "Frozen", 4.99, "20oz"),
        ("Frozen Waffles", "1234567890177", "Frozen", 3.99, "8ct"),
        ("Frozen Burritos", "1234567890178", "Frozen", 2.99, "4ct"),
        
        // Canned Goods
        ("Canned Tomatoes", "1234567890179", "Canned", 1.99, "28oz"),
        ("Canned Beans", "1234567890180", "Canned", 1.49, "15oz"),
        ("Canned Tuna", "1234567890181", "Canned", 2.99, "5oz"),
        ("Canned Corn", "1234567890182", "Canned", 1.99, "15oz"),
        ("Canned Soup", "1234567890183", "Canned", 2.49, "10.5oz"),
        ("Canned Fruit", "1234567890184", "Canned", 2.99, "15oz"),
        ("Canned Vegetables", "1234567890185", "Canned", 1.99, "15oz"),
        ("Canned Chili", "1234567890186", "Canned", 2.99, "15oz"),
        
        // Condiments
        ("Ketchup", "1234567890187", "Condiments", 2.99, "24oz"),
        ("Mustard", "1234567890188", "Condiments", 2.49, "12oz"),
        ("Mayonnaise", "1234567890189", "Condiments", 3.99, "30oz"),
        ("Ranch Dressing", "1234567890190", "Condiments", 3.49, "16oz"),
        ("Soy Sauce", "1234567890191", "Condiments", 2.99, "10oz"),
        ("Hot Sauce", "1234567890192", "Condiments", 3.99, "5oz"),
        ("BBQ Sauce", "1234567890193", "Condiments", 2.99, "18oz"),
        ("Honey", "1234567890194", "Condiments", 4.99, "12oz"),
        
        // Baking
        ("Chocolate Chips", "1234567890195", "Baking", 3.99, "12oz"),
        ("Vanilla Extract", "1234567890196", "Baking", 4.99, "2oz"),
        ("Baking Soda", "1234567890197", "Baking", 1.99, "16oz"),
        ("Baking Powder", "1234567890198", "Baking", 2.99, "8oz"),
        ("Yeast Active", "1234567890199", "Baking", 3.99, "3pk"),
        ("Cocoa Powder", "1234567890200", "Baking", 4.99, "8oz"),
        ("Brown Sugar", "1234567890201", "Baking", 2.99, "2lb"),
        ("Powdered Sugar", "1234567890202", "Baking", 2.99, "2lb")
    ]
    
    func seedTestData() {
        let context = PersistenceController.shared.container.viewContext
        
        // Get or create current user first
        let userFetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        userFetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \UserEntity.createdAt, ascending: false)]
        userFetchRequest.fetchLimit = 1
        
        var currentUser: UserEntity
        do {
            let users = try context.fetch(userFetchRequest)
            if let user = users.first {
                currentUser = user
            } else {
                // Create a test user if none exists
                currentUser = UserEntity(context: context)
                currentUser.id = UUID().uuidString
                currentUser.username = "TestUser"
                currentUser.password = "testpassword"
                currentUser.updates = 0
                currentUser.level = "Beginner"
                currentUser.createdAt = Date()
            }
        } catch {
            print("❌ Error fetching user: \(error)")
            return
        }
        
        // Create stores first
        var createdStores: [Location] = []
        
        for (index, store) in stores.enumerated() {
            let location = Location(
                context: context,
                id: UUID().uuidString,
                name: store.0,
                address: store.1,
                city: store.2,
                state: store.3,
                zipCode: store.4,
                favorited: index < 2, // First 2 stores are favorited
                isDefault: index == 0 // First store is default
            )
            location.user = currentUser // Associate with user
            createdStores.append(location)
        }
        
        // Create grocery items with prices at each store
        for (index, item) in groceryItems.enumerated() {
            let groceryItem = GroceryItem(
                context: context,
                id: UUID().uuidString,
                productName: item.0,
                brand: "Test Brand",
                category: item.2,
                imageURL: nil,
                barcode: item.1,
                isOnSale: index % 10 == 0 // Every 10th item is on sale
            )
            
            // Add prices at each store with slight variations
            for (storeIndex, store) in createdStores.enumerated() {
                let priceVariation = Double(storeIndex) * 0.10 // 10 cent variation per store
                let basePrice = item.3 // price is at index 3
                let finalPrice = basePrice + priceVariation
                
                let price = GroceryItemPrice(
                    context: context,
                    id: UUID().uuidString,
                    price: finalPrice,
                    currency: "USD",
                    store: store.name ?? "Unknown Store",
                    groceryItem: groceryItem,
                    location: store,
                    updatedBy: "TestData"
                )
                
                // Debug: Print store association
                print("Created price: $\(finalPrice) for \(item.0) at \(store.name ?? "Unknown")")
                
                // Add some random price updates
                if index % 5 == 0 { // Every 5th item has recent price updates
                    price.lastUpdated = Date().addingTimeInterval(-Double.random(in: 0...86400)) // Within last 24 hours
                }
            }
        }
        
        // Save context
        do {
            try context.save()
            print("✅ Test data seeded successfully!")
            print("📊 Created \(stores.count) stores")
            print("📊 Created \(groceryItems.count) grocery items")
            print("📊 Created \(groceryItems.count * stores.count) price entries")
            
            // Post notification to refresh UI
            NotificationCenter.default.post(name: .NSManagedObjectContextDidSave, object: context)
        } catch {
            print("❌ Error seeding test data: \(error)")
        }
    }
    
    func clearTestData() {
        let context = PersistenceController.shared.container.viewContext
        
        // Delete all test data in the correct order (respecting relationships)
        let entities = ["GroceryItemPrice", "GroceryItem", "Location", "UserEntity"]
        
        for entityName in entities {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            
            do {
                let objects = try context.fetch(fetchRequest)
                print("Found \(objects.count) \(entityName) objects to delete")
                
                for object in objects {
                    context.delete(object as! NSManagedObject)
                }
                
                print("Deleted \(objects.count) \(entityName) objects")
            } catch {
                print("Error clearing \(entityName) data: \(error)")
            }
        }
        
        do {
            try context.save()
            print("✅ Test data cleared successfully!")
            
            // Post notification to refresh UI
            NotificationCenter.default.post(name: .NSManagedObjectContextDidSave, object: context)
        } catch {
            print("❌ Error clearing test data: \(error)")
        }
    }
} 