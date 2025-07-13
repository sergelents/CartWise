//
//  Persistence.swift
//  CartWise
//
//  Created by Alex Kumar on 7/12/25.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        // Add sample data for previews
        let user = UserEntity(context: viewContext)
        user.id = UUID().uuidString
        user.username = "testuser"
        user.password = "test123"
        user.updates = 0
        user.level = "Newbie"
        user.createdAt = Date()
        try? viewContext.save()
        return result
    }()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "CartWise")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
