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
    let products: [GroceryPriceData]?
    
    var allProducts: [GroceryPriceData] {
        return data ?? products ?? []
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

