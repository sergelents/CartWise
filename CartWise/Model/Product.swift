//
//  Product.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/7/25.
//

import Foundation
import CoreData

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

// MARK: - Main Response Model
struct APIResponse: Codable {
    let success: Bool
    let pagination: Pagination?
    let products: [APIProduct]
}

// MARK: - Pagination Model
struct Pagination: Codable {
    let currentPage: Int
    let nextPage: Int?
    let totalPages: Int  // Note: This comes as string, not int
}

// MARK: - Product Model
struct APIProduct: Codable {
    let name: String
    let price: String
    let currency: String
    let customerReview: String  // Can be empty string
    let customerReviewCount: String
    let shippingMessage: String  // Can be empty string
    let amazonLink: String
    let image: String
    let boughtInfo: String  // Can be empty string
}

struct Product: Identifiable, Codable {
    let id: String
    let name: String
    let brand: String?
    let category: String?
    let price: Double
    let currency: String
    let store: String?
    let location: String?
    let imageURL: String?
    let barcode: String?
    let isOnSale: Bool
}

// Local price comparison model
struct LocalPriceComparison: Codable, Sendable {
    let productName: String
    let localPrices: [Double]
    
    var averagePrice: Double {
        guard !localPrices.isEmpty else { return 0.0 }
        return localPrices.reduce(0, +) / Double(localPrices.count)
    }
    
    var minPrice: Double {
        localPrices.min() ?? 0.0
    }
    
    var maxPrice: Double {
        localPrices.max() ?? 0.0
    }
}

// Local store price model
struct LocalStorePrice: Codable, Sendable {
    let store: String
    let totalPrice: Double
    let currency: String
    let availableItems: Int
    let unavailableItems: Int
    let itemPrices: [String: Double] // productName -> price
}

// Local price comparison result
struct LocalPriceComparisonResult: Codable, Sendable {
    let storePrices: [LocalStorePrice]
    let bestStore: String?
    let bestTotalPrice: Double
    let bestCurrency: String
    let totalItems: Int
    let availableItems: Int
}

// Price comparison models for UI
struct StorePrice: Codable, Sendable {
    let store: String
    let totalPrice: Double
    let currency: String
    let availableItems: Int
    let unavailableItems: Int
    let itemPrices: [String: Double] // productName -> price
}

struct PriceComparison: Codable, Sendable {
    let storePrices: [StorePrice]
    let bestStore: String?
    let bestTotalPrice: Double
    let bestCurrency: String
    let totalItems: Int
    let availableItems: Int
}
