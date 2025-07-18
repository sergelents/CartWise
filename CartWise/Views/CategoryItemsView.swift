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
   let price: Double
   let onSale: Bool
   let salePrice: Double?
   let store: String?
   let category: ProductCategory
   let nutritionGrade: String?
   let imageURL: String?
}

// Sample data for CategoryItemsView
struct CategorySampleData {
   static let allProducts: [ProductItem] = [
       // Produce
       ProductItem(name: "Organic Bananas", brand: nil, price: 2.99, onSale: false, salePrice: nil, store: "Whole Foods", category: .produce, nutritionGrade: "A", imageURL: nil),
       ProductItem(name: "Fresh Apples", brand: nil, price: 3.49, onSale: true, salePrice: 2.99, store: "Trader Joe's", category: .produce, nutritionGrade: "A", imageURL: nil),
       ProductItem(name: "Spinach", brand: nil, price: 2.99, onSale: false, salePrice: nil, store: "Safeway", category: .produce, nutritionGrade: "A", imageURL: nil),
       ProductItem(name: "Broccoli", brand: nil, price: 1.99, onSale: false, salePrice: nil, store: "Whole Foods", category: .produce, nutritionGrade: "A", imageURL: nil),
       ProductItem(name: "Sweet Potatoes", brand: nil, price: 4.99, onSale: true, salePrice: 3.99, store: "Trader Joe's", category: .produce, nutritionGrade: "A", imageURL: nil),
       ProductItem(name: "Avocados", brand: nil, price: 5.99, onSale: false, salePrice: nil, store: "Safeway", category: .produce, nutritionGrade: "B", imageURL: nil),
       // Dairy & Eggs
       ProductItem(name: "Whole Milk", brand: "Farm Fresh", price: 4.49, onSale: false, salePrice: nil, store: "Whole Foods", category: .dairy, nutritionGrade: "B", imageURL: nil),
       ProductItem(name: "Large Eggs", brand: "Happy Hens", price: 6.99, onSale: true, salePrice: 5.99, store: "Trader Joe's", category: .dairy, nutritionGrade: "A", imageURL: nil),
       ProductItem(name: "Cheddar Cheese", brand: "Dairy Delight", price: 8.99, onSale: false, salePrice: nil, store: "Safeway", category: .dairy, nutritionGrade: "C", imageURL: nil),
       ProductItem(name: "Greek Yogurt", brand: "Creamy Goodness", price: 5.99, onSale: false, salePrice: nil, store: "Whole Foods", category: .dairy, nutritionGrade: "A", imageURL: nil),
       // Bakery
       ProductItem(name: "Croissants", brand: "French Bakery", price: 3.99, onSale: false, salePrice: nil, store: "Whole Foods", category: .bakery, nutritionGrade: "D", imageURL: nil),
       ProductItem(name: "White Bread", brand: "Fresh Bakery", price: 2.99, onSale: true, salePrice: 2.49, store: "Trader Joe's", category: .bakery, nutritionGrade: "C", imageURL: nil),
       ProductItem(name: "Wheat Bread", brand: "Healthy Grains", price: 3.49, onSale: false, salePrice: nil, store: "Safeway", category: .bakery, nutritionGrade: "B", imageURL: nil),
       ProductItem(name: "Chocolate Cupcakes", brand: "Sweet Treats", price: 4.99, onSale: false, salePrice: nil, store: "Whole Foods", category: .bakery, nutritionGrade: "D", imageURL: nil),
       ProductItem(name: "Chocolate Chip Cookies", brand: "Cookie Corner", price: 3.99, onSale: true, salePrice: 2.99, store: "Trader Joe's", category: .bakery, nutritionGrade: "D", imageURL: nil),
       // Meat & Seafood
       ProductItem(name: "Chicken Breast", brand: "Farm Raised", price: 12.99, onSale: false, salePrice: nil, store: "Whole Foods", category: .meat, nutritionGrade: "A", imageURL: nil),
       ProductItem(name: "Salmon Fillet", brand: "Ocean Fresh", price: 15.99, onSale: true, salePrice: 12.99, store: "Trader Joe's", category: .meat, nutritionGrade: "A", imageURL: nil),
       ProductItem(name: "Ground Turkey", brand: "Lean & Healthy", price: 8.99, onSale: false, salePrice: nil, store: "Safeway", category: .meat, nutritionGrade: "A", imageURL: nil),
       // Frozen Foods
       ProductItem(name: "Frozen Pizza", brand: "Quick Bite", price: 6.99, onSale: false, salePrice: nil, store: "Whole Foods", category: .frozen, nutritionGrade: "C", imageURL: nil),
       ProductItem(name: "Ice Cream", brand: "Sweet Dreams", price: 4.99, onSale: true, salePrice: 3.99, store: "Trader Joe's", category: .frozen, nutritionGrade: "D", imageURL: nil),
       ProductItem(name: "Frozen Vegetables", brand: "Fresh Frozen", price: 3.99, onSale: false, salePrice: nil, store: "Safeway", category: .frozen, nutritionGrade: "A", imageURL: nil),
       // Beverages
       ProductItem(name: "Orange Juice", brand: "Sunshine", price: 4.49, onSale: false, salePrice: nil, store: "Whole Foods", category: .beverages, nutritionGrade: "B", imageURL: nil),
       ProductItem(name: "Coffee Beans", brand: "Morning Brew", price: 12.99, onSale: true, salePrice: 9.99, store: "Trader Joe's", category: .beverages, nutritionGrade: "A", imageURL: nil),
       ProductItem(name: "Green Tea", brand: "Zen Garden", price: 5.99, onSale: false, salePrice: nil, store: "Safeway", category: .beverages, nutritionGrade: "A", imageURL: nil),
       // Pantry Items
       ProductItem(name: "Pasta", brand: "Italian Kitchen", price: 2.99, onSale: false, salePrice: nil, store: "Whole Foods", category: .pantry, nutritionGrade: "C", imageURL: nil),
       ProductItem(name: "Olive Oil", brand: "Mediterranean", price: 8.99, onSale: true, salePrice: 6.99, store: "Trader Joe's", category: .pantry, nutritionGrade: "A", imageURL: nil),
       ProductItem(name: "Brown Rice", brand: "Whole Grain", price: 3.99, onSale: false, salePrice: nil, store: "Safeway", category: .pantry, nutritionGrade: "A", imageURL: nil),
       ProductItem(name: "Quinoa", brand: "Ancient Grains", price: 6.99, onSale: false, salePrice: nil, store: "Whole Foods", category: .pantry, nutritionGrade: "A", imageURL: nil),
       // Household & Personal Care
       ProductItem(name: "Toothpaste", brand: "Fresh Smile", price: 3.99, onSale: false, salePrice: nil, store: "Safeway", category: .household, nutritionGrade: nil, imageURL: nil),
       ProductItem(name: "Paper Towels", brand: "Clean & Soft", price: 4.99, onSale: true, salePrice: 3.99, store: "Trader Joe's", category: .household, nutritionGrade: nil, imageURL: nil),
       ProductItem(name: "Dish Soap", brand: "Sparkle Clean", price: 2.99, onSale: false, salePrice: nil, store: "Whole Foods", category: .household, nutritionGrade: nil, imageURL: nil)
   ]
}

