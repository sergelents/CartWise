//
//  CategoryPickerView.swift
//  CartWise
//
//  Extracted from YourListView.swift
//

import SwiftUI

struct CategoryPickerView: View {
    @Binding var selectedCategory: ProductCategory
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationView {
            List(ProductCategory.allCases, id: \.self) { category in
                Button(action: {
                    selectedCategory = category
                    dismiss()
                }) {
                    HStack {
                        Text(category.rawValue)
                            .font(.poppins(size: 16, weight: .regular))
                            .foregroundColor(category == .none ? .gray : .primary)
                        Spacer()
                        if selectedCategory == category && category != .none {
                            Image(systemName: "checkmark")
                                .foregroundColor(AppColors.accentGreen)
                        }
                    }
                }
            }
            .navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
