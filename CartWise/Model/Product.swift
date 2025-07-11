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

// Extension to add convenience methods to Core Data Product
extension Product {
    // Convert categories string to ProductCategory enum
    var productCategory: ProductCategory? {
        guard let categories = categories else { return nil }
        return ProductCategory.from(categories)
    }
    
    // Sample products for testing (will be replaced with real API data)
    static func sampleProducts(context: NSManagedObjectContext) -> [Product] {
        let sampleData = [
            // Bakery
            (name: "Chocolate Cupcakes", brand: "Sweet Treats", categories: "Bakery", imageURL: nil),
            (name: "White Bread", brand: "Fresh Bakery", categories: "Bakery", imageURL: nil),
            (name: "Wheat Bread", brand: "Healthy Grains", categories: "Bakery", imageURL: nil),
            (name: "Chocolate Chip Cookies", brand: "Cookie Corner", categories: "Bakery", imageURL: nil),
            (name: "Croissants", brand: "French Bakery", categories: "Bakery", imageURL: nil),
            
            // Dairy & Eggs
            (name: "Whole Milk", brand: "Farm Fresh", categories: "Dairy & Eggs", imageURL: nil),
            (name: "Large Eggs", brand: "Happy Hens", categories: "Dairy & Eggs", imageURL: nil),
            (name: "Cheddar Cheese", brand: "Dairy Delight", categories: "Dairy & Eggs", imageURL: nil),
            
            // Produce
            (name: "Bananas", brand: nil, categories: "Produce", imageURL: nil),
            (name: "Apples", brand: nil, categories: "Produce", imageURL: nil),
            (name: "Spinach", brand: nil, categories: "Produce", imageURL: nil),
            
            // Meat & Seafood
            (name: "Chicken Breast", brand: "Farm Raised", categories: "Meat & Seafood", imageURL: nil),
            (name: "Salmon Fillet", brand: "Ocean Fresh", categories: "Meat & Seafood", imageURL: nil),
            
            // Beverages
            (name: "Orange Juice", brand: "Sunshine", categories: "Beverages", imageURL: nil),
            (name: "Coffee Beans", brand: "Morning Brew", categories: "Beverages", imageURL: nil),
            
            // Pantry Items
            (name: "Pasta", brand: "Italian Kitchen", categories: "Pantry Items", imageURL: nil),
            (name: "Olive Oil", brand: "Mediterranean", categories: "Pantry Items", imageURL: nil),
            
            // Frozen Foods
            (name: "Frozen Pizza", brand: "Quick Bite", categories: "Frozen Foods", imageURL: nil),
            (name: "Ice Cream", brand: "Sweet Dreams", categories: "Frozen Foods", imageURL: nil),
            
            // Household & Personal Care
            (name: "Toothpaste", brand: "Fresh Smile", categories: "Household & Personal Care", imageURL: nil),
            (name: "Paper Towels", brand: "Clean & Soft", categories: "Household & Personal Care", imageURL: nil)
        ]
        
        return sampleData.map { data in
            Product(context: context, 
                   barcode: UUID().uuidString, 
                   name: data.name, 
                   brands: data.brand, 
                   imageURL: data.imageURL, 
                   nutritionGrade: nil, 
                   categories: data.categories, 
                   ingredients: nil)
        }
    }
}
