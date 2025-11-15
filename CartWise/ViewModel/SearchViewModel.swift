//
//  SearchViewModel.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 11/7/25.
//
import SwiftUI
import Combine
import CoreData
import Foundation

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var products: [GroceryItem] = []
    @Published var errorMessage: String?
    
    private let repository: ProductRepositoryProtocol
    
    init(repository: ProductRepositoryProtocol) {
        self.repository = repository
    }
    
    // MARK: - Product Loading
    
    func loadProducts() async {
        do {
            products = try await repository.fetchAllProducts()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // Fetch all products without mutating the published `products` array
    // Useful for views that need a read-only snapshot without triggering UI-wide reloads
    func fetchAllProducts() async -> [GroceryItem] {
        do {
            return try await repository.fetchAllProducts()
        } catch {
            // Surface the error but do not mutate state; return an empty list on failure
            errorMessage = error.localizedDescription
            return []
        }
    }
    
    // MARK: - Search Operations
    
    func searchProducts(by name: String) async {
        do {
            products = try await repository.searchProducts(by: name)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // Search without mutating the published `products` array
    func searchProductsQuiet(by name: String) async -> [GroceryItem] {
        do {
            return try await repository.searchProducts(by: name)
        } catch {
            errorMessage = error.localizedDescription
            return []
        }
    }
    
    // MARK: - Add to Shopping List
    
    func addExistingProductToShoppingList(_ product: GroceryItem) async {
        do {
            try await repository.addProductToShoppingList(product)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // Quiet version that doesn't reload lists - for UI components
    func addExistingProductToShoppingListQuiet(_ product: GroceryItem) async {
        do {
            try await repository.addProductToShoppingList(product)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Helper Methods
    
    func clearSearch() {
        products = []
    }
    
    func filterProductsByCategory(_ category: String) -> [GroceryItem] {
        guard !category.isEmpty else { return products }
        return products.filter { $0.category?.lowercased() == category.lowercased() }
    }
    
    func filterProductsByBrand(_ brand: String) -> [GroceryItem] {
        guard !brand.isEmpty else { return products }
        return products.filter { $0.brand?.lowercased() == brand.lowercased() }
    }
    
    func sortProductsByName(ascending: Bool = true) -> [GroceryItem] {
        return products.sorted { product1, product2 in
            let name1 = product1.productName?.lowercased() ?? ""
            let name2 = product2.productName?.lowercased() ?? ""
            return ascending ? name1 < name2 : name1 > name2
        }
    }
    
    func sortProductsByPrice(ascending: Bool = true) -> [GroceryItem] {
        return products.sorted { product1, product2 in
            return ascending ? product1.price < product2.price : product1.price > product2.price
        }
    }
}

