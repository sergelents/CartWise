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
    @EnvironmentObject var coordinator: ShoppingListCoordinator
    @State private var suggestedStore: String = "Whole Foods Market"
    @State private var storeAddress: String = "1701 Wewatta St."
    @State private var total: Double = 0.00
    @State private var allItemsChecked: Bool = false
    @State private var isEditing: Bool = false
    @State private var selectedItemsForDeletion: Set<String> = []

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
                        showingRatingPrompt: Binding(
                            get: { coordinator.showingRatingPrompt },
                            set: { _ in }
                        ),
                        showingAddProductModal: Binding(
                            get: { coordinator.showingAddProductModal },
                            set: { _ in }
                        ),
                        showingCheckAllConfirmation: Binding(
                            get: { coordinator.showingCheckAllConfirmation },
                            set: { _ in }
                        )
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
                        },
                        onShareExperience: {
                            coordinator.showShareExperience(priceComparison: productViewModel.priceComparison)
                        }
                    )
                    .padding(.horizontal)
                    Spacer()
                }
                .padding(.top)
            }
            .navigationTitle("Your Shopping List")
            .sheet(isPresented: Binding(
                get: { coordinator.showingRatingPrompt },
                set: { _ in coordinator.hideRatingPrompt() }
            )) {
                RatingPromptView()
            }
            .sheet(isPresented: Binding(
                get: { coordinator.showingAddProductModal },
                set: { _ in coordinator.hideAddProductModal() }
            )) {
                SmartAddProductModal(onAdd: { name, brand, category, price in
                    Task {
                        // Check for duplicate first
                        if await productViewModel.isDuplicateProduct(name: name) {
                            coordinator.showDuplicateAlert(productName: name)
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
                })
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
            .sheet(isPresented: Binding(
                get: { coordinator.showingShareExperience },
                set: { _ in coordinator.hideShareExperience() }
            )) {
                ShareExperienceView(priceComparison: coordinator.currentPriceComparison)
            }
            .alert("Duplicate Product", isPresented: Binding(
                get: { coordinator.showingDuplicateAlert },
                set: { _ in coordinator.hideDuplicateAlert() }
            )) {
                Button("OK") {
                    coordinator.hideDuplicateAlert()
                }
            } message: {
                Text("A product named \"\(coordinator.duplicateProductName)\" already exists in your list.")
            }
            .alert("All done shopping?", isPresented: Binding(
                get: { coordinator.showingCheckAllConfirmation },
                set: { _ in coordinator.hideCheckAllConfirmation() }
            )) {
                Button("Cancel", role: .cancel) {
                    coordinator.hideCheckAllConfirmation()
                }
                Button("Clear List") {
                    Task {
                        await productViewModel.clearShoppingList()
                        coordinator.hideCheckAllConfirmation()
                    }
                }
            } message: {
                Text("Want to clear your shopping list?")
            }
            .onAppear {
                Task {
                    // Load data directly through ViewModel
                    await productViewModel.loadShoppingListProducts()
                    await productViewModel.loadLocalPriceComparison()
                    
                    print("YourListView: Loaded \(productViewModel.products.count) shopping list products")
                    print("YourListView: Price comparison loaded: " +
                          "\(productViewModel.priceComparison?.storePrices.count ?? 0) stores")
                    if let comparison = productViewModel.priceComparison {
                        print("YourListView: Best store: \(comparison.bestStore ?? "None"), " +
                              "Total: $\(comparison.bestTotalPrice)")
                        for storePrice in comparison.storePrices {
                            print("YourListView: Store \(storePrice.store): $\(storePrice.totalPrice)")
                        }
                    }
                }
            }
        }
    }

}

#Preview {
    YourListView()
}
