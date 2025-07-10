//
//  YourListView.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/5/25.
//

import SwiftUI

struct YourListView: View {
    @State private var items: [ShoppingItem] = SampleData.items
    @State private var suggestedStore: String = "Whole Foods Market"
    @State private var storeAddress: String = "1701 Wewatta St."
    @State private var total: Double = 43.00

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Header
                Text("Your Shopping List")
                    .font(.poppins(size:30, weight: .bold))
                    .foregroundColor(AppColors.accentGreen)
                    .padding(.horizontal)

                // Item List Card
                VStack(spacing: 12) {
                    HStack {
                        Text("\(items.count) Items")
                            .font(.poppins(size:15, weight: .regular))
                            .foregroundColor(.gray)
                        Spacer()
                        Text("Edit")
                            .font(.poppins(size:15, weight: .regular))
                            .underline()
                            .foregroundColor(.gray)
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(AppColors.accentOrange)
                    }
                    .padding(.horizontal)

                    Divider()

                    // Item Rows
                    ForEach(items) { item in
                        HStack(alignment: .top) {
                            Circle()
                                .strokeBorder(.gray, lineWidth: 1)
                                .frame(width: 20, height: 20)
                                .padding(.top, 6)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                    .font(.poppins(size:15, weight: .regular))
                                Text(item.details)
                                    .font(.poppins(size:12, weight: .regular))
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            Text(String(format: "$%.2f", item.price))
                                .font(.poppins(size:15, weight: .regular))
                        }
                        .padding(.horizontal)
                    }

                    // Add Button
                    Button(action: {
                        // TODO: Add item logic
                    }) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 28))
                            .foregroundColor(AppColors.accentGreen)
                    }
                    .padding(.top, 8)
                }
                .padding()
                .background(AppColors.backgroundPrimary)
                .cornerRadius(20)
                .shadow(radius: 3)
                .padding(.horizontal)

                // Suggested Store Card
                VStack(spacing: 10) {
                    Text("Running Total at Suggested Store")
                        .font(.poppins(size:13, weight: .regular))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Divider()
                    Text("$\(Int(total))")
                        .font(.poppins(size:35, weight: .bold))

                    Text(suggestedStore)
                        .font(.poppins(size:19, weight: .semibold))

                    Text(storeAddress)
                        .font(.poppins(size:15, weight: .regular))
                        .foregroundColor(.gray)

                    Button("Change Store") {
                        // TODO: Store picker logic
                    }
                    .font(.poppins(size:15, weight: .bold))
                    .padding(.vertical, 4)
                    .padding(.horizontal, 30)
                    .background(.gray.opacity(0.15))
                    .foregroundColor(AppColors.accentGreen)
                    .cornerRadius(20)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(20)
                .shadow(radius: 3)
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top)
        }
        .background(AppColors.accentGray)
    }
}

#Preview {
    YourListView()
}

