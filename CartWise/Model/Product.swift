//
//  Product.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/7/25.
//

import CoreData
import Foundation

// Date extension for ISO8601 formatting
extension Date {
    var ISO8601String: String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
}

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
    let success: Bool
    let pagination: PaginationInfo?
    let products: [GroceryPriceData]?
    
    // Legacy support - map to old format
    var status: Int { success ? 200 : 400 }
    var message: String { success ? "Success" : "Error" }
    var data: [GroceryPriceData]? { products }
}

struct PaginationInfo: Codable, Sendable {
    let currentPage: Int
    let nextPage: Int?
    let totalPages: Int
}

struct GroceryPriceData: Codable, Sendable {
    let name: String
    let price: String
    let currency: String
    let customerReview: String?
    let customerReviewCount: String?
    let shippingMessage: String?
    let amazonLink: String?
    let image: String?
    let boughtInfo: String?
    
    // Map to your existing model format
    var id: String { amazonLink?.components(separatedBy: "/dp/").last?.components(separatedBy: "?").first ?? UUID().uuidString }
    var productName: String { name }
    var brand: String? { 
        // Extract brand from product name (first part before comma or dash)
        let components = name.components(separatedBy: CharacterSet(charactersIn: ", -"))
        return components.first?.trimmingCharacters(in: .whitespaces)
    }
    var category: String? { nil } // Will be set based on search context
    var priceValue: Double { 
        // Extract numeric price from string like "$7.29"
        let cleanPrice = price.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")
        return Double(cleanPrice) ?? 0.0
    }
    var store: String { "Amazon" }
    var location: String? { nil }
    var lastUpdated: String { Date().ISO8601String }
    var imageURL: String? { image }
    var barcode: String? { nil }
    
    enum CodingKeys: String, CodingKey {
        case name, price, currency, customerReview, customerReviewCount
        case shippingMessage, amazonLink, image, boughtInfo
    }
}
