//
//  ShareExperienceView.swift
//  CartWise
//
//  Created by AI Assistant on 12/19/24.
//
import SwiftUI
struct ShareExperienceView: View {
    let priceComparison: PriceComparison?
    @StateObject private var viewModel = SocialFeedViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @State private var comment = ""
    @State private var rating: Int16 = 0
    @State private var selectedType = "price_update"
    // Optional additional information
    @State private var selectedProduct: GroceryItem?
    @State private var selectedLocation: Location?
    @State private var showingProductPicker = false
    @State private var showingLocationPicker = false
    private let types = [
        ("price_update", "Price Update"),
        ("store_review", "Store Review"),
        ("general", "General Comment")
    ]
    init(priceComparison: PriceComparison?) {
        self.priceComparison = priceComparison
        // Initialize state values based on context
        _viewModel = StateObject(wrappedValue: SocialFeedViewModel())
        _selectedType = State(initialValue: priceComparison == nil ? "store_review" : "price_update")
    }
    var body: some View {
        NavigationView {
            Form {
                Section("Experience Details") {
                    Picker("Type", selection: $selectedType) {
                        ForEach(types, id: \.0) { type in
                            Text(type.1).tag(type.0)
                        }
                    }
                    .pickerStyle(.menu)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Rating")
                            .font(.headline)
                        HStack(spacing: 12) {
                            ForEach(1...5, id: \.self) { star in
                                Button(action: {
                                    // If tapping the same star, clear the rating, otherwise set to the tapped star
                                    rating = rating == Int16(star) ? 0 : Int16(star)
                                }) {
                                    Image(systemName: star <= rating ? "star.fill" : "star")
                                        .foregroundColor(star <= rating ? .orange : .gray)
                                        .font(.title2)
                                        .frame(width: 32, height: 32)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
                if let comparison = priceComparison, let bestStore = comparison.bestStore {
                    Section("Price Comparison Info") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Best Store: \(bestStore)")
                                .font(.headline)
                                .foregroundColor(.green)
                            Text("Total Price: $\(String(format: "%.2f", comparison.bestTotalPrice))")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            if !comparison.storePrices.isEmpty {
                                Text("Available at \(comparison.storePrices.count) stores")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                // Optional Product Information
                if selectedType == "price_update" {
                    Section("Product Information (Optional)") {
                        Button(action: {
                            showingProductPicker = true
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Product")
                                        .font(.headline)
                                    Text(selectedProduct?.productName ?? "Select a product")
                                        .font(.subheadline)
                                        .foregroundColor(selectedProduct == nil ? .gray : .primary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        if selectedProduct != nil {
                            Button("Clear Product") {
                                selectedProduct = nil
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
                // Optional Store Information
                if selectedType == "store_review" {
                    Section("Store Information (Optional)") {
                        Button(action: {
                            showingLocationPicker = true
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Store")
                                        .font(.headline)
                                    Text(selectedLocation?.name ?? "Select a store")
                                        .font(.subheadline)
                                        .foregroundColor(selectedLocation == nil ? .gray : .primary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        if selectedLocation != nil {
                            Button("Clear Store") {
                                selectedLocation = nil
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
                Section("Your Comment") {
                    TextEditor(text: $comment)
                        .frame(minHeight: 100)
                        .onAppear {
                            if let comparison = priceComparison, let bestStore = comparison.bestStore {
                                comment = "Found great prices at \(bestStore)! Total: $\(String(format: "%.2f", comparison.bestTotalPrice))"
                            }
                        }
                }
            }
            .navigationTitle("Share Experience")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Post") {
                        postExperience()
                    }
                    .disabled(comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .sheet(isPresented: $showingProductPicker) {
                ProductPickerView(selectedProduct: $selectedProduct)
            }
            .sheet(isPresented: $showingLocationPicker) {
                LocationPickerView(selectedLocation: $selectedLocation)
            }
        }
    }
    private func postExperience() {
        // Create enhanced comment with optional information
        var enhancedComment = comment.trimmingCharacters(in: .whitespacesAndNewlines)
        // Add product information if available
        if let product = selectedProduct {
            enhancedComment += "\n\nProduct: \(product.productName ?? "Unknown")"
            if let brand = product.brand, !brand.isEmpty {
                enhancedComment += " (\(brand))"
            }
        }
        // Add store information if available
        if let location = selectedLocation {
            enhancedComment += "\nStore: \(location.name ?? "Unknown")"
            if let address = location.address, !address.isEmpty {
                enhancedComment += " (\(address))"
            }
        }
        // Get current user from the same context
        let currentUser = viewModel.getCurrentUser()
        viewModel.createExperience(
            comment: enhancedComment,
            rating: rating,
            type: selectedType,
            groceryItem: selectedProduct,
            location: selectedLocation,
            user: currentUser
        )
        dismiss()
    }
}
#Preview {
    ShareExperienceView(priceComparison: nil)
}