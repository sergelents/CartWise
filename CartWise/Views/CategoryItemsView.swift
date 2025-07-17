//
//  CategoryItemsView.swift
//  CartWise
//
//  Created by Kelly Yong on 7/9/25.
//  Enhanced with AI assistance from Cursor AI for sample data implementation and UI improvements.
//  This saved me 2-3 hours of work implementing product display functionality.
//

import SwiftUI

// Simple product item for sample data
struct ProductItem: Identifiable {
    let id = UUID()
    let name: String
    let brand: String?
    let category: ProductCategory
    let nutritionGrade: String?
    let imageURL: String?
}

// Sample data for CategoryItemsView
struct CategorySampleData {
    static let allProducts: [ProductItem] = [
        // Produce
        ProductItem(name: "Organic Bananas", brand: nil, category: .produce, nutritionGrade: "A", imageURL: nil),
        ProductItem(name: "Fresh Apples", brand: nil, category: .produce, nutritionGrade: "A", imageURL: nil),
        ProductItem(name: "Spinach", brand: nil, category: .produce, nutritionGrade: "A", imageURL: nil),
        ProductItem(name: "Broccoli", brand: nil, category: .produce, nutritionGrade: "A", imageURL: nil),
        ProductItem(name: "Sweet Potatoes", brand: nil, category: .produce, nutritionGrade: "A", imageURL: nil),
        ProductItem(name: "Avocados", brand: nil, category: .produce, nutritionGrade: "B", imageURL: nil),
        // Dairy & Eggs
        ProductItem(name: "Whole Milk", brand: "Farm Fresh", category: .dairy, nutritionGrade: "B", imageURL: nil),
        ProductItem(name: "Large Eggs", brand: "Happy Hens", category: .dairy, nutritionGrade: "A", imageURL: nil),
        ProductItem(name: "Cheddar Cheese", brand: "Dairy Delight", category: .dairy, nutritionGrade: "C", imageURL: nil),
        ProductItem(name: "Greek Yogurt", brand: "Creamy Goodness", category: .dairy, nutritionGrade: "A", imageURL: nil),
        // Bakery
        ProductItem(name: "Croissants", brand: "French Bakery", category: .bakery, nutritionGrade: "D", imageURL: nil),
        ProductItem(name: "White Bread", brand: "Fresh Bakery", category: .bakery, nutritionGrade: "C", imageURL: nil),
        ProductItem(name: "Wheat Bread", brand: "Healthy Grains", category: .bakery, nutritionGrade: "B", imageURL: nil),
        ProductItem(name: "Chocolate Cupcakes", brand: "Sweet Treats", category: .bakery, nutritionGrade: "D", imageURL: nil),
        ProductItem(name: "Chocolate Chip Cookies", brand: "Cookie Corner", category: .bakery, nutritionGrade: "D", imageURL: nil),
        // Meat & Seafood
        ProductItem(name: "Chicken Breast", brand: "Farm Raised", category: .meat, nutritionGrade: "A", imageURL: nil),
        ProductItem(name: "Salmon Fillet", brand: "Ocean Fresh", category: .meat, nutritionGrade: "A", imageURL: nil),
        ProductItem(name: "Ground Turkey", brand: "Lean & Healthy", category: .meat, nutritionGrade: "A", imageURL: nil),
        // Frozen Foods
        ProductItem(name: "Frozen Pizza", brand: "Quick Bite", category: .frozen, nutritionGrade: "C", imageURL: nil),
        ProductItem(name: "Ice Cream", brand: "Sweet Dreams", category: .frozen, nutritionGrade: "D", imageURL: nil),
        ProductItem(name: "Frozen Vegetables", brand: "Fresh Frozen", category: .frozen, nutritionGrade: "A", imageURL: nil),
        // Beverages
        ProductItem(name: "Orange Juice", brand: "Sunshine", category: .beverages, nutritionGrade: "B", imageURL: nil),
        ProductItem(name: "Coffee Beans", brand: "Morning Brew", category: .beverages, nutritionGrade: "A", imageURL: nil),
        ProductItem(name: "Green Tea", brand: "Zen Garden", category: .beverages, nutritionGrade: "A", imageURL: nil),
        // Pantry Items
        ProductItem(name: "Pasta", brand: "Italian Kitchen", category: .pantry, nutritionGrade: "C", imageURL: nil),
        ProductItem(name: "Olive Oil", brand: "Mediterranean", category: .pantry, nutritionGrade: "A", imageURL: nil),
        ProductItem(name: "Brown Rice", brand: "Whole Grain", category: .pantry, nutritionGrade: "A", imageURL: nil),
        ProductItem(name: "Quinoa", brand: "Ancient Grains", category: .pantry, nutritionGrade: "A", imageURL: nil),
        // Household & Personal Care
        ProductItem(name: "Toothpaste", brand: "Fresh Smile", category: .household, nutritionGrade: nil, imageURL: nil),
        ProductItem(name: "Paper Towels", brand: "Clean & Soft", category: .household, nutritionGrade: nil, imageURL: nil),
        ProductItem(name: "Dish Soap", brand: "Sparkle Clean", category: .household, nutritionGrade: nil, imageURL: nil)
    ]
}

struct CategoryItemsView: View { 
    let category: ProductCategory
    
    var body: some View {
        VStack {
            if categoryProducts.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "basket")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.gray.opacity(0.7))
                    Text("No products found in this category")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.gray)
                    Text("Products will appear here when available")
                        .font(.system(size: 14))
                        .foregroundColor(.gray.opacity(0.7))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(categoryProducts) { product in
                            ProductCard(product: product)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(category.rawValue)
        .navigationBarTitleDisplayMode(.large)
    }
    
    private var categoryProducts: [ProductItem] {
        return CategorySampleData.allProducts.filter { $0.category == category }
    }
}

// Product Card View
struct ProductCard: View {
    let product: ProductItem
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            HStack(spacing: 12) {
                // Product image placeholder
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    if let brand = product.brand {
                        Text(brand)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }

                    if let nutritionGrade = product.nutritionGrade, !nutritionGrade.isEmpty {
                        Text("Grade: \(nutritionGrade.uppercased())")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                    }
                }
                Spacer()
                // Add to list button
                Button(action: {
                    // TODO: Add to shopping list functionality
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            ProductDetailView(product: product)
        }
    }
}

// Product Detail View
struct ProductDetailView: View {
    let product: ProductItem
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Product Image
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray5))
                        .frame(height: 200)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                        )
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Product Name
                        Text(product.name)
                            .font(.system(size:24, weight: .bold))
                            .foregroundColor(.primary)
                        
                        // Brand
                        if let brand = product.brand {
                            HStack {
                                Text("Brand:")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                                Text(brand)
                                    .font(.system(size: 16))
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        // Nutrition Grade
                        if let nutritionGrade = product.nutritionGrade, !nutritionGrade.isEmpty {
                            HStack {
                                Text("Nutrition Grade:")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                                Text(nutritionGrade.uppercased())
                                    .font(.system(size:16, weight: .bold))
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        // Category
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category:")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                            Text(product.category.rawValue)
                                .font(.system(size: 14))
                                .foregroundColor(.primary)
                                .lineLimit(nil)
                        }
                        
                        // Sample additional info
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Product Details:")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                            Text("This is a sample product from the \(product.category.rawValue) category. Tap the plus button to add it to your shopping list.")
                                .font(.system(size: 14))
                                .foregroundColor(.primary)
                                .lineLimit(nil)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Product Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}