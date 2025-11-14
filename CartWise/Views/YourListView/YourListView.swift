//
//  YourListView.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/5/25.
//  Optimized for production-level performance
//

import SwiftUI

struct YourListView: View {
    @EnvironmentObject var coordinator: ShoppingListCoordinator
    
    // Performance Optimization 1: Computed property for clean access
    private var viewModel: ShoppingListViewModel {
        coordinator.shoppingListViewModel
    }
    
    // Performance Optimization 2: Remove unused state
    // allItemsChecked is managed internally by ShoppingListCard now
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundSecondary
                    .ignoresSafeArea()
                
                // Performance Optimization 3: Extract main content
                MainContentView(
                    viewModel: viewModel,
                    coordinator: coordinator
                )
            }
            .navigationTitle("Your Shopping List")
            // Performance Optimization 4: Extract modal configurations
            .modifier(ShoppingListModals(coordinator: coordinator))
            // Performance Optimization 5: Optimized data loading
            .task {
                await loadInitialData()
            }
        }
    }
    
    // Performance Optimization 6: Parallel async operations
    private func loadInitialData() async {
        async let productsTask: () = viewModel.loadShoppingListProducts()
        async let priceTask: () = viewModel.loadLocalPriceComparison()
        
        // Wait for both operations to complete in parallel
        _ = await (productsTask, priceTask)
        
        // Performance Optimization 7: Production logging (conditional)
        #if DEBUG
        logLoadedData()
        #endif
    }
    
    #if DEBUG
    private func logLoadedData() {
        print("YourListView: Loaded \(viewModel.products.count) shopping list products")
        print("YourListView: Price comparison loaded: \(viewModel.priceComparison?.storePrices.count ?? 0) stores")
        
        if let comparison = viewModel.priceComparison {
            print("YourListView: Best store: \(comparison.bestStore ?? "None"), Total: $\(comparison.bestTotalPrice)")
            for storePrice in comparison.storePrices {
                print("YourListView: Store \(storePrice.store): $\(storePrice.totalPrice)")
            }
        }
    }
    #endif
}

// MARK: - Performance Optimization 8: Extracted Main Content

struct MainContentView: View {
    let viewModel: ShoppingListViewModel
    let coordinator: ShoppingListCoordinator
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ShoppingListCard(
                allItemsChecked: .constant(false),
                showingRatingPrompt: coordinatorBinding(\.showingRatingPrompt),
                showingAddProductModal: coordinatorBinding(\.showingAddProductModal),
                showingCheckAllConfirmation: coordinatorBinding(\.showingCheckAllConfirmation)
            )
            
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
    
    // Performance Optimization 9: Helper to reduce Binding boilerplate
    private func coordinatorBinding(_ keyPath: KeyPath<ShoppingListCoordinator, Bool>) -> Binding<Bool> {
        Binding(
            get: { coordinator[keyPath: keyPath] },
            set: { _ in }
        )
    }
}

// MARK: - Performance Optimization 10: Extracted Modal Configurations

struct ShoppingListModals: ViewModifier {
    let coordinator: ShoppingListCoordinator
    
    private var viewModel: ShoppingListViewModel {
        coordinator.shoppingListViewModel
    }
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: binding(\.showingRatingPrompt, hide: coordinator.hideRatingPrompt)) {
                RatingPromptView()
            }
            .sheet(isPresented: binding(\.showingAddProductModal, hide: coordinator.hideAddProductModal)) {
                SmartAddProductModal(onAdd: { _, _, _, _ in })
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .ignoresSafeArea(.keyboard, edges: .bottom)
            }
            .sheet(isPresented: binding(\.showingShareExperience, hide: coordinator.hideShareExperience)) {
                ShareExperienceView(priceComparison: coordinator.currentPriceComparison)
            }
            .alert("Duplicate Product", isPresented: binding(\.showingDuplicateAlert, hide: coordinator.hideDuplicateAlert)) {
                Button("OK") {
                    coordinator.hideDuplicateAlert()
                }
            } message: {
                Text("A product named \"\(coordinator.duplicateProductName)\" already exists in your list.")
            }
            .alert("All done shopping?", isPresented: binding(\.showingCheckAllConfirmation, hide: coordinator.hideCheckAllConfirmation)) {
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
    }
    
    // Performance Optimization 11: Reusable binding helper
    private func binding(
        _ keyPath: KeyPath<ShoppingListCoordinator, Bool>,
        hide: @escaping () -> Void
    ) -> Binding<Bool> {
        Binding(
            get: { coordinator[keyPath: keyPath] },
            set: { _ in hide() }
        )
    }
}

#Preview {
    YourListView()
}
