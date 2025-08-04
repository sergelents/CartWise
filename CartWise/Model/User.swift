//
//  User.swift
//  CartWise
//
//  Created by Alex Kumar on 7/12/25.
//
import Foundation
struct User: Identifiable, Codable {
    let id: String
    let username: String
    let updates: Int
    var level: String {
        updates > 50 ? "Master Shopper" : updates > 10 ? "Shopper" : "Newbie"
    }
}
