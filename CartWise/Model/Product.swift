//
//  Product.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/7/25.
//

import CoreData
import Foundation

// Product categories enum
enum ProductCategory: String, CaseIterable {
    case none = "Select Category"
    case meat = "Meat & Seafood"
    case dairy = "Dairy & Eggs"
    case bakery = "Bakery"
    case produce = "Produce"
    case pantry = "Pantry Items"
    case beverages = "Beverages"
    case frozen = "Frozen Foods"
    case household = "Household & Personal Care"
}

// Grocery Price API Models
struct GroceryPriceResponse: Codable, Sendable {
    let status: Int?
    let message: String?
    let data: [GroceryPriceData]?
    let success: Bool?
    let products: [AmazonProduct]?
    
    // Computed property to get products from either format
    var allProducts: [GroceryPriceData] {
        if let data = data {
            return data
        } else if let products = products {
            return products.map { amazonProduct in
                GroceryPriceData(
                    id: amazonProduct.amazonLink ?? UUID().uuidString,
                    productName: amazonProduct.name,
                    brand: nil,
                    category: nil,
                    price: extractPrice(from: amazonProduct.price),
                    currency: amazonProduct.currency ?? "$",
                    store: "Amazon",
                    location: nil,
                    lastUpdated: ISO8601DateFormatter().string(from: Date()),
                    imageURL: amazonProduct.image,
                    barcode: nil
                )
            }
        }
        return []
    }
    
    private func extractPrice(from priceString: String) -> Double {
        // Remove currency symbols and clean the string
        let cleaned = priceString.replacingOccurrences(of: "[$€£¥]", with: "", options: .regularExpression)
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Try to extract price using various patterns
        if let price = Double(cleaned) {
            return price
        }
        
        // Try to extract price from strings like "$12.99" or "12.99"
        let pricePattern = #"(\d+\.?\d*)"#
        if let range = cleaned.range(of: pricePattern, options: .regularExpression),
           let price = Double(String(cleaned[range])) {
            return price
        }
        
        return 0.0
    }
}

struct GroceryPriceData: Codable, Sendable {
    let id: String
    let productName: String
    let brand: String?
    let category: String?
    let price: Double
    let currency: String
    let store: String
    let location: String?
    let lastUpdated: String
    let imageURL: String?
    let barcode: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case productName = "product_name"
        case brand
        case category
        case price
        case currency
        case store
        case location
        case lastUpdated = "last_updated"
        case imageURL = "image_url"
        case barcode
    }
}

// Amazon API Response Models (for internal use only)
struct AmazonResponse: Codable, Sendable {
    let products: [AmazonProduct]
}

struct AmazonProduct: Codable, Sendable {
    let name: String
    let price: String
    let currency: String?
    let customerReview: String?
    let customerReviewCount: String?
    let shippingMessage: String?
    let amazonLink: String?
    let image: String?
    let boughtInfo: String?
}