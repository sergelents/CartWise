//
//  OpenFoodFactsView.swift
//  CartWise
//
//  Created by AI Assistant on 12/19/25.
//

import SwiftUI

struct OpenFoodFactsView: View {
    @ObservedObject var viewModel: ProductViewModel
    @State private var searchText = ""
    @State private var barcodeText = ""
    @State private var showingBarcodeScanner = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Error Message Display
                if let errorMessage = viewModel.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.orange)
                        Spacer()
                        Button("Dismiss") {
                            viewModel.errorMessage = nil
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                
                // Tab Picker
                Picker("Search Type", selection: $selectedTab) {
                    Text("Search").tag(0)
                    Text("Barcode").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if selectedTab == 0 {
                    searchTabView
                } else {
                    barcodeTabView
                }
            }
            .navigationTitle("Open Food Facts")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var searchTabView: some View {
        VStack {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search products...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: searchText) { newValue in
                        Task {
                            await viewModel.searchProductsFromOpenFoodFacts(by: newValue)
                        }
                    }
                
                if !searchText.isEmpty {
                    Button("Clear") {
                        searchText = ""
                        viewModel.clearOpenFoodFactsSearch()
                    }
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            // Results
            if viewModel.isLoadingOpenFoodFacts {
                Spacer()
                ProgressView("Searching...")
                    .progressViewStyle(CircularProgressViewStyle())
                Spacer()
            } else if !viewModel.openFoodFactsProducts.isEmpty {
                List(viewModel.openFoodFactsProducts, id: \.code) { product in
                    OpenFoodFactsProductRow(product: product) {
                        Task {
                            await viewModel.addOpenFoodFactsProductToCart(product)
                        }
                    }
                }
            } else if !searchText.isEmpty && !viewModel.isLoadingOpenFoodFacts {
                Spacer()
                VStack {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("No products found")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Text("Try a different search term")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
            } else {
                Spacer()
                VStack {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("Search for products")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Text("Enter a product name to search")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
        }
    }
    
    private var barcodeTabView: some View {
        VStack(spacing: 20) {
            // Barcode Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Enter Barcode")
                    .font(.headline)
                
                HStack {
                    TextField("Barcode number", text: $barcodeText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                    
                    Button("Scan") {
                        showingBarcodeScanner = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Button("Search") {
                    Task {
                        await viewModel.searchProductByBarcode(barcodeText)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(barcodeText.isEmpty)
            }
            .padding()
            
            // Barcode Scanner Button
            Button(action: {
                showingBarcodeScanner = true
            }) {
                HStack {
                    Image(systemName: "barcode.viewfinder")
                    Text("Scan Barcode")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
            }
            .padding(.horizontal)
            
            // Product Details
            if let selectedProduct = viewModel.selectedOpenFoodFactsProduct {
                ScrollView {
                    OpenFoodFactsProductDetailView(product: selectedProduct) {
                        Task {
                            await viewModel.addOpenFoodFactsProductToCart(selectedProduct)
                        }
                    }
                    .padding()
                }
            } else if viewModel.isLoadingOpenFoodFacts {
                Spacer()
                ProgressView("Searching...")
                    .progressViewStyle(CircularProgressViewStyle())
                Spacer()
            } else {
                Spacer()
                VStack {
                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("Scan or enter a barcode")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Text("Get detailed product information")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
        }
        .sheet(isPresented: $showingBarcodeScanner) {
            // Placeholder for barcode scanner
            // In a real implementation, you would integrate a barcode scanning library
            BarcodeScannerPlaceholderView(barcodeText: $barcodeText, isPresented: $showingBarcodeScanner)
        }
    }
}

struct OpenFoodFactsProductRow: View {
    let product: OpenFoodFactsProduct
    let onAddToCart: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Product Image
            if let imageURL = product.imageFrontURL ?? product.imageURL,
               let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                }
                .frame(width: 60, height: 60)
                .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
                    .cornerRadius(8)
            }
            
            // Product Info
            VStack(alignment: .leading, spacing: 4) {
                Text(product.productName ?? "Unknown Product")
                    .font(.headline)
                    .lineLimit(2)
                
                if let brand = product.brands {
                    Text(brand)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let nutritionGrade = product.nutritionGrades {
                    HStack {
                        Text("Nutrition Grade:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(nutritionGrade.uppercased())
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(nutritionGradeColor(nutritionGrade))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                }
            }
            
            Spacer()
            
            // Add to Cart Button
            Button(action: onAddToCart) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func nutritionGradeColor(_ grade: String) -> Color {
        switch grade.lowercased() {
        case "a": return .green
        case "b": return .yellow
        case "c": return .orange
        case "d": return .red
        case "e": return .purple
        default: return .gray
        }
    }
}

struct OpenFoodFactsProductDetailView: View {
    let product: OpenFoodFactsProduct
    let onAddToCart: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Product Header
            HStack {
                if let imageURL = product.imageFrontURL ?? product.imageURL,
                   let url = URL(string: imageURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            )
                    }
                    .frame(width: 100, height: 100)
                    .cornerRadius(12)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(product.productName ?? "Unknown Product")
                        .font(.title2)
                        .fontWeight(.bold)
                        .lineLimit(3)
                    
                    if let brand = product.brands {
                        Text(brand)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let nutritionGrade = product.nutritionGrades {
                        HStack {
                            Text("Nutrition Grade:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(nutritionGrade.uppercased())
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(nutritionGradeColor(nutritionGrade))
                                .foregroundColor(.white)
                                .cornerRadius(6)
                        }
                    }
                }
                
                Spacer()
            }
            
            // Nutrition Information
            if let nutriments = product.nutriments {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Nutrition Facts (per 100g)")
                        .font(.headline)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        NutritionFactRow(label: "Energy", value: nutriments.energy100G, unit: "kcal")
                        NutritionFactRow(label: "Fat", value: nutriments.fat100G, unit: "g")
                        NutritionFactRow(label: "Saturated Fat", value: nutriments.saturatedFat100G, unit: "g")
                        NutritionFactRow(label: "Carbohydrates", value: nutriments.carbohydrates100G, unit: "g")
                        NutritionFactRow(label: "Sugars", value: nutriments.sugars100G, unit: "g")
                        NutritionFactRow(label: "Fiber", value: nutriments.fiber100G, unit: "g")
                        NutritionFactRow(label: "Proteins", value: nutriments.proteins100G, unit: "g")
                        NutritionFactRow(label: "Salt", value: nutriments.salt100G, unit: "g")
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
            
            // Additional Information
            VStack(alignment: .leading, spacing: 8) {
                if let categories = product.categories {
                    InfoRow(label: "Categories", value: categories)
                }
                
                if let quantity = product.quantity {
                    InfoRow(label: "Quantity", value: quantity)
                }
                
                if let packaging = product.packaging {
                    InfoRow(label: "Packaging", value: packaging)
                }
                
                if let ingredients = product.ingredientsText {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ingredients")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(ingredients)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let allergens = product.allergens {
                    InfoRow(label: "Allergens", value: allergens)
                }
            }
            
            // Add to Cart Button
            Button(action: onAddToCart) {
                HStack {
                    Image(systemName: "cart.badge.plus")
                    Text("Add to Shopping List")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
        }
    }
    
    private func nutritionGradeColor(_ grade: String) -> Color {
        switch grade.lowercased() {
        case "a": return .green
        case "b": return .yellow
        case "c": return .orange
        case "d": return .red
        case "e": return .purple
        default: return .gray
        }
    }
}

struct NutritionFactRow: View {
    let label: String
    let value: Double?
    let unit: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            if let value = value {
                Text("\(value, specifier: "%.1f") \(unit)")
                    .font(.caption)
                    .fontWeight(.medium)
            } else {
                Text("N/A")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(value)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct BarcodeScannerPlaceholderView: View {
    @Binding var barcodeText: String
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "barcode.viewfinder")
                    .font(.system(size: 100))
                    .foregroundColor(.blue)
                
                Text("Barcode Scanner")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("This is a placeholder for the barcode scanner. In a real implementation, you would integrate a barcode scanning library like AVFoundation or a third-party library.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding()
                
                // Simulated barcode input for testing
                VStack(spacing: 12) {
                    Text("For testing, enter a barcode:")
                        .font(.headline)
                    
                    TextField("Barcode", text: $barcodeText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .padding(.horizontal)
                    
                    Button("Use This Barcode") {
                        isPresented = false
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Scanner")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Cancel") {
                isPresented = false
            })
        }
    }
}

#Preview {
    OpenFoodFactsView(viewModel: ProductViewModel(repository: ProductRepository()))
} 