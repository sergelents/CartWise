//
//  ProductViewModel.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/7/25.
//
import SwiftUI
import Combine

@MainActor
final class ProductViewModel: ObservableObject {
    @Published var products: [Product] = []
    var errorMessage: String?
    
    private let repository: ProductRepositoryProtocol
    
    init(repository: ProductRepositoryProtocol) {
            self.repository = repository
        }
    
    func loadAllProducts() async {
            do {
                products = try await repository.fetchAllProducts()
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    
    func updateProduct(_ product: Product) async {
        do {
            try await repository.updateProduct(product)
            await loadAllProducts() // Refresh the list
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
    
    func toggleProductCompletion(_ product: Product) async {
        do {
            try await repository.toggleProductCompletion(product)
            await loadAllProducts() // Refresh the list to show updated completion status
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
            await loadAllProducts() // Refresh the list
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func addExistingProductToShoppingList(_ product: Product) async {
        do {
            try await repository.addProductToShoppingList(product)
            await loadAllProducts()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func createProductByName(_ name: String) async {
        do {
            // Generate a random barcode for now, or use a UUID string
            let barcode = UUID().uuidString
            _ = try await repository.createProduct(barcode: barcode, name: name, brands: nil, imageURL: nil, nutritionGrade: nil, categories: nil, ingredients: nil)
            await loadAllProducts()
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
    
    func createProduct(byName name: String) async {
        do {
            let newProduct = try await repository.createProduct(name: name)
            products.append(newProduct)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func createProductWithDetails(name: String, brand: String?, category: String?) async {
        do {
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
            await loadAllProducts()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // Future barcode scanning functionality
    func addProductByBarcode(_ barcode: String) async {
        do {
            // First try to fetch from network (Open Food Facts API)
            if let networkProduct = try await repository.fetchProductFromNetwork(by: barcode) {
                // Product found and saved to local cache
                await loadAllProducts()
                errorMessage = nil
            } else {
                // Product not found in network, create a placeholder
                _ = try await repository.createProduct(
                    barcode: barcode,
                    name: "Product (Barcode: \(barcode))",
                    brands: nil,
                    imageURL: nil,
                    nutritionGrade: nil,
                    categories: nil,
                    ingredients: nil
                )
                await loadAllProducts()
                errorMessage = "Product not found in database. Added as placeholder."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // Clear all products (for debugging)
    func clearAllProducts() async {
        do {
            // Delete all products from Core Data
            for product in products {
                try await repository.deleteProduct(product)
            }
            await loadAllProducts()
            errorMessage = "All products cleared successfully."
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// This code was generated with the help of Claude, saving me 1 hour of research and development.

