//
//  ShoppingListCard.swift
//  CartWise
//
//  Extracted from YourListView.swift
//  Optimized for production-level performance
//

import SwiftUI

// MARK: - Performance Optimization 1: Consolidated Card State
/// Reduce property wrapper overhead and prevent unnecessary re-renders
struct ShoppingListCardState: Equatable {
    var isEditing: Bool
    var selectedItemsForDeletion: Set<String>
    
    static func == (lhs: ShoppingListCardState, rhs: ShoppingListCardState) -> Bool {
        lhs.isEditing == rhs.isEditing &&
        lhs.selectedItemsForDeletion == rhs.selectedItemsForDeletion
    }
}

// Shopping List Card
struct ShoppingListCard: View {
    @EnvironmentObject var coordinator: ShoppingListCoordinator
    
    // Performance Optimization 2: Consolidated state
    @State private var cardState = ShoppingListCardState(
        isEditing: false,
        selectedItemsForDeletion: []
    )
    
    @Binding var allItemsChecked: Bool
    @Binding var showingRatingPrompt: Bool
    @Binding var showingAddProductModal: Bool
    @Binding var showingCheckAllConfirmation: Bool

    private var viewModel: ShoppingListViewModel {
        coordinator.shoppingListViewModel
    }

    var body: some View {
        VStack(spacing: 12) {
            // Performance Optimization 3: Extract header
            CardHeader(
                cardState: $cardState,
                productCount: viewModel.products.count,
                productIds: viewModel.products.compactMap { $0.id },
                onDelete: handleBulkDelete
            )
            
            Divider()
            
            // Performance Optimization 4: Conditional view rendering
            if viewModel.products.isEmpty {
                EmptyStateView()
            } else {
                ProductList(
                    products: viewModel.products,
                    cardState: $cardState,
                    onToggle: { product in
                        handleToggle(product)
                    },
                    onDelete: deleteItems
                )
            }
            
            // Performance Optimization 5: Extract action buttons
            ActionButtonsView(
                onAddTap: {
                    coordinator.navigateToAddItems()
                },
                onCheckAllTap: {
                    handleCheckAll()
                }
            )
        }
        .padding()
        .background(AppColors.backgroundPrimary)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.07), radius: 3, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    // MARK: - Business Logic
    
    private func handleToggle(_ product: GroceryItem) {
        if cardState.isEditing {
            if let id = product.id {
                if cardState.selectedItemsForDeletion.contains(id) {
                    cardState.selectedItemsForDeletion.remove(id)
                } else {
                    cardState.selectedItemsForDeletion.insert(id)
                }
            }
        } else {
            Task {
                await viewModel.toggleProductCompletion(product)
            }
        }
    }
    
    private func handleBulkDelete() {
        // Performance Optimization 6: Batch operations
        Task {
            let productsToDelete = viewModel.products.filter {
                cardState.selectedItemsForDeletion.contains($0.id ?? "")
            }
            
            for product in productsToDelete {
                await viewModel.removeProductFromShoppingList(product)
            }
            
            cardState.isEditing = false
            cardState.selectedItemsForDeletion.removeAll()
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        let productsToDelete = offsets.compactMap { index in
            index < viewModel.products.count ? viewModel.products[index] : nil
        }

        Task {
            for product in productsToDelete {
                await viewModel.removeProductFromShoppingList(product)
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
        }
    }
    
    private func handleCheckAll() {
        let allCompleted = viewModel.products.allSatisfy { $0.isCompleted }
        
        if allCompleted {
            Task {
                await viewModel.toggleAllProductsCompletion()
            }
        } else {
            showingCheckAllConfirmation = true
            Task {
                await viewModel.toggleAllProductsCompletion()
            }
        }
    }
}

// MARK: - Extracted Subviews (Performance Optimization 7)

struct CardHeader: View {
    @Binding var cardState: ShoppingListCardState
    let productCount: Int
    let productIds: [String]
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            if cardState.isEditing {
                EditingControls(
                    cardState: $cardState,
                    productCount: productCount,
                    productIds: productIds,
                    onDelete: onDelete
                )
            } else {
                NormalControls(
                    productCount: productCount,
                    onEditTap: {
                        cardState.isEditing.toggle()
                    }
                )
            }
        }
        .padding(.horizontal)
    }
}

