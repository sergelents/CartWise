//
//  ShoppingListItemRow.swift
//  CartWise
//
//  Extracted from YourListView.swift
//

import SwiftUI

// Shopping List circle logic
struct ShoppingListItemRow: View {
    @ObservedObject var product: GroceryItem
    let isEditing: Bool
    let isSelected: Bool
    let onToggle: () -> Void
    let onDelete: (() -> Void)?
    var body: some View {
        HStack(alignment: .center) {
            Button(action: onToggle) {
                if isEditing {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 20))
                    } else {
                        Image(systemName: "circle")
                            .foregroundColor(.red)
                            .font(.system(size: 20))
                    }
                } else {
                    // Show completion status
                    if product.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppColors.accentGreen)
                            .font(.system(size: 20))
                    } else {
                        Image(systemName: "circle")
                            .foregroundColor(AppColors.accentGreen)
                            .font(.system(size: 20))
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .frame(width: 20, height: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(product.productName ?? "Unknown Product")
                    .font(.poppins(size: 15, weight: .regular))
                    .foregroundColor(product.isCompleted ? .gray : .primary)
                    .strikethrough(product.isCompleted)
                if let brand = product.brand, !brand.isEmpty {
                    Text(brand)
                        .font(.poppins(size: 12, weight: .regular))
                        .foregroundColor(.gray)
                }
            }
            Spacer()
            // Display lowest price and store
            VStack(alignment: .trailing, spacing: 2) {
                if let lowestPrice = product.getLowestPrice(), lowestPrice.price > 0 {
                    Text("$\(String(format: "%.2f", lowestPrice.price))")
                        .font(.poppins(size: 15, weight: .semibold))
                        .foregroundColor(product.isCompleted ? .gray : AppColors.accentGreen)
                        .strikethrough(product.isCompleted)
                    if let store = lowestPrice.store, !store.isEmpty {
                        Text(store)
                            .font(.poppins(size: 10, weight: .regular))
                            .foregroundColor(.gray)
                    }
                    // Display update information
                    if let updatedBy = lowestPrice.updatedBy, !updatedBy.isEmpty {
                        Text("Updated by \(updatedBy)")
                            .font(.poppins(size: 8, weight: .regular))
                            .foregroundColor(.gray.opacity(0.6))
                    }
                    if let lastUpdated = lowestPrice.lastUpdated {
                        Text(formatDate(lastUpdated))
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
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.07), radius: 3, x: 0, y: 2)
        )
        .contentShape(Rectangle()) // Ensure the entire row is tappable
        .padding(.horizontal, 2)
    }
}

// Helper function to format dates
private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    let now = Date()
    let calendar = Calendar.current
    
    if calendar.isDateInToday(date) {
        formatter.timeStyle = .short
        return "Today \(formatter.string(from: date))"
    } else if calendar.isDateInYesterday(date) {
        formatter.timeStyle = .short
        return "Yesterday \(formatter.string(from: date))"
    } else if calendar.dateInterval(of: .weekOfYear, for: now)?.contains(date) == true {
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    } else {
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}