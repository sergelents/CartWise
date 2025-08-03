//
//  TagSeedData.swift
//  CartWise
//
//  Created by Brenna Wilson on 7/27/25.
//
import Foundation
import CoreData
struct TagSeedData {
    static let seededTags: [(name: String, color: String)] = [
        // Original 20 tags
        ("Toilet Paper", "#FF6B6B"),
        ("All-Purpose Cleaner", "#4ECDC4"),
        ("Hand Sanitizer", "#45B7D1"),
        ("Paper Towels", "#96CEB4"),
        ("Dish Soap", "#FFEAA7"),
        ("Laundry Detergent", "#DDA0DD"),
        ("Trash Bags", "#98D8C8"),
        ("Batteries", "#F7DC6F"),
        ("Light Bulbs", "#BB8FCE"),
        ("First Aid", "#E74C3C"),
        ("Vitamins", "#F39C12"),
        ("Pet Food", "#8E44AD"),
        ("Baby Items", "#E91E63"),
        ("Office Supplies", "#607D8B"),
        ("Kitchen Essentials", "#795548"),
        ("Bathroom Items", "#9C27B0"),
        ("Cleaning Supplies", "#00BCD4"),
        ("Personal Care", "#FF9800"),
        ("Snacks", "#4CAF50"),
        ("Beverages", "#2196F3"),
        // Energy Drinks (as requested)
        ("Energy Drink", "#FF5722"),
        ("Red Bull", "#D32F2F"),
        ("Monster", "#FF9800"),
        ("Rockstar", "#FFC107"),
        ("Bang", "#9C27B0"),
        ("5-Hour Energy", "#FFEB3B"),
        ("NOS", "#F44336"),
        ("Amp", "#E91E63"),
        ("Full Throttle", "#FF5722"),
        ("Xyience", "#9C27B0"),
        // Store Brands (as requested)
        ("Store Brand", "#607D8B"),
        ("Great Value", "#4CAF50"),
        ("Kirkland", "#2196F3"),
        ("Up&Up", "#FF9800"),
        ("Equate", "#9C27B0"),
        ("Member's Mark", "#795548"),
        ("365 Everyday Value", "#4CAF50"),
        ("Good & Gather", "#2196F3"),
        ("Market Pantry", "#FF9800"),
        ("Simply Nature", "#8BC34A"),
        // Organic (as requested)
        ("Organic", "#4CAF50"),
        ("USDA Organic", "#2E7D32"),
        ("Certified Organic", "#388E3C"),
        ("Organic Produce", "#66BB6A"),
        ("Organic Dairy", "#81C784"),
        ("Organic Meat", "#A5D6A7"),
        ("Organic Grains", "#C8E6C9"),
        ("Organic Snacks", "#E8F5E8"),
        ("Organic Beverages", "#4CAF50"),
        ("Organic Personal Care", "#66BB6A"),
        // Food Categories
        ("Fruits", "#FF9800"),
        ("Vegetables", "#4CAF50"),
        ("Meat", "#D32F2F"),
        ("Dairy", "#2196F3"),
        ("Bread", "#8D6E63"),
        ("Cereal", "#FFC107"),
        ("Pasta", "#FF9800"),
        ("Rice", "#8D6E63"),
        ("Beans", "#795548"),
        ("Nuts", "#8D6E63"),
        ("Seeds", "#8D6E63"),
        ("Oils", "#FFC107"),
        ("Condiments", "#FF5722"),
        ("Spices", "#795548"),
        ("Herbs", "#4CAF50"),
        ("Sauces", "#FF5722"),
        ("Dressings", "#FF9800"),
        ("Jams & Jellies", "#E91E63"),
        ("Peanut Butter", "#8D6E63"),
        // Beverage Categories
        ("Coffee", "#8D6E63"),
        ("Tea", "#4CAF50"),
        ("Juice", "#FF9800"),
        ("Soda", "#F44336"),
        ("Water", "#2196F3"),
        ("Sports Drinks", "#00BCD4"),
        ("Milk", "#E3F2FD"),
        ("Plant Milk", "#8BC34A"),
        ("Alcoholic Beverages", "#9C27B0"),
        ("Sparkling Water", "#00BCD4"),
        // Health & Wellness
        ("Gluten Free", "#4CAF50"),
        ("Dairy Free", "#2196F3"),
        ("Vegan", "#4CAF50"),
        ("Vegetarian", "#8BC34A"),
        ("Keto", "#9C27B0"),
        ("Paleo", "#795548"),
        ("Low Carb", "#607D8B"),
        ("Sugar Free", "#E91E63"),
        ("Low Sodium", "#00BCD4"),
        ("High Protein", "#FF5722"),
        // Household Categories
        ("Kitchen", "#FF9800"),
        ("Bathroom", "#2196F3"),
        ("Laundry", "#9C27B0"),
        ("Storage", "#607D8B"),
        ("Tools", "#795548"),
        ("Electronics", "#9E9E9E"),
        ("Garden", "#4CAF50"),
        ("Automotive", "#FF5722"),
        ("Hardware", "#795548"),
        ("Seasonal", "#FF9800"),
        // Special Categories
        ("On Sale", "#E91E63"),
        ("New Product", "#4CAF50"),
        ("Limited Edition", "#9C27B0"),
        ("Seasonal Item", "#FF9800"),
        ("Holiday", "#E91E63"),
        ("Gift", "#9C27B0"),
        ("Bulk", "#795548"),
        ("Single Serve", "#2196F3"),
        ("Family Size", "#FF9800"),
        ("Travel Size", "#607D8B"),
        // Dietary Restrictions
        ("Nut Free", "#4CAF50"),
        ("Soy Free", "#8BC34A"),
        ("Egg Free", "#FFC107"),
        ("Fish Free", "#00BCD4"),
        ("Shellfish Free", "#FF9800"),
        ("Wheat Free", "#8D6E63"),
        ("Corn Free", "#FFC107"),
        ("MSG Free", "#4CAF50"),
        ("Artificial Colors", "#E91E63"),
        ("Preservative Free", "#4CAF50")
    ]
    static func seedTags(in context: NSManagedObjectContext) throws {
        // Check if tags already exist
        let request: NSFetchRequest<Tag> = Tag.fetchRequest()
        let existingTags = try context.fetch(request)
        // If we have the full set of tags (100), don't recreate
        if existingTags.count >= seededTags.count {
            return // Tags already seeded
        }
        // If we have some tags but not all, add the missing ones
        let existingTagNames = Set(existingTags.compactMap { $0.name })
        let newTagsToCreate = seededTags.filter { !existingTagNames.contains($0.name) }
        // Create missing tags
        for (name, color) in newTagsToCreate {
            let tag = Tag(context: context, id: UUID().uuidString, name: name, color: color)
        }
        try context.save()
    }
}