struct CategoryItemsView: View {
   let category: ProductCategory
   @State private var selectedItemsToAdd: Set<UUID> = []
  
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
                           ProductCard(
                               product: product,
                               isSelected: selectedItemsToAdd.contains(product.id),
                               onToggle: {
                                   if selectedItemsToAdd.contains(product.id) {
                                       selectedItemsToAdd.remove(product.id)
                                   } else {
                                       selectedItemsToAdd.insert(product.id)
                                   }
                               }
                           )
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
   let isSelected: Bool
   let onToggle: () -> Void

   // Display product details when tapped
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
               Button(action: onToggle) {
                   // TODO: Add to shopping list functionality
                   if isSelected {
                       Image(systemName: "checkmark.circle.fill")
                       .foregroundColor(Color.accentColorGreen)
                       .font(.system(size: 24))
                   } else {
                       Image(systemName: "plus.circle.fill")
                       .font(.system(size: 24))
                       .foregroundColor(Color.accentColorBlue)
                   }
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
    
    // ProductViewModel for adding to shopping list
    @StateObject private var productViewModel = ProductViewModel(repository: ProductRepository())

    // Adding to shopping list and to favorites
    @State private var isAddingToFavorites = false
    @State private var isAddingToShoppingList = false
    @State private var showingSuccessMessage = false

    // Dismissing the view
    @Environment(\.dismiss) private var dismiss
  
   var body: some View {
       NavigationView {
           ScrollView {
               VStack(alignment: .center, spacing: 18) {
                  
                   // Store View
                   if let store = product.store {
                       // TODO: Add store address
                       StoreView(store: store, storeAddress: "1701 Wewatta St.")
                   }

                   // Product Name View
                   ProductNameView(product: product)

                   // Product Image View
                   ProductImageView(product: product)

                   // Product Price View
                   // TODO: Need to update data model
                   ProductPriceView(
                       product: product,
                       lastUpdated: "7/17/2025",
                       lastUpdatedBy: "Kelly Yong"
                   )

                    // Add to Shopping List and Add to Favorites View
                    AddToShoppingListAndFavoritesView(
                        onAddToShoppingList: {
                            addToShoppingList()
                        }, 
                        onAddToFavorites: {
                            isAddingToFavorites.toggle()
                        }
                    )

                   // Update Price View
                   UpdatePriceView(
                       product: product,
                       onUpdatePrice: {
                           // TODO: Update price functionality
                       },
                       lastUpdated: "7/17/2025",
                       lastUpdatedBy: "Kelly Yong"
                   )
               }
               .padding(.horizontal, 24)

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
       .alert("Added to Shopping List!", isPresented: $showingSuccessMessage) {
           Button("OK") { }
       } message: {
           Text("\(product.name) has been added to your shopping list.")
       }
   }
         private func addToShoppingList() {
         Task {
             // Create product using ProductViewModel
             await productViewModel.createProduct(
                 byName: product.name,
                 brand: product.brand,
                 category: product.category.rawValue
             )
             
             // Show success message
             await MainActor.run {
                 showingSuccessMessage = true
             }
         }
     }
}

// Store view
struct StoreView: View {
   let store: String
   let storeAddress: String

   var body: some View {
       HStack(alignment: .center, spacing: 10) {
           Image(systemName: "mappin.circle")
               .foregroundColor(.blue)
           Text(store)
               .font(.system(size: 16, weight: .bold))
               .foregroundColor(.black)
           Spacer()
           Text(storeAddress)
               .font(.system(size: 12, weight: .regular))
               .foregroundColor(.gray)
       }
       .frame(maxWidth: .infinity, maxHeight: 10, alignment: .center)
       .padding()
       .background(Color.gray.opacity(0.12))
       .cornerRadius(20)
       .shadow(color: Color.black.opacity(0.07), radius: 3, x: 0, y: 2)
       .padding(.horizontal)
   }
}

// Product Name View
struct ProductNameView: View {
   let product: ProductItem

   var body: some View { 
       VStack(alignment: .center, spacing: 10) {
           // Brand and Grade
           HStack {
               // Brand
               if let brand = product.brand {
                   Text(brand)
                       .font(.system(size: 16))
                       .foregroundColor(.secondary)
               }
               // Nutrition Grade
               if let nutritionGrade = product.nutritionGrade, !nutritionGrade.isEmpty {
                   Text(nutritionGrade.uppercased())
                       .font(.system(size: 14,weight: .bold))
                       .foregroundColor(.blue)
               }
           }

           // Product Name
           Text(product.name)
               .font(.system(size: 20, weight: .regular))
               .foregroundColor(.primary)
               .multilineTextAlignment(.center)
               .padding(.horizontal, 10)

           // Sample additional info
           VStack(alignment: .leading, spacing: 8) {
               Text("This is a sample product from the \(product.category.rawValue) category.")
                   .font(.system(size: 14))
                   .foregroundColor(.primary)
                   .lineLimit(nil)
           }
       }
   }
}

// Product Image View
struct ProductImageView: View {
   let product: ProductItem

       var body: some View {
       RoundedRectangle(cornerRadius: 12)
           .fill(Color(.systemGray5))
           .frame(height: 250)
           .overlay(
               Image(systemName: "photo")
                   .font(.system(size: 40))
                   .foregroundColor(.gray)
           )
           .overlay(
               VStack {
                   if product.onSale {
                       Text("Sale")
                           .font(.system(size: 14, weight: .bold))
                           .frame(width: 100, height: 24)
                           .foregroundColor(.white)
                           .background(Color.accentColorOrange.opacity(0.9))
                           .cornerRadius(8)
                   }
                   Spacer()
               }
               .padding(.top, 12)
           )
   }
}

// Product Price View
struct ProductPriceView: View {
   let product: ProductItem
   // TODO: Need to update data model
   var lastUpdated: String
   var lastUpdatedBy: String

   var body: some View {
       VStack(alignment: .center, spacing: 10) {
           HStack {
               if product.onSale, let salePrice = product.salePrice {
                   Text("$\(String(format: "%.2f", salePrice))")
                       .font(.system(size: 28, weight: .bold))
                       .foregroundColor(.red)
                   Text("$\(String(format: "%.2f", product.price))")
                       .font(.system(size: 24, weight: .regular))
                       .strikethrough()
                       .foregroundColor(.gray)
               } else {
                   Text("$\(String(format: "%.2f", product.price))")
                       .font(.system(size: 28, weight: .bold))
                       .foregroundColor(.primary)
               }
           }
           // Last updated by
           Text("Last updated: \(lastUpdated) \n By \(lastUpdatedBy)")
               .font(.system(size: 12, weight: .regular))
               .foregroundColor(.gray)
               .multilineTextAlignment(.center)
       }
   }
}

// Custom Button View
struct CustomButtonView: View {
   let title: String
   let imageName: String
   let fontSize: Int
   let weight: Font.Weight?
   let buttonColor: Color
   let textColor: Color
   let action: () -> Void
   @State var isAdded : Bool = false
   @State var isAddedImageName: String
   @State var isAddedColor: Color
  
   var body: some View {
       Button(action: {
        action()
        self.isAdded.toggle()}) {
           HStack(alignment: .center, spacing: 2) {
               Image(systemName: isAdded ? isAddedImageName : imageName)
                   .font(.system(size: 14))
                   .foregroundColor(textColor)
               Text(title)
                   .font(.system(size: CGFloat(fontSize), weight: weight ?? .regular))
                   .foregroundColor(textColor)
                   .frame(width: 100, height: 10)
           }
           .padding(.vertical, 8)
           .padding(.horizontal, 8)
           .background(isAdded ? isAddedColor : buttonColor)
           .cornerRadius(8)
       }
   }
}

// Buttons Add to Shopping List and Add to Favorites View 
struct AddToShoppingListAndFavoritesView: View {
   let onAddToShoppingList: () -> Void
   let onAddToFavorites: () -> Void

   var body: some View {
       HStack(spacing: 16) {

           // Add to List Button
           CustomButtonView(
               title: "Add to My List",
               imageName: "plus.circle.fill",
               fontSize: 13,
               weight: .bold,
               buttonColor: Color.accentColorBlue,
               textColor: .white,
               action: onAddToShoppingList,
               isAddedImageName: "checkmark.circle.fill",
               isAddedColor: Color.accentColorGreen
           )
           Spacer()
           // Add to Favorite Button
           CustomButtonView(
               title: "Add to Favorite",
               imageName: "heart.circle",
               fontSize: 13,
               weight: .bold,
               buttonColor: Color.accentColorCoral,
               textColor: .white,
               action: onAddToFavorites,
               isAddedImageName: "heart.fill",
               isAddedColor: Color.accentColorRed
           )
       }
       .padding(.horizontal, 10)
       .padding(.top, 8)
   }
}

// Update Price View
struct UpdatePriceView: View {
   let product: ProductItem
   let onUpdatePrice: () -> Void
   let lastUpdated: String
   let lastUpdatedBy: String
  
   var body: some View {
       VStack(alignment: .center, spacing: 12) {
           Text("Price Inaccurate?")
               .font(.system(size: 16, weight: .bold))
               .foregroundColor(.primary)

           Button(action: onUpdatePrice) {
               Text("Update Price")
                   .font(.system(size: 14, weight: .bold))
                   .foregroundColor(Color.accentColorGreen)
                   .padding(.bottom, 6)
           }
       }
       .padding()
   }
}

#Preview {
   ScrollView {
       LazyVStack(spacing: 20) {
           ForEach(ProductCategory.allCases, id: \.self) { category in
               CategoryItemsView(category: category)
           }
       }
       .padding()
   }
}

