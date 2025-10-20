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
            let apiKey = APIKeys.mealMeAPIKey
            _ = networkService.setMealMeAPIKey(apiKey)
            print("MealMe API key initialized successfully")
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
