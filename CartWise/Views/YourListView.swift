//
//  YourListView.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/5/25.
//

import SwiftUI

struct YourListView: View {
    @State private var suggestedStore: String = "Whole Foods Market"
    @State private var storeAddress: String = "1701 Wewatta St."
    @State private var total: Double = 43.00
    @State private var allItemsChecked: Bool = false
    @State private var isEditing: Bool = false
    @State private var selectedItemsForDeletion: Set<UUID> = []
    
    // Static sample data
    @State private var items: [ShoppingItem] = SampleData.shoppingItems
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Header
                Text("Your Shopping List")
                    .font(.poppins(size:30, weight: .bold))
                    .foregroundColor(AppColors.accentGreen)
                    .padding(.horizontal)

                // Item List Card
                VStack(spacing: 12) {
                    HStack {
                        Text("\(items.count) Items")
                            .font(.poppins(size:15, weight: .regular))
                            .foregroundColor(.gray)
                        Spacer()
                        Button(action: {
                            if isEditing {
                                // Delete selected items
                                items.removeAll { selectedItemsForDeletion.contains($0.id) }
                            }
                            isEditing.toggle()
                        }) {
                            Text(isEditing ? "Delete Selected" : "Edit")
                                .font(.poppins(size:15, weight: .regular))
                                .underline()
                                .foregroundColor(isEditing ? .red : .gray)
                        }
                        Button(action: {
                            allItemsChecked.toggle()
                            for index in items.indices {
                                items[index].isCompleted = allItemsChecked
                            }
                        }) {
                            Image(systemName: allItemsChecked ? "checkmark.circle.fill" : "checkmark.circle")
                                .foregroundColor(AppColors.accentOrange)
                                .font(.system(size: 20))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal)

                    Divider()
                    
                    // Scrollable Item Rows
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(items) { item in
                                HStack(alignment: .top) {
                                    Button(action: {
                                        if isEditing {
                                            // Toggle selection for deletion
                                            if selectedItemsForDeletion.contains(item.id) {
                                                selectedItemsForDeletion.remove(item.id)
                                            } else {
                                                selectedItemsForDeletion.insert(item.id)
                                            }
                                        } else {
                                            // Normal completion toggle
                                            if let index = items.firstIndex(where: { $0.id == item.id }) {
                                                items[index].isCompleted.toggle()
                                            }
                                        }
                                    }) {
                                        if isEditing {
                                            // Show selection state in edit mode
                                            if selectedItemsForDeletion.contains(item.id) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.red)
                                                    .font(.system(size: 20))
                                            } else {
                                                Circle()
                                                    .strokeBorder(.red, lineWidth: 1)
                                                    .frame(width: 20, height: 20)
                                            }
                                        } else {
                                            // Show completion state in normal mode
                                            if item.isCompleted {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(AppColors.accentGreen)
                                                    .font(.system(size: 20))
                                            } else {
                                                Circle()
                                                    .strokeBorder(.gray, lineWidth: 1)
                                                    .frame(width: 20, height: 20)
                                            }
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .frame(width: 20, height: 20)
                                    .padding(.top, 6)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.name)
                                            .font(.poppins(size:15, weight: .regular))
                                            .strikethrough(item.isCompleted)
                                            .foregroundColor(item.isCompleted ? .gray : .primary)
                                        Text(item.details)
                                            .font(.poppins(size:12, weight: .regular))
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    Text(String(format: "$%.2f", item.price))
                                        .font(.poppins(size:15, weight: .regular))
                                        .foregroundColor(item.isCompleted ? .gray : .primary)
                                }
                                .padding(.horizontal)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        items.removeAll { $0.id == item.id }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                    .frame(maxHeight: 200)

                    // Add Button
                    Button(action: {
                        // TODO: Add item functionality
                    }) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 28))
                            .foregroundColor(AppColors.accentGreen)
                    }
                    .padding(.top, 8)
                }
                .padding()
                .background(AppColors.backgroundPrimary)
                .cornerRadius(20)
                .shadow(radius: 3)
                .padding(.horizontal)

                // Suggested Store Card
                VStack(spacing: 10) {
                    Text("Running Total at Suggested Store")
                        .font(.poppins(size:13, weight: .regular))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Divider()
                    Text("$\(Int(total))")
                        .font(.poppins(size:35, weight: .bold))

                    Text(suggestedStore)
                        .font(.poppins(size:19, weight: .semibold))

                    Text(storeAddress)
                        .font(.poppins(size:15, weight: .regular))
                        .foregroundColor(.gray)

                    Button("Change Store") {
                        // TODO: Store picker logic
                    }
                    .font(.poppins(size:15, weight: .bold))
                    .padding(.vertical, 4)
                    .padding(.horizontal, 30)
                    .background(.gray.opacity(0.15))
                    .foregroundColor(AppColors.accentGreen)
                    .cornerRadius(20)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(20)
                .shadow(radius: 3)
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top)
        }
        .background(AppColors.backgroundPrimary)
        .overlay(
            VStack {
                Spacer()
                
                // Bottom Tab Bar
                HStack(spacing: 0) {
                    TabButton(icon: "list.bullet", title: "List", isSelected: true)
                    TabButton(icon: "magnifyingglass", title: "Search", isSelected: false)
                    TabButton(icon: "barcode.viewfinder", title: "Scan", isSelected: false)
                    TabButton(icon: "person.circle", title: "Profile", isSelected: false)
                }
                .background(Color.white)
                .cornerRadius(25, corners: [.topLeft, .topRight])
                .shadow(radius: 5, y: -2)
                .padding(.horizontal, 8)
            }
            .padding(.bottom, 0)
        )
        .ignoresSafeArea(.container, edges: .bottom)
    }
}

