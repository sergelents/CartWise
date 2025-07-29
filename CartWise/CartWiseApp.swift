//
//  CartWiseApp.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/5/25.
//

import SwiftUI
import CoreData

@main
struct CartWiseApp: App {
    @StateObject private var appCoordinator = AppCoordinator()
    @StateObject var productViewModel = ProductViewModel(repository: ProductRepository())
    
    init() {
        // Tags are now seeded automatically by CoreDataStack
    }
    
    // Create a CoreDataStack instance for the app
    private let coreDataStack = CoreDataStack.shared

    var body: some Scene {
        WindowGroup {
            AppCoordinatorView(coordinator: appCoordinator)
                .environment(\.managedObjectContext, coreDataStack.persistentContainer.viewContext)
                .environmentObject(productViewModel)
                .preferredColorScheme(.light)
        }
    }
}

