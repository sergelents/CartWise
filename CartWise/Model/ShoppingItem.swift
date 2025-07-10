//
//  ShoppingItem.swift
//  CartWise
//
//  Created by Brenna Wilson on 7/9/25.
//

import Foundation

struct ShoppingItem: Identifiable {
    let id = UUID()
    let name: String
    let details: String
    let price: Double
}


struct SampleData {
    static let items: [ShoppingItem] = [
        ShoppingItem(name: "Eggs", details: "Happy Egg Co. | Free Range | 12 ct", price: 8.56),
        ShoppingItem(name: "Butter", details: "Vital Farms Grass Fed | Unsalted | 8 oz", price: 4.54),
        ShoppingItem(name: "Bread", details: "Dave’s Killer Bread | 21 Whole Grains | 24 oz", price: 7.99),
        ShoppingItem(name: "Granola", details: "Purely Elizabeth | Ancient Grain | 12 oz", price: 9.75)
    ]
}
