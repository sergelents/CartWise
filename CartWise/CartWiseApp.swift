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
    @StateObject private var appCoordinator: AppCoordinator
    
    init() {
        // Create shared dependencies
        let repository = ProductRepository()
        let socialFeedViewModel = SocialFeedViewModel()
        
        // Initialize all view models with dependencies
        let shoppingListViewModel = ShoppingListViewModel(
            repository: repository,
            socialFeedViewModel: socialFeedViewModel
        )
        let searchViewModel = SearchViewModel(repository: repository)
        let addItemsViewModel = AddItemsViewModel(repository: repository)
        let profileViewModel = ProfileViewModel(repository: repository)
        let locationViewModel = LocationViewModel(
            repository: repository
        )
        let tagViewModel = TagViewModel(
            repository: repository
        )
        
        // Initialize AppCoordinator with all view models
        _appCoordinator = StateObject(wrappedValue: AppCoordinator(
            shoppingListViewModel: shoppingListViewModel,
            searchViewModel: searchViewModel,
            addItemsViewModel: addItemsViewModel,
            profileViewModel: profileViewModel,
            locationViewModel: locationViewModel,
            tagViewModel: tagViewModel,
            socialFeedViewModel: socialFeedViewModel
        ))
        
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
                .preferredColorScheme(.light)
        }
    }
}