// MARK: - Tab Button
struct TabButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(isSelected ? AppColors.accentGreen : .gray)
            
            Text(title)
                .font(.poppins(size: 12, weight: .regular))
                .foregroundColor(isSelected ? AppColors.accentGreen : .gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// MARK: - Sample Data
struct ShoppingItem: Identifiable {
    let id = UUID()
    let name: String
    let details: String
    let price: Double
    var isCompleted: Bool = false
}

struct SampleData {
    static let shoppingItems: [ShoppingItem] = [
        ShoppingItem(name: "Organic Bananas", details: "6 count", price: 2.99),
        ShoppingItem(name: "Whole Milk", details: "1 gallon", price: 4.49),
        ShoppingItem(name: "Chicken Breast", details: "2 lbs", price: 12.99),
        ShoppingItem(name: "Brown Rice", details: "2 lb bag", price: 3.99),
        ShoppingItem(name: "Broccoli", details: "1 head", price: 2.49),
        ShoppingItem(name: "Greek Yogurt", details: "32 oz", price: 5.99),
        ShoppingItem(name: "Olive Oil", details: "16 oz", price: 8.99),
        ShoppingItem(name: "Quinoa", details: "1 lb", price: 6.49),
        ShoppingItem(name: "Sweet Potatoes", details: "3 lbs", price: 4.99),
        ShoppingItem(name: "Almonds", details: "8 oz", price: 7.99),
        ShoppingItem(name: "Spinach", details: "1 bag", price: 3.49),
        ShoppingItem(name: "Salmon", details: "1 lb", price: 15.99),
        ShoppingItem(name: "Avocados", details: "4 count", price: 5.99),
        ShoppingItem(name: "Coconut Oil", details: "14 oz", price: 9.99),
        ShoppingItem(name: "Blueberries", details: "1 pint", price: 4.99),
        ShoppingItem(name: "Ground Turkey", details: "1 lb", price: 6.99),
        ShoppingItem(name: "Cauliflower", details: "1 head", price: 3.99),
        ShoppingItem(name: "Chia Seeds", details: "8 oz", price: 8.49)
    ]
}

#Preview {
    YourListView()
}

