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
    @Published var products: [GroceryItem] = []
    @Published var recentProducts: [GroceryItem] = []
    @Published var openFoodFactsProducts: [OpenFoodFactsProduct] = []
    @Published var selectedOpenFoodFactsProduct: OpenFoodFactsProduct?
    @Published var isLoadingOpenFoodFacts: Bool = false
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
    
    func updateProduct(_ product: GroceryItem) async {
        do {
            try await repository.updateProduct(product)
            await loadAllProducts() // Refresh the list
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func deleteProduct(_ product: GroceryItem) async {
        do {
            try await repository.deleteProduct(product)
            products.removeAll { $0.id == product.id }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func removeProduct(_ product: GroceryItem) async {
        do {
            try await repository.removeProductFromShoppingList(product)
            products.removeAll { $0.id == product.id }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func permanentlyDeleteProduct(_ product: GroceryItem) async {
        do {
            try await repository.deleteProduct(product)
            products.removeAll { $0.id == product.id }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func toggleProductCompletion(_ product: GroceryItem) async {
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
    
    func addExistingProductToShoppingList(_ product: GroceryItem) async {
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
            if await isDuplicateProduct(name: name) {
                errorMessage = "Product '\(name)' already exists in your list"
                return
            }
            
            let id = UUID().uuidString
            _ = try await repository.createProduct(
                id: id,
                productName: name,
                brand: brand,
                category: category,
                price: 0.0,
                currency: "USD",
                store: nil,
                location: nil,
                imageURL: nil,
                barcode: nil
            )
            await loadAllProducts()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func isDuplicateProduct(name: String) async -> Bool {
        do {
            let existingProducts = try await repository.searchProducts(by: name)
            return existingProducts.contains { product in
                product.productName?.lowercased() == name.lowercased()
            }
        } catch {
            return false // If search fails, allow creation
        }
    }
    
    // MARK: - Open Food Facts Operations
    
    func searchProductByBarcode(_ barcode: String) async {
        isLoadingOpenFoodFacts = true
        errorMessage = nil
        
        do {
            selectedOpenFoodFactsProduct = try await repository.searchProductByBarcode(barcode)
            if selectedOpenFoodFactsProduct == nil {
                errorMessage = "Product not found in Open Food Facts database"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoadingOpenFoodFacts = false
    }
    
    func searchProductsFromOpenFoodFacts(by query: String) async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            openFoodFactsProducts = []
            return
        }
        
        isLoadingOpenFoodFacts = true
        errorMessage = nil
        
        do {
            openFoodFactsProducts = try await repository.searchProductsFromOpenFoodFacts(by: query)
            print("📱 ViewModel received \(openFoodFactsProducts.count) products")
            for (index, product) in openFoodFactsProducts.enumerated() {
                print("📦 Product \(index): \(product.productName ?? "nil") - \(product.code ?? "nil")")
            }
        } catch {
            errorMessage = error.localizedDescription
            openFoodFactsProducts = []
            print("❌ ViewModel error: \(error)")
        }
        
        isLoadingOpenFoodFacts = false
    }
    
    func addOpenFoodFactsProductToCart(_ product: OpenFoodFactsProduct) async {
        guard let productName = product.productName else {
            errorMessage = "Product name is required"
            return
        }
        
        do {
            if await isDuplicateProduct(name: productName) {
                errorMessage = "Product '\(productName)' already exists in your list"
                return
            }
            
            let id = UUID().uuidString
            _ = try await repository.createProduct(
                id: id,
                productName: productName,
                brand: product.brands,
                category: product.categories,
                price: 0.0,
                currency: "USD",
                store: nil,
                location: nil,
                imageURL: product.imageFrontURL ?? product.imageURL,
                barcode: product.code
            )
            await loadAllProducts()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func clearOpenFoodFactsSearch() {
        openFoodFactsProducts = []
        selectedOpenFoodFactsProduct = nil
        errorMessage = nil
    }
    
    func testOpenFoodFactsAPI() async {
        await repository.testOpenFoodFactsAPI()
    }
}

// This code was generated with the help of Claude, saving me 1 hour of research and development.

