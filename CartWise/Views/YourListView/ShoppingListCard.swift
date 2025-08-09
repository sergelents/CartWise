//
//  ShoppingListCard.swift
//  CartWise
//
//  Extracted from YourListView.swift
//

import SwiftUI

// Shopping List Card
struct ShoppingListCard: View {
    @EnvironmentObject var productViewModel: ProductViewModel
    @Binding var isEditing: Bool
    @Binding var allItemsChecked: Bool
    @Binding var selectedItemsForDeletion: Set<String>
    @Binding var showingRatingPrompt: Bool
    @Binding var showingAddProductModal: Bool
    @Binding var showingCheckAllConfirmation: Bool

    // Function to handle SwiftUI's native onDelete
    private func deleteItems(offsets: IndexSet) {
        // Capture the products to delete before any async operations
        let productsToDelete = offsets.compactMap { index in
            // Check bounds to prevent index out of range
            index < productViewModel.products.count ? productViewModel.products[index] : nil
        }

        Task {
            // Process deletions sequentially to avoid race conditions
            for product in productsToDelete {
                await productViewModel.removeProductFromShoppingList(product)
                // Small delay to allow UI to update between deletions
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
        }
    }
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                if isEditing {
                    HStack(spacing: 16) {
                        Button(action: {
                            // Remove selected items from shopping list
                            for id in selectedItemsForDeletion {
                                if let product = productViewModel.products.first(where: { $0.id == id }) {
                                    Task {
                                        await productViewModel.removeProductFromShoppingList(product)
                                    }
                                }
                            }
                            isEditing = false
                            selectedItemsForDeletion.removeAll()
                        }) {
                            Text("Delete")
                                .font(.poppins(size: 15, weight: .regular))
                                .underline()
                                .foregroundColor(.red)
                        }
                        Button(action: {
                            if selectedItemsForDeletion.count == productViewModel.products.count {
                                selectedItemsForDeletion.removeAll()
                            } else {
                                selectedItemsForDeletion = Set(productViewModel.products.compactMap { $0.id })
                            }
                        }) {
                            Text(selectedItemsForDeletion.count == productViewModel.products.count ? 
                                 "Deselect All" : "Select All")
                                .font(.poppins(size: 15, weight: .regular))
                                .underline()
                                .foregroundColor(.blue)
                        }
                    }
                    Spacer()
                    Button(action: {
                        isEditing = false
                        selectedItemsForDeletion.removeAll()
                    }) {
                        Text("Cancel")
                            .font(.poppins(size: 15, weight: .regular))
                            .underline()
                            .foregroundColor(.gray)
                    }
                } else {
                    Text("\(productViewModel.products.count) Items")
                        .font(.poppins(size: 15, weight: .regular))
                        .foregroundColor(.gray)
                    Spacer()
                    Button(action: {
                        isEditing.toggle()
                    }) {
                        Text("Edit")
                            .font(.poppins(size: 15, weight: .regular))
                            .underline()
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal)
            Divider()
            // Item List
            if productViewModel.products.isEmpty {
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
            } else {
                List {
                    ForEach(productViewModel.products, id: \.objectID) { product in
                        ShoppingListItemRow(
                            product: product,
                            isEditing: isEditing,
                            isSelected: selectedItemsForDeletion.contains(product.id ?? ""),
                            onToggle: {
                                if isEditing {
                                    if let id = product.id {
                                        if selectedItemsForDeletion.contains(id) {
                                            selectedItemsForDeletion.remove(id)
                                        } else {
                                            selectedItemsForDeletion.insert(id)
                                        }
                                    }
                                } else {
                                    // Toggle completion status
                                    Task {
                                        await productViewModel.toggleProductCompletion(product)
                                        // Check if all products are completed after toggling
                                        // if productViewModel.allProductsCompleted {
                                        //     showingRatingPrompt = true
                                        // }
                                    }
                                }
                            },
                            onDelete: nil // Remove the onDelete callback to prevent conflicts
                        )
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                    }
                    .onDelete(perform: deleteItems)
                }
                .listStyle(PlainListStyle())
                .background(Color.clear)
            }
            // Add Button & Check All Button
            HStack(spacing: 56) {
                Button(action: {
                    showingAddProductModal = true
                }) {
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
                Button(action: {
                    // Check if we're about to complete all items (not uncheck them)
                    let allCompleted = productViewModel.products.allSatisfy { $0.isCompleted }
                    if allCompleted {
                        // If all are completed, directly uncheck them all (no confirmation needed)
                        Task {
                            await productViewModel.toggleAllProductsCompletion()
                        }
                    } else {
                        // If not all are completed, show alert immediately and check items in background
                        showingCheckAllConfirmation = true
                        Task {
                            await productViewModel.toggleAllProductsCompletion()
                        }
                    }
                }) {
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
        .padding()
        .background(AppColors.backgroundPrimary)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.07), radius: 3, x: 0, y: 2)
        .padding(.horizontal)
    }
}
