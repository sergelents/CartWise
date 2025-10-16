//
//  MealMe.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 10/16/25.
//

// MARK: - MealMe Response Models (minimal for images)

struct MealMeSearchResponse: Decodable {
    let results: [MealMeItem]
}

struct MealMeItem: Decodable {
    let title: String?
    let name: String?
    let imageUrl: String?
    let image: String?
    let url: String?
    let link: String?
    let price: String?
    let currency: String?
}
