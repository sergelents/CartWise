//
//  Product.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/7/25.
//

import CoreData
import Foundation

// Product Categories Enum
enum ProductCategory: String, CaseIterable, Identifiable, Codable {
    case meat = "Meat & Seafood"
    case dairy = "Dairy & Eggs"
    case bakery = "Bakery"
    case produce = "Produce"
    case pantry = "Pantry Items"
    case beverages = "Beverages"
    case frozen = "Frozen Foods"
    case household = "Household & Personal Care"
    
    var id: String { rawValue }
    
    // Helper to convert from API string to enum
    static func from(_ string: String?) -> ProductCategory? {
        guard let string = string else { return nil }
        return ProductCategory.allCases.first { category in
            string.localizedCaseInsensitiveContains(category.rawValue)
        }
    }
}

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

// Local Product Model for the app
struct Product: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let brand: String?
    let price: Double?
    let imageURL: String?
    let category: ProductCategory
    let description: String?
    
    // Sample products for each category
    static let sampleProducts: [Product] = [
        // Bakery
        Product(name: "Chocolate Cupcakes", brand: "Sweet Treats", price: 4.99, imageURL: nil, category: .bakery, description: "Delicious chocolate cupcakes with frosting"),
        Product(name: "White Bread", brand: "Fresh Bakery", price: 2.49, imageURL: nil, category: .bakery, description: "Soft white bread, perfect for sandwiches"),
        Product(name: "Wheat Bread", brand: "Healthy Grains", price: 3.99, imageURL: nil, category: .bakery, description: "Whole wheat bread with seeds"),
        Product(name: "Chocolate Chip Cookies", brand: "Cookie Corner", price: 5.99, imageURL: nil, category: .bakery, description: "Fresh baked chocolate chip cookies"),
        Product(name: "Croissants", brand: "French Bakery", price: 3.49, imageURL: nil, category: .bakery, description: "Buttery French croissants"),
        
        // Dairy & Eggs
        Product(name: "Whole Milk", brand: "Farm Fresh", price: 3.99, imageURL: nil, category: .dairy, description: "Fresh whole milk"),
        Product(name: "Large Eggs", brand: "Happy Hens", price: 4.49, imageURL: nil, category: .dairy, description: "Farm fresh large eggs"),
        Product(name: "Cheddar Cheese", brand: "Dairy Delight", price: 6.99, imageURL: nil, category: .dairy, description: "Sharp cheddar cheese block"),
        
        // Produce
        Product(name: "Bananas", brand: nil, price: 1.99, imageURL: nil, category: .produce, description: "Fresh yellow bananas"),
        Product(name: "Apples", brand: nil, price: 3.99, imageURL: nil, category: .produce, description: "Crisp red apples"),
        Product(name: "Spinach", brand: nil, price: 2.49, imageURL: nil, category: .produce, description: "Fresh spinach leaves"),
        
        // Meat & Seafood
        Product(name: "Chicken Breast", brand: "Farm Raised", price: 8.99, imageURL: nil, category: .meat, description: "Boneless skinless chicken breast"),
        Product(name: "Salmon Fillet", brand: "Ocean Fresh", price: 12.99, imageURL: nil, category: .meat, description: "Fresh Atlantic salmon"),
        
        // Beverages
        Product(name: "Orange Juice", brand: "Sunshine", price: 4.99, imageURL: nil, category: .beverages, description: "100% pure orange juice"),
        Product(name: "Coffee Beans", brand: "Morning Brew", price: 9.99, imageURL: nil, category: .beverages, description: "Premium coffee beans"),
        
        // Pantry Items
        Product(name: "Pasta", brand: "Italian Kitchen", price: 2.99, imageURL: nil, category: .pantry, description: "Spaghetti pasta"),
        Product(name: "Olive Oil", brand: "Mediterranean", price: 7.99, imageURL: nil, category: .pantry, description: "Extra virgin olive oil"),
        
        // Frozen Foods
        Product(name: "Frozen Pizza", brand: "Quick Bite", price: 6.99, imageURL: nil, category: .frozen, description: "Pepperoni frozen pizza"),
        Product(name: "Ice Cream", brand: "Sweet Dreams", price: 4.99, imageURL: nil, category: .frozen, description: "Vanilla ice cream"),
        
        // Household & Personal Care
        Product(name: "Toothpaste", brand: "Fresh Smile", price: 3.99, imageURL: nil, category: .household, description: "Mint toothpaste"),
        Product(name: "Paper Towels", brand: "Clean & Soft", price: 5.99, imageURL: nil, category: .household, description: "Absorbent paper towels")
    ]
}
