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
    @StateObject private var productViewModel = ProductViewModel(repository: ProductRepository())
    init() {
        // Tags are now seeded automatically by CoreDataStack
        
        let networkService = NetworkService()
        if !networkService.hasMealMeAPIKey() {
            // Use environment variable for API key (required for CI/CD and production)
            if let apiKey = ProcessInfo.processInfo.environment["MEALME_API_KEY"], !apiKey.isEmpty {
                _ = networkService.setMealMeAPIKey(apiKey)
                print("MealMe API key initialized successfully from environment")
            } else {
                print("Warning: MEALME_API_KEY environment variable not set. Image fetching will be disabled.")
            }
        }
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
