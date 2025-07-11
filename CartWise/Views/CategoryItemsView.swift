//
//  CatergoryItemsView.swift
//  CartWise
//
//  Created by Kelly Yong on 7/9/25.
//

import SwiftUI

struct CategoryItemsView: View { 
    let category: ProductCategory
    @State private var viewModel = ProductViewModel(repository: ProductRepository())
    
    var body: some View {
        VStack {
            if categoryProducts.isEmpty {
                Text("No products found in this category")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List(categoryProducts) { product in
                    ProductRowView(product: product)
                }
            }
        }
        .navigationTitle(category.rawValue)
        .task {
            await viewModel.loadAllProducts()
        }
    }
    
    // Filter products by category
    private var categoryProducts: [Product] {
        viewModel.products.filter { product in
            product.productCategory == category
        }
    }
}

// Product Row View
struct ProductRowView: View {
    let product: Product
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading) {
                    Text(product.name ?? "Unknown Product")
                        .font(.headline)
                    if let brand = product.brands {
                        Text(brand)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                Spacer()
                // Note: Price will be added when we implements the API
                Text("Price TBD")
                    .font(.headline)
                    .foregroundColor(.blue)
            }
            
            if let ingredients = product.ingredients {
                Text(ingredients)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}