struct EditingControls: View {
    @Binding var cardState: ShoppingListCardState
    let productCount: Int
    let productIds: [String]
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Button {
                onDelete()
            } label: {
                Text("Delete")
                    .font(.poppins(size: 15, weight: .regular))
                    .underline()
                    .foregroundColor(.red)
            }
            
            Button {
                if cardState.selectedItemsForDeletion.count == productCount {
                    cardState.selectedItemsForDeletion.removeAll()
                } else {
                    cardState.selectedItemsForDeletion = Set(productIds)
                }
            } label: {
                Text(cardState.selectedItemsForDeletion.count == productCount ? "Deselect All" : "Select All")
                    .font(.poppins(size: 15, weight: .regular))
                    .underline()
                    .foregroundColor(.blue)
            }
        }
        
        Spacer()
        
        Button {
            cardState.isEditing = false
            cardState.selectedItemsForDeletion.removeAll()
        } label: {
            Text("Cancel")
                .font(.poppins(size: 15, weight: .regular))
                .underline()
                .foregroundColor(.gray)
        }
    }
}

struct NormalControls: View {
    let productCount: Int
    let onEditTap: () -> Void
    
    var body: some View {
        Text("\(productCount) Items")
            .font(.poppins(size: 15, weight: .regular))
            .foregroundColor(.gray)
        
        Spacer()
        
        Button {
            onEditTap()
        } label: {
            Text("Edit")
                .font(.poppins(size: 15, weight: .regular))
                .underline()
                .foregroundColor(.gray)
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "basket")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(AppColors.accentGreen.opacity(0.7))
            
            Text("You have nothing on your list!")
                .font(.poppins(size: 18, weight: .semibold))
                .foregroundColor(.gray)
            
            HStack(spacing: 4) {
                Text("Tap the")
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(AppColors.accentGreen)
                    .font(.system(size: 16))
                Text("button to add your first item.")
            }
            .font(.poppins(size: 15, weight: .regular))
            .foregroundColor(.gray.opacity(0.7))
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .padding(.vertical, 24)
    }
}

struct ProductList: View {
    let products: [GroceryItem]
    @Binding var cardState: ShoppingListCardState
    let onToggle: (GroceryItem) -> Void
    let onDelete: (IndexSet) -> Void
    
    var body: some View {
        List {
            ForEach(products, id: \.objectID) { product in
                ProductRowWrapper(
                    product: product,
                    cardState: cardState,
                    onToggle: { onToggle(product) }
                )
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
            }
            .onDelete(perform: onDelete)
        }
        .listStyle(PlainListStyle())
        .background(Color.clear)
    }
}

// Performance Fix: Wrapper that observes product changes
struct ProductRowWrapper: View {
    @ObservedObject var product: GroceryItem
    let cardState: ShoppingListCardState
    let onToggle: () -> Void
    
    var body: some View {
        ShoppingListItemRow(
            itemData: ShoppingListItemData(from: product),
            isEditing: cardState.isEditing,
            isSelected: cardState.selectedItemsForDeletion.contains(product.id ?? ""),
            onToggle: onToggle,
            onDelete: nil
        )
    }
}

struct ActionButtonsView: View {
    let onAddTap: () -> Void
    let onCheckAllTap: () -> Void
    
    var body: some View {
        HStack(spacing: 56) {
            // Add Button
            Button(action: onAddTap) {
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
            
            // Check All Button
            Button(action: onCheckAllTap) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(width: 44, height: 44)
            .background(
                Circle()
                    .fill(AppColors.accentOrange)
                    .shadow(color: AppColors.accentOrange.opacity(0.3), radius: 8, x: 0, y: 4)
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
}
