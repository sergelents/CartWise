//
//  ProductViewModel.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/7/25.
//  Updated by Brenna Wilson on 7/17/25 -7/18/25
import SwiftUI
import Combine

@MainActor
final class ProductViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var recentProducts: [Product] = []
    var errorMessage: String?
    
    private let repository: ProductRepositoryProtocol
    
    // Computed property to check if all products are completed
    var allProductsCompleted: Bool {
        !products.isEmpty && products.allSatisfy { $0.isCompleted }
    }
    
    init(repository: ProductRepositoryProtocol) {
            self.repository = repository
        }
    
    func loadListProducts() async {
        do {
            products = try await repository.fetchListProducts()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func loadProducts() async {
        do {
            products = try await repository.fetchAllProducts()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func loadRecentProducts(limit: Int = 10) async {
        do {
            recentProducts = try await repository.fetchRecentProducts(limit: limit)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func updateProduct(_ product: Product) async {
        do {
            try await repository.updateProduct(product)
            // No automatic refresh - let calling view decide
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func deleteProduct(_ product: Product) async {
        do {
            try await repository.deleteProduct(product)
            products.removeAll { $0.barcode == product.barcode }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func removeProduct(_ product: Product) async {
        do {
            try await repository.removeProductFromShoppingList(product)
            products.removeAll { $0.barcode == product.barcode }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func permanentlyDeleteProduct(_ product: Product) async {
        do {
            try await repository.deleteProduct(product)
            products.removeAll { $0.barcode == product.barcode }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func toggleProductCompletion(_ product: Product) async {
        do {
            try await repository.toggleProductCompletion(product)
            await loadListProducts() // Refresh the list to show updated completion status
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func toggleAllProductsCompletion() async {
        do {
            // Toggle all products completion status
            for product in products {
                try await repository.toggleProductCompletion(product)
            }
            await loadListProducts() // Refresh the list
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func addExistingProductToShoppingList(_ product: Product) async {
        do {
            try await repository.addProductToShoppingList(product)
            await loadListProducts()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    

  
    func searchProducts(by name: String) async {
        do {
            products = try await repository.searchProducts(by: name)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func createProductForShoppingList(byName name: String, brand: String? = nil, category: String? = nil) async {
        do {
            if await isDuplicateProduct(name: name) {
                errorMessage = "Product '\(name)' already exists in your list"
                return
            }
            
            let barcode = UUID().uuidString
            _ = try await repository.createProduct(
                barcode: barcode,
                name: name,
                brands: brand,
                imageURL: nil,
                nutritionGrade: nil,
                categories: category,
                ingredients: nil
            )
            await loadListProducts()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func isDuplicateProduct(name: String) async -> Bool {
        do {
            let existingProducts = try await repository.searchProducts(by: name)
            return existingProducts.contains { product in
                product.name?.lowercased() == name.lowercased()
            }
        } catch {
            return false // If search fails, allow creation
        }
    }

    
}

// This code was generated with the help of Claude, saving me 1 hour of research and development.

