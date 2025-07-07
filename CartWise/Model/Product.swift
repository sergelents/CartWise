//
//  Product.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/7/25.
//

import CoreData
import Foundation

struct OpenFoodFactsResponse: Codable, Sendable {
    let status: Int
    let product: OpenFoodFactsProduct?
}

struct OpenFoodFactsProduct: Codable, Sendable {
    let code: String
    let productName: String?
    let brands: String?
    let imageURL: String?
    let nutritionGrades: String?
    let categories: String?
    let ingredients: [Ingredient]?
    
    enum CodingKeys: String, CodingKey {
        case code
        case productName = "product_name"
        case brands
        case imageURL = "image_url"
        case nutritionGrades = "nutrition_grades"
        case categories
        case ingredients
    }
}

struct Ingredient: Codable, Sendable {
    let text: String
}
