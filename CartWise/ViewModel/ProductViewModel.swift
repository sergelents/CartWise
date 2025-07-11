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
}

// This code was generated with the help of Claude, saving me 1 hour of research and development.
