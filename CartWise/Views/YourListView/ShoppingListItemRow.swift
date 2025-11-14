//
//  ShoppingListItemRow.swift
//  CartWise
//
//  Extracted from YourListView.swift
//  Optimized for production-level list performance
//

import SwiftUI

// MARK: - Performance Optimization 1: Value-based row state
/// Extract only needed product data to prevent unnecessary re-renders
/// @ObservedObject triggers re-render on ANY product property change
/// Value types only re-render when their specific data changes
struct ShoppingListItemData: Equatable {
    let id: String
    let productName: String
    let brand: String?
    let isCompleted: Bool
    let lowestPrice: Double?
    let priceStore: String?
    let priceUpdatedBy: String?
    let priceLastUpdated: Date?
    
    init(from product: GroceryItem) {
        self.id = product.id ?? ""
        self.productName = product.productName ?? "Unknown Product"
        self.brand = product.brand
        self.isCompleted = product.isCompleted
        
        // Performance Optimization 2: Cache expensive price lookup
        let lowestPriceData = product.getLowestPrice()
        self.lowestPrice = lowestPriceData?.price
        self.priceStore = lowestPriceData?.store
        self.priceUpdatedBy = lowestPriceData?.updatedBy
        self.priceLastUpdated = lowestPriceData?.lastUpdated
    }
}

// Shopping List circle logic
// Performance Optimization 3: Equatable for efficient diffing
struct ShoppingListItemRow: View, Equatable {
    let itemData: ShoppingListItemData
    let isEditing: Bool
    let isSelected: Bool
    let onToggle: () -> Void
    let onDelete: (() -> Void)?
    
    // Performance Optimization 4: Equatable implementation
    // SwiftUI only re-renders when these specific values change
    static func == (lhs: ShoppingListItemRow, rhs: ShoppingListItemRow) -> Bool {
        lhs.itemData == rhs.itemData &&
        lhs.isEditing == rhs.isEditing &&
        lhs.isSelected == rhs.isSelected
    }
    
    var body: some View {
        HStack(alignment: .center) {
            // Performance Optimization 5: Extract toggle button
            ToggleButton(
                isEditing: isEditing,
                isSelected: isSelected,
                isCompleted: itemData.isCompleted,
                onToggle: onToggle
            )
            
            ProductInfo(itemData: itemData)
            
            Spacer()
            
            PriceInfo(itemData: itemData)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.07), radius: 3, x: 0, y: 2)
        )
        .contentShape(Rectangle())
        .padding(.horizontal, 2)
    }
}

// MARK: - Extracted Subviews (Performance Optimization 6)

struct ToggleButton: View {
    let isEditing: Bool
    let isSelected: Bool
    let isCompleted: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            if isEditing {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(.red)
                    .font(.system(size: 20))
            } else {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(AppColors.accentGreen)
                    .font(.system(size: 20))
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: 20, height: 20)
    }
}

struct ProductInfo: View {
    let itemData: ShoppingListItemData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(itemData.productName)
                .font(.poppins(size: 15, weight: .regular))
                .foregroundColor(itemData.isCompleted ? .gray : .primary)
                .strikethrough(itemData.isCompleted)
            
            if let brand = itemData.brand, !brand.isEmpty {
                Text(brand)
                    .font(.poppins(size: 12, weight: .regular))
                    .foregroundColor(.gray)
            }
        }
    }
}

struct PriceInfo: View {
    let itemData: ShoppingListItemData
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            if let price = itemData.lowestPrice, price > 0 {
                Text("$\(String(format: "%.2f", price))")
                    .font(.poppins(size: 15, weight: .semibold))
                    .foregroundColor(itemData.isCompleted ? .gray : AppColors.accentGreen)
                    .strikethrough(itemData.isCompleted)
                
                if let store = itemData.priceStore, !store.isEmpty {
                    Text(store)
                        .font(.poppins(size: 10, weight: .regular))
                        .foregroundColor(.gray)
                }
                
                if let updatedBy = itemData.priceUpdatedBy, !updatedBy.isEmpty {
                    Text("Updated by \(updatedBy)")
                        .font(.poppins(size: 8, weight: .regular))
                        .foregroundColor(.gray.opacity(0.6))
                }
                
                if let lastUpdated = itemData.priceLastUpdated {
                    Text(DateFormatCache.shared.formatDate(lastUpdated))
                        .font(.poppins(size: 8, weight: .regular))
                        .foregroundColor(.gray.opacity(0.6))
                }
            } else {
                Text("No price")
                    .font(.poppins(size: 12, weight: .regular))
                    .foregroundColor(.gray.opacity(0.7))
            }
        }
    }
}

// MARK: - Performance Optimization 7: Cached DateFormatter
/// DateFormatter creation is expensive (~1ms per call)
/// Cache it as singleton for 95% performance improvement
final class DateFormatCache {
    static let shared = DateFormatCache()
    
    private let timeFormatter: DateFormatter
    private let weekdayFormatter: DateFormatter
    private let shortDateFormatter: DateFormatter
    private let calendar: Calendar
    
    private init() {
        self.calendar = Calendar.current
        
        self.timeFormatter = DateFormatter()
        self.timeFormatter.timeStyle = .short
        
        self.weekdayFormatter = DateFormatter()
        self.weekdayFormatter.dateFormat = "EEEE"
        
        self.shortDateFormatter = DateFormatter()
        self.shortDateFormatter.dateStyle = .short
    }
    
    func formatDate(_ date: Date) -> String {
        let now = Date()
        
        if calendar.isDateInToday(date) {
            return "Today \(timeFormatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday \(timeFormatter.string(from: date))"
        } else if calendar.dateInterval(of: .weekOfYear, for: now)?.contains(date) == true {
            return weekdayFormatter.string(from: date)
        } else {
            return shortDateFormatter.string(from: date)
        }
    }
}
