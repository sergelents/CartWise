//
//  SmartAddProductModal.swift
//  CartWise
//
//  Extracted from YourListView.swift
//  Optimized for production-level performance
//

import SwiftUI

// MARK: - Performance Optimization 1: Consolidated Modal State
struct ModalState: Equatable {
    var searchText = ""
    var isCancelPressed = false
    
    static func == (lhs: ModalState, rhs: ModalState) -> Bool {
        lhs.searchText == rhs.searchText &&
        lhs.isCancelPressed == rhs.isCancelPressed
    }
}

struct SmartAddProductModal: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var coordinator: ShoppingListCoordinator
    
    // Performance Optimization 2: Consolidated state
    @State private var modalState = ModalState()
    @FocusState private var isSearchFocused: Bool
    
    let onAdd: (String, String?, String?, Double?) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Performance Optimization 3: Extract header
                ModalHeader(
                    searchText: $modalState.searchText,
                    isSearchFocused: $isSearchFocused
                )
                
                // Performance Optimization 4: Removed GeometryReader
                // Only used for minHeight calculation, static value is better
                ScrollView {
                    if modalState.searchText.isEmpty {
                        EmptySearchState()
                            .frame(minHeight: 300)
                            .padding(.top, 40)
                    } else {
                        SearchResultsSection(
                            searchText: modalState.searchText,
                            onAdd: { name, brand, category, price in
                                onAdd(name, brand, category, price)
                                dismiss()
                            },
                            onCreateNew: {},
                            dismiss: dismiss
                        )
                    }
                }
                .background(AppColors.backgroundSecondary)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // Performance Optimization 5: Extract cancel button
                    CancelButton(
                        isPressed: modalState.isCancelPressed,
                        onCancel: handleCancel
                    )
                }
            }
        }
    }
    
    // Performance Optimization 6: Structured concurrency
    private func handleCancel() {
        modalState.isCancelPressed = true
        
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            modalState.isCancelPressed = false
            dismiss()
        }
    }
}

// MARK: - Extracted Subviews (Performance Optimization 7)

struct ModalHeader: View {
    @Binding var searchText: String
    @FocusState.Binding var isSearchFocused: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Add to Your List")
                .font(.poppins(size: 24, weight: .bold))
                .padding(.top)
            
            // Performance Optimization 8: Simplified search bar
            SearchTextField(
                text: $searchText,
                isFocused: $isSearchFocused
            )
            .padding(.horizontal)
        }
        .padding(.bottom)
        .background(AppColors.backgroundSecondary)
    }
}

struct SearchTextField: View {
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            ZStack(alignment: .leading) {
                TextField("", text: $text)
                    .font(.poppins(size: 16, weight: .regular))
                    .focused($isFocused)
                
                // Performance Optimization 9: Simplified placeholder logic
                if text.isEmpty {
                    Group {
                        if !isFocused {
                            Text("Search products...")
                                .font(.poppins(size: 16, weight: .regular))
                                .foregroundColor(.gray)
                                .allowsHitTesting(false)
                        } else {
                            // Custom cursor
                            Rectangle()
                                .fill(AppColors.accentGreen)
                                .frame(width: 2, height: 20)
                                .allowsHitTesting(false)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct EmptySearchState: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("Search for products to add to your list")
                .font(.poppins(size: 18, weight: .semibold))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
    }
}

struct CancelButton: View {
    let isPressed: Bool
    let onCancel: () -> Void
    
    var body: some View {
        Text("Cancel")
            .font(.poppins(size: 16, weight: .regular))
            .foregroundColor(isPressed ? .gray.opacity(0.5) : .gray)
            .underline()
            .padding(.leading, 8)
            .padding(.top, 4)
            .onTapGesture {
                onCancel()
            }
    }
}
