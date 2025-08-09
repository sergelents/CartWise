//
//  YourListView.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/5/25.
//  Edited by Brenna Wilson on 7/10/25 - 7/13/25
//  Enhanced with AI assistance from Cursor AI for UI improvements and functionality.
//  This saved me 6-9 hours of work learning swift UI syntax.
//

import SwiftUI

struct YourListView: View {
    @EnvironmentObject var productViewModel: ProductViewModel
    @State private var suggestedStore: String = "Whole Foods Market"
    @State private var storeAddress: String = "1701 Wewatta St."
    @State private var total: Double = 0.00
    @State private var allItemsChecked: Bool = false
    @State private var isEditing: Bool = false
    @State private var selectedItemsForDeletion: Set<String> = []
    @State private var showingAddProductModal = false
    @State private var showingRatingPrompt: Bool = false
    @State private var showingDuplicateAlert = false
    @State private var duplicateProductName = ""
    @State private var showingCheckAllConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                AppColors.backgroundSecondary
                    .ignoresSafeArea()
                // Main Content
                VStack(alignment: .leading, spacing: 24) {
                    // Item List Card
                    ShoppingListCard(
                        isEditing: $isEditing,
                        allItemsChecked: $allItemsChecked,
                        selectedItemsForDeletion: $selectedItemsForDeletion,
                        showingRatingPrompt: $showingRatingPrompt,
                        showingAddProductModal: $showingAddProductModal,
                        showingCheckAllConfirmation: $showingCheckAllConfirmation
                    )
                    // Price Comparison Card
                    PriceComparisonView(
                        priceComparison: productViewModel.priceComparison,
                        isLoading: productViewModel.isLoadingPriceComparison,
                        onRefresh: {
                            await productViewModel.loadLocalPriceComparison()
                        },
                        onLocalComparison: {
                            await productViewModel.loadLocalPriceComparison()
                        }
                    )
                    .padding(.horizontal)
                    Spacer()
                }
                .padding(.top)
            }
            .navigationTitle("Your Shopping List")
            .sheet(isPresented: $showingRatingPrompt) {
                RatingPromptView()
            }
            .sheet(isPresented: $showingAddProductModal) {
                SmartAddProductModal(onAdd: addProductToSystem)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .ignoresSafeArea(.keyboard, edges: .bottom)
            }
            .alert("Duplicate Product", isPresented: $showingDuplicateAlert) {
                Button("OK") {
                    showingDuplicateAlert = false
                }
            } message: {
                Text("A product named \"\(duplicateProductName)\" already exists in your list.")
            }
            .alert("All done shopping?", isPresented: $showingCheckAllConfirmation) {
                Button("Cancel", role: .cancel) {
                    // Do nothing, just dismiss the alert
                }
                Button("Clear List") {
                    Task {
                        await productViewModel.clearShoppingList()
                    }
                }
            } message: {
                Text("Want to clear your shopping list?")
            }
            .onAppear {
                Task {
                    await productViewModel.loadShoppingListProducts()
                    print("YourListView: Loaded \(productViewModel.products.count) shopping list products")
                    await productViewModel.loadLocalPriceComparison()
                    print("YourListView: Price comparison loaded: \(productViewModel.priceComparison?.storePrices.count ?? 0) stores")
                    if let comparison = productViewModel.priceComparison {
                        print("YourListView: Best store: \(comparison.bestStore ?? "None"), Total: $\(comparison.bestTotalPrice)")
                        for storePrice in comparison.storePrices {
                            print("YourListView: Store \(storePrice.store): $\(storePrice.totalPrice)")
                        }
                    }
                }
            }
        }
    }

    private func addProductToSystem(name: String, brand: String?, category: String?, price: Double? = nil) {
        Task {
            // Check for duplicate first
            if await productViewModel.isDuplicateProduct(name: name) {
                duplicateProductName = name
                showingDuplicateAlert = true
                return
            }
            // Proceed with creation if no duplicate
            if let brand = brand, !brand.isEmpty {
                await productViewModel.createProductForShoppingList(byName: name, brand: brand, category: category)
            } else {
                await productViewModel.createProductForShoppingList(byName: name, brand: nil, category: category)
            }
            // Refresh price comparison after adding product
            await productViewModel.loadLocalPriceComparison()
        }
    }
}

#Preview {
    YourListView()
}
