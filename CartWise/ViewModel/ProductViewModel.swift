//
//  ProductViewModel.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/7/25.
//
import SwiftUI

@MainActor
@Observable
final class ProductViewModel {
    var products: [Product] = []
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
    
}
