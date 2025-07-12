//
//  YourListView.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/5/25.
//  Edited by Brenna Wilonek on 7/10/25.
//  Enhanced with AI assistance from Cursor AI for UI improvements and functionality. 
//  This saved me 4-5 hours of work learning swift UI syntax.
//

import SwiftUI
import UIKit



struct YourListView: View {
    @State private var suggestedStore: String = "Whole Foods Market"
    @State private var storeAddress: String = "1701 Wewatta St."
    @State private var total: Double = 43.00
    @State private var allItemsChecked: Bool = false
    @State private var isEditing: Bool = false
    @State private var selectedItemsForDeletion: Set<UUID> = []
    // Static sample data
    @State private var items: [ShoppingItem] = SampleData.shoppingItems
    
    // Navigation state
    @State private var selectedTabIndex: Int = 0
    @State private var showingRatingPrompt: Bool = false
    
    var body: some View {
        MainContentView(
            items: $items,
            isEditing: $isEditing,
            allItemsChecked: $allItemsChecked,
            selectedItemsForDeletion: $selectedItemsForDeletion,
            suggestedStore: suggestedStore,
            storeAddress: storeAddress,
            total: total,
            selectedTabIndex: $selectedTabIndex,
            showingRatingPrompt: $showingRatingPrompt
        )
        .sheet(isPresented: $showingRatingPrompt) {
            RatingPromptView()
        }
    }
}

// MARK: - Main Content View
struct MainContentView: View {
    @Binding var items: [ShoppingItem]
    @Binding var isEditing: Bool
    @Binding var allItemsChecked: Bool
    @Binding var selectedItemsForDeletion: Set<UUID>
    let suggestedStore: String
    let storeAddress: String
    let total: Double
    @Binding var selectedTabIndex: Int
    @Binding var showingRatingPrompt: Bool
    
    var body: some View {
        ZStack {
            // Background
            AppColors.backgroundSecondary
                .ignoresSafeArea()
            
            // Main Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Shopping List")
                            .font(.poppins(size:32, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("\(items.count) items • $\(String(format: "%.2f", items.reduce(0) { $0 + $1.price }))")
                            .font(.poppins(size:15, weight: .regular))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Item List Card
                    ShoppingListCard(
                        items: $items,
                        isEditing: $isEditing,
                        allItemsChecked: $allItemsChecked,
                        selectedItemsForDeletion: $selectedItemsForDeletion,
                        showingRatingPrompt: $showingRatingPrompt
                    )

                    // Store Card
                    StoreCard(
                        suggestedStore: suggestedStore,
                        storeAddress: storeAddress,
                        total: items.reduce(0) { $0 + $1.price }
                    )

                    Spacer()
                }
                .padding(.top)
            }
            
            // Bottom Tab Bar
            VStack {
                Spacer()
                BottomTabBar(selectedTabIndex: $selectedTabIndex)
            }
            .ignoresSafeArea(.container, edges: .bottom)
        }
    }
}

// MARK: - Shopping List Card
struct ShoppingListCard: View {
    @Binding var items: [ShoppingItem]
    @Binding var isEditing: Bool
    @Binding var allItemsChecked: Bool
    @Binding var selectedItemsForDeletion: Set<UUID>
    @Binding var showingRatingPrompt: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("\(items.count) Items")
                    .font(.poppins(size:15, weight: .regular))
                    .foregroundColor(.gray)
                Spacer()
                Button(action: {
                    if isEditing {
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
                            if allItemsChecked {
                                // Uncheck all items
                                allItemsChecked.toggle()
                                for index in items.indices {
                                    items[index].isCompleted = allItemsChecked
                                }
                            } else {
                                // Check all items and show rating prompt
                                allItemsChecked.toggle()
                                for index in items.indices {
                                    items[index].isCompleted = allItemsChecked
                                }
                                showingRatingPrompt = true
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
            
            // Item List
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(items) { item in
                        ShoppingListItemRow(
                            item: item,
                            isEditing: isEditing,
                            isSelected: selectedItemsForDeletion.contains(item.id),
                            onToggle: {
                                if isEditing {
                                    if selectedItemsForDeletion.contains(item.id) {
                                        selectedItemsForDeletion.remove(item.id)
                                    } else {
                                        selectedItemsForDeletion.insert(item.id)
                                    }
                                } else {
                                    if let index = items.firstIndex(where: { $0.id == item.id }) {
                                        items[index].isCompleted.toggle()
                                    }
                                }
                            },
                            onDelete: {
                                items.removeAll { $0.id == item.id }
                            }
                        )
                    }
                }
                .padding(.top, 8)
            }
            .frame(maxHeight: 200)

            // Add Button
            Button(action: {
                // TODO: Add item functionality
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(width: 44, height: 44)
            .background(
                Circle()
                    .fill(AppColors.accentGreen)
                    .shadow(color: AppColors.accentGreen.opacity(0.3), radius: 8, x: 0, y: 4)
            )
            .padding(.top, 8)
        }
        .padding()
        .background(AppColors.backgroundPrimary)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.07), radius: 3, x: 0, y: 2)
        .padding(.horizontal)
    }
}

// MARK: - Store Card
struct StoreCard: View {
    let suggestedStore: String
    let storeAddress: String
    let total: Double
    
    var body: some View {
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
        .shadow(color: Color.black.opacity(0.07), radius: 3, x: 0, y: 2)
        .padding(.horizontal)
    }
}

