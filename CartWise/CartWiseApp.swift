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
    @StateObject private var productViewModel: ProductViewModel
    @StateObject private var appCoordinator: AppCoordinator
    
    init() {
        // Create repository once
        let repository = ProductRepository()
        
        // Initialize ProductViewModel with the repository
        let productViewModel = ProductViewModel(repository: repository)
        _productViewModel = StateObject(wrappedValue: productViewModel)
        
        // Initialize AppCoordinator with ProductViewModel
        _appCoordinator = StateObject(wrappedValue: AppCoordinator(productViewModel: productViewModel))
        
        // Set up MealMe API key
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
