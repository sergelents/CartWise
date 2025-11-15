//
//  ShoppingListViewModel.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 11/7/25.
//
import SwiftUI
import Combine
import CoreData
import Foundation

@MainActor
final class ShoppingListViewModel: ObservableObject {
    @Published var products: [GroceryItem] = []
    @Published var priceComparison: PriceComparison?
    @Published var isLoadingPriceComparison = false
    @Published var errorMessage: String?
    
    private let repository: ProductRepositoryProtocol
    private let socialFeedViewModel: SocialFeedViewModel
    
    // Computed property to check if all products are completed
    var allProductsCompleted: Bool {
        !products.isEmpty && products.allSatisfy { $0.isCompleted }
    }
    
    init(
        repository: ProductRepositoryProtocol,
        socialFeedViewModel: SocialFeedViewModel
    ) {
        self.repository = repository
        self.socialFeedViewModel = socialFeedViewModel
    }
    
    // MARK: - Shopping List Operations
    
    func loadShoppingListProducts() async {
        do {
            products = try await repository.fetchListProducts()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func removeProductFromShoppingList(_ product: GroceryItem) async {
        do {
            try await repository.removeProductFromShoppingList(product)
            // Update the products array on the main thread
            products.removeAll { $0.id == product.id }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func permanentlyDeleteProduct(_ product: GroceryItem) async {
        do {
            try await repository.deleteProduct(product)
            // Reload the entire list instead of manually removing items
            // This prevents collection view inconsistency during animations
            await loadShoppingListProducts()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func clearShoppingList() async {
        do {
            // Remove all products from shopping list without deleting the actual product data
            for product in products {
                try await repository.removeProductFromShoppingList(product)
            }
            // Clear the local products array
            products.removeAll()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func addExistingProductToShoppingList(_ product: GroceryItem) async {
        do {
            try await repository.addProductToShoppingList(product)
            // Refresh shopping list to show the newly added item
            await loadShoppingListProducts()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Product Completion
    
    func toggleProductCompletion(_ product: GroceryItem) async {
        do {
            try await repository.toggleProductCompletion(product)
            await loadShoppingListProducts() // Refresh the list to show updated completion status
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func toggleAllProductsCompletion() async {
        do {
            // Check if all products are completed
            let allCompleted = products.allSatisfy { $0.isCompleted }
            // If all are completed, uncheck them all. Otherwise, check them all.
            for product in products {
                if allCompleted {
                    // Uncheck all if all are completed
                    if product.isCompleted {
                        try await repository.toggleProductCompletion(product)
                    }
                } else {
                    // Check all if not all are completed
                    if !product.isCompleted {
                        try await repository.toggleProductCompletion(product)
                    }
                }
            }
            await loadShoppingListProducts() // Refresh the list
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Price Update
    
    func updateProductPrice(_ product: GroceryItem, price: Double, store: String, locationAddress: String?) async {
        do {
            try await repository.updateProductWithPrice(
                product: product,
                price: price,
                store: store,
                location: locationAddress
            )
            // Create a social feed entry for this price update
            await socialFeedViewModel.createPriceUpdateExperienceForStore(
                product: product,
                price: price,
                store: store,
                locationAddress: locationAddress
            )
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Price Comparison
    
    func loadLocalPriceComparison() async {
        // First, refresh any outdated sample data prices (older than 2 weeks)
        await CoreDataStack.shared.refreshSampleDataPrices()
        
        // Get the current shopping list products specifically
        let shoppingListProducts = try? await repository.fetchListProducts()
        print("ShoppingListViewModel: Starting local price comparison")
        print("ShoppingListViewModel: Shopping list products count: \(shoppingListProducts?.count ?? 0)")
        
        guard let shoppingList = shoppingListProducts, !shoppingList.isEmpty else {
            print("ShoppingListViewModel: No shopping list products found")
            priceComparison = nil
            return
        }
        
        // Print details of each shopping list item
        for (index, item) in shoppingList.enumerated() {
            print("ShoppingListViewModel: Item \(index + 1): \(item.productName ?? "Unknown") - " +
                  "Store: \(item.store ?? "None") - Price: $\(item.price)")
        }
        
        isLoadingPriceComparison = true
        errorMessage = nil
        
        do {
            print("ShoppingListViewModel: Starting local price comparison for shopping list with \(shoppingList.count) items")
            // Use the repository to get local price comparison
            let localComparison = try await repository.getLocalPriceComparison(for: shoppingList)
            print("ShoppingListViewModel: Local comparison result - \(localComparison.storePrices.count) stores")
            
            for storePrice in localComparison.storePrices {
                print("ShoppingListViewModel: Store \(storePrice.store): $\(storePrice.totalPrice)")
            }
            
            // Convert LocalPriceComparisonResult to PriceComparison for compatibility
            let storePrices = localComparison.storePrices.map { localStorePrice in
                StorePrice(
                    store: localStorePrice.store,
                    totalPrice: localStorePrice.totalPrice,
                    currency: localStorePrice.currency,
                    availableItems: localStorePrice.availableItems,
                    unavailableItems: localStorePrice.unavailableItems,
                    itemPrices: localStorePrice.itemPrices,
                    itemShoppers: localStorePrice.itemShoppers
                )
            }
            
            let comparison = PriceComparison(
                storePrices: storePrices,
                bestStore: localComparison.bestStore,
                bestTotalPrice: localComparison.bestTotalPrice,
                bestCurrency: localComparison.bestCurrency,
                totalItems: localComparison.totalItems,
                availableItems: localComparison.availableItems
            )
            
            priceComparison = comparison
        } catch {
            print("ShoppingListViewModel: Error loading local price comparison: \(error)")
            errorMessage = "Failed to load local price comparison: \(error.localizedDescription)"
        }
        
        isLoadingPriceComparison = false
    }
}

