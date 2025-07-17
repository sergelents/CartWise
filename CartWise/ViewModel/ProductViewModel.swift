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
    
    func loadAllProducts() async {
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
    

  
    func searchProducts(by name: String) async {
        do {
            products = try await repository.searchProducts(by: name)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func createProduct(byName name: String, brand: String? = nil, category: String? = nil) async {
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
    

    
    // // Future barcode scanning functionality
    // func addProductByBarcode(_ barcode: String) async {
    //     do {
    //         // First try to fetch from network (Open Food Facts API)
    //         if try await repository.fetchProductFromNetwork(by: barcode) != nil {
    //             // Product found and saved to local cache
    //             await loadAllProducts()
    //             errorMessage = nil
    //         } else {
    //             // Product not found in network, create a placeholder
    //             _ = try await repository.createProduct(
    //                 barcode: barcode,
    //                 name: "Product (Barcode: \(barcode))",
    //                 brands: nil,
    //                 imageURL: nil,
    //                 nutritionGrade: nil,
    //                 categories: nil,
    //                 ingredients: nil
    //             )
    //             await loadAllProducts()
    //             errorMessage = "Product not found in database. Added as placeholder."
    //         }
    //     } catch {
    //         errorMessage = error.localizedDescription
    //     }
    // }
    
}

// This code was generated with the help of Claude, saving me 1 hour of research and development.

