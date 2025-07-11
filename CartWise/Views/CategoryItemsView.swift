//
//  CatergoryItemsView.swift
//  CartWise
//
//  Created by Kelly Yong on 7/9/25.
//

import SwiftUI

struct CategoryItemsView: View { 
    let category: ProductCategory
    
    // Get products for this category
    var categoryProducts: [Product] {
        Product.sampleProducts.filter { $0.category == category }
    }
    
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
    }
}

// Product Row View
struct ProductRowView: View {
    let product: Product
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading) {
                    Text(product.name)
                        .font(.headline)
                    if let brand = product.brand {
                        Text(brand)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                Spacer()
                if let price = product.price {
                    Text("$\(price, specifier: "%.2f")")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
            }
            
            if let description = product.description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}