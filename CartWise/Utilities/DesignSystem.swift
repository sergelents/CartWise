//
//  DesignSystem.swift
//  CartWise
//
//  Created by Alex Kumar on 7/12/25.
//

import SwiftUI

struct DesignSystem {
    static let primaryColor = Color(hex: "#007AFF") // Blue, matching iOS/Figma
    static let accentColor = Color(hex: "#FF9500") // Orange, for links/buttons
    static let backgroundColor = Color(.systemGray6)
    static let bodyFont = Font.system(size: 16, weight: .regular)
    static let buttonFont = Font.system(size: 16, weight: .bold)
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgb)
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255.0,
            green: Double((rgb >> 8) & 0xFF) / 255.0,
            blue: Double(rgb & 0xFF) / 255.0
        )
    }
}
