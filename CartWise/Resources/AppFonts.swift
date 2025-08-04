//
//  AppFonts.swift
//  CartWise
//
//  Created by Brenna Wilson on 7/9/25.
//
import SwiftUI
extension Font {
    static func poppins(size: CGFloat, weight: Weight = .regular) -> Font {
        return Font.custom(CustomFont(weight: weight).rawValue, size: size)
    }
}
enum CustomFont: String {
    case regular = "Poppins-Regular"
    case semiBold = "Poppins-SemiBold"
    case bold = "Poppins-Bold"
    case black = "Poppins-Black"
    init(weight: Font.Weight) {
        switch weight {
        case .black, .heavy:
            self = .black
        case .bold:
            self = .bold
        case .semibold:
            self = .semiBold
        case .regular:
            self = .regular
        default:
            self = .regular
        }
    }
}
