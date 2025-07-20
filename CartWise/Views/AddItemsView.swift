//
//  AddItemsView.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/5/25.
//

import SwiftUI

struct AddItemsView: View {
    @State private var showingBarcodeScanner = false
    @State private var showingManualEntry = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Add Items to Your List")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Scan a barcode or manually add items to your shopping list")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 50)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 20) {
                    // Scan Barcode Button
                    Button(action: {
                        showingBarcodeScanner = true
                    }) {
                        HStack {
                            Image(systemName: "barcode.viewfinder")
                                .font(.title2)
                            Text("Scan Barcode")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Manual Entry Button
                    Button(action: {
                        showingManualEntry = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                                .font(.title2)
                            Text("Add Manually")
                                .font(.headline)
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Info Section
                VStack(spacing: 12) {
                    Text("Supported Barcode Types")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("EAN-8, EAN-13, UPC-E, Code 128, Code 39")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, 30)
            }
            .navigationTitle("Add Items")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingBarcodeScanner) {
            BarcodeScannerView()
        }
        .sheet(isPresented: $showingManualEntry) {
            ManualEntryView()
        }
    }
}

// Manual Entry View
struct ManualEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var productViewModel = ProductViewModel(repository: Repository(coreDataContainer: CoreDataContainer()))
    @State private var productName = ""
    @State private var brand = ""
    @State private var category = "Select Category"
    @State private var showingSuccessMessage = false
    @State private var showingErrorMessage = false
    
    private let categories = ["Select Category", "Meat & Seafood", "Dairy & Eggs", "Bakery", "Produce", "Pantry Items", "Beverages", "Frozen Foods", "Household & Personal Care"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Product Information")) {
                    TextField("Product Name", text: $productName)
                    
                    TextField("Brand (Optional)", text: $brand)
                    
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                }
                
                Section {
                    Button("Add to Shopping List") {
                        addProduct()
                    }
                    .disabled(productName.isEmpty || category == "Select Category")
                }
            }
            .navigationTitle("Add Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Success!", isPresented: $showingSuccessMessage) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Product has been added to your shopping list.")
        }
        .alert("Error", isPresented: $showingErrorMessage) {
            Button("OK") { }
        } message: {
            Text(productViewModel.errorMessage ?? "An error occurred while adding the product.")
        }
    }
    
    private func addProduct() {
        let selectedCategory = category == "Select Category" ? nil : category
        let selectedBrand = brand.isEmpty ? nil : brand
        
        Task {
            await productViewModel.createProductForShoppingList(
                byName: productName,
                brand: selectedBrand,
                category: selectedCategory
            )
            
            await MainActor.run {
                if productViewModel.errorMessage == nil {
                    showingSuccessMessage = true
                } else {
                    showingErrorMessage = true
                }
            }
        }
    }
}
