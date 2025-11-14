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
    @EnvironmentObject var coordinator: ShoppingListCoordinator
    
    private var viewModel: ShoppingListViewModel {
        coordinator.shoppingListViewModel
    }
    @State private var allItemsChecked: Bool = false

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
                        allItemsChecked: $allItemsChecked,
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
                        priceComparison: viewModel.priceComparison,
                        isLoading: viewModel.isLoadingPriceComparison,
                        onRefresh: {
                            await viewModel.loadLocalPriceComparison()
                        },
                        onLocalComparison: {
                            await viewModel.loadLocalPriceComparison()
                        },
                        onShareExperience: {
                            coordinator.showShareExperience(priceComparison: viewModel.priceComparison)
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
                    // This modal is handled by AddItemsViewModel now
                    // We'll need to create a simple version for shopping list
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
                        await viewModel.clearShoppingList()
                        coordinator.hideCheckAllConfirmation()
                    }
                }
            } message: {
                Text("Want to clear your shopping list?")
            }
            .onAppear {
                Task {
                    // Load data directly through ViewModel
                    await viewModel.loadShoppingListProducts()
                    await viewModel.loadLocalPriceComparison()
                    
                    print("YourListView: Loaded \(viewModel.products.count) shopping list products")
                    print("YourListView: Price comparison loaded: " +
                          "\(viewModel.priceComparison?.storePrices.count ?? 0) stores")
                    if let comparison = viewModel.priceComparison {
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