// MARK: - Bottom Tab Bar
struct BottomTabBar: View {
    @Binding var selectedTabIndex: Int
    
    var body: some View {
        HStack(spacing: 0) {
            TabButton(
                icon: "list.bullet",
                title: "List",
                isSelected: selectedTabIndex == 0
            ) {
                selectedTabIndex = 0
            }
            
            TabButton(
                icon: "magnifyingglass",
                title: "Search",
                isSelected: selectedTabIndex == 1
            ) {
                selectedTabIndex = 1
            }
            
            TabButton(
                icon: "barcode.viewfinder",
                title: "Scan",
                isSelected: selectedTabIndex == 2
            ) {
                selectedTabIndex = 2
            }
            
            TabButton(
                icon: "person.circle",
                title: "Profile",
                isSelected: selectedTabIndex == 3
            ) {
                selectedTabIndex = 3
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: -4)
        )
        .padding(.horizontal, 12)
    }
}

// MARK: - Tab Button
struct TabButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? AppColors.accentGreen : .gray.opacity(0.7))
                
                Text(title)
                    .font(.poppins(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? AppColors.accentGreen : .gray.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? AppColors.accentGreen.opacity(0.1) : Color.clear)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
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

struct ShoppingListItemRow: View {
    let item: ShoppingItem
    let isEditing: Bool
    let isSelected: Bool
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            Button(action: onToggle) {
                if isEditing {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 20))
                    } else {
                        Circle()
                            .strokeBorder(.red, lineWidth: 1)
                            .frame(width: 20, height: 20)
                    }
                } else {
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

            // Price centered vertically
            Text(String(format: "$%.2f", item.price))
                .font(.poppins(size:15, weight: .regular))
                .foregroundColor(item.isCompleted ? .gray : .primary)
                .frame(minWidth: 60, alignment: .center)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.07), radius: 3, x: 0, y: 2)
        )
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        .padding(.horizontal, 2)
    }
}

#Preview {
    YourListView()
}

// MARK: - Rating Prompt View
struct RatingPromptView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showRatingScreen = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(AppColors.accentGreen)
                
                Text("Have you finished shopping?")
                    .font(.poppins(size:24, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Rate your experience")
                    .font(.poppins(size:16, weight: .regular))
                    .foregroundColor(.gray)
            }
            .padding(.top, 40)
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 12) {
                Button(action: {
                    showRatingScreen = true
                }) {
                    Text("Rate my experience")
                        .font(.poppins(size:16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(AppColors.accentGreen)
                        .cornerRadius(12)
                        .contentShape(Rectangle())
                }
                
                Button(action: {
                    dismiss()
                }) {
                    Text("No thanks")
                        .font(.poppins(size:16, weight: .regular))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .contentShape(Rectangle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(AppColors.backgroundSecondary)
        .sheet(isPresented: $showRatingScreen) {
            ShoppingExperienceRatingView(dismissAll: {
                dismiss() // dismiss the prompt
                showRatingScreen = false // close the rating sheet
            })
        }
    }
}

// MARK: - Shopping Experience Rating View
struct ShoppingExperienceRatingView: View {
    var dismissAll: () -> Void
    @State private var pricingRating: Int = 0
    @State private var overallRating: Int = 0
    
    var body: some View {
        VStack(spacing: 32) {
            Text("Rate your shopping Experience!")
                .font(.poppins(size:28, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.top, 32)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Grocery Store")
                    .font(.poppins(size:20, weight: .bold))
                // TODO: Connect to Google Maps API for live store info
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(AppColors.accentGreen)
                    Text("Whole Foods Market")
                        .font(.poppins(size:17, weight: .semibold))
                    Spacer()
                    Text("1701 Wewatta St.")
                        .font(.poppins(size:15, weight: .regular))
                        .foregroundColor(.gray)
                }
                .padding(12)
                .background(Color.gray.opacity(0.10))
                .cornerRadius(16)
            }
            .padding(.horizontal, 16)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Pricing Accuracy")
                    .font(.poppins(size:20, weight: .bold))
                StarRatingView(rating: $pricingRating, accentColor: AppColors.accentGreen)
            }
            .padding(.horizontal, 16)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Overall Experience")
                    .font(.poppins(size:20, weight: .bold))
                StarRatingView(rating: $overallRating, accentColor: AppColors.accentGreen)
            }
            .padding(.horizontal, 16)
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 12) {
                Button(action: {
                    // TODO: Handle submit logic
                    dismissAll()
                }) {
                    Text("Submit")
                        .font(.poppins(size:16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(AppColors.accentGreen)
                        .cornerRadius(12)
                        .contentShape(Rectangle())
                }
                
                Button(action: {
                    dismissAll()
                }) {
                    Text("Cancel")
                        .font(.poppins(size:16, weight: .regular))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .contentShape(Rectangle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(AppColors.backgroundSecondary)
        .cornerRadius(24)
        .padding(8)
    }
}

// MARK: - Star Rating View
struct StarRatingView: View {
    @Binding var rating: Int
    var accentColor: Color = .yellow
    let maxRating = 5
    
    var body: some View {
        HStack(spacing: 16) {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: rating >= index ? "star.fill" : "star")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 36, height: 36)
                    .foregroundColor(accentColor)
                    .onTapGesture {
                        rating = index
                    }
            }
        }
    }
}

