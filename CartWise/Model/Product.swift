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

// MARK: - Main Response Model
struct APIResponse: Codable {
    let success: Bool
    let pagination: Pagination
    let products: [APIProduct]
}

// MARK: - Pagination Model
struct Pagination: Codable {
    let currentPage: Int
    let nextPage: Int?
    let totalPages: String  // Note: This comes as string, not int
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
