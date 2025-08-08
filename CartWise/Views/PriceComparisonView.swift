//
//  PriceComparisonView.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/19/25.
//
import SwiftUI
import Foundation
struct PriceComparisonView: View {
    let priceComparison: PriceComparison?
    let isLoading: Bool
    let onRefresh: () async -> Void
    let onLocalComparison: () async -> Void
    @State private var showingShareExperience = false
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("Price Comparison")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.gray)
                Spacer()
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    HStack(spacing: 12) {
                        Button(
                            action: {
                                showingShareExperience = true
                            },
                            label: {
                                Image(systemName: "bubble.left.and.bubble.right")
                                    .foregroundColor(.blue)
                            }
                        )
                        Button(
                            action: {
                                Task {
                                    await onLocalComparison()
                                }
                            },
                            label: {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(.blue)
                            }
                        )
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // Availability threshold info
            HStack {
                Text("Only showing stores with 85%+ of your items")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 4)

            // Price comparison content
            if let comparison = priceComparison {
                if comparison.storePrices.isEmpty {
                    VStack(spacing: 8) {
                        Text("No stores meet the 85% availability threshold")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text("Add more items with store information or try stores with better inventory")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    VStack(spacing: 8) {
                        // Best store summary
                        if let bestStore = comparison.bestStore {
                            HStack {
                                Text("Best: \(bestStore)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.green)
                                Spacer()
                                Text("$\(String(format: "%.2f", comparison.bestTotalPrice))")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                        }
                        // Store rankings
                        ForEach(Array(comparison.storePrices.enumerated()), id: \.offset) { index, storePrice in
                            StorePriceRow(
                                storePrice: storePrice,
                                isBest: storePrice.store == comparison.bestStore,
                                rank: index + 1
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            } else {
                VStack(spacing: 8) {
                    Text("No price comparison available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Scan barcodes to add items with store information")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
        }
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .sheet(isPresented: $showingShareExperience) {
            ShareExperienceView(priceComparison: priceComparison)
        }
    }
}
struct StorePriceRow: View {
    let storePrice: StorePrice
    let isBest: Bool
    let rank: Int
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                // Rank
                Text("\(rank).")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(width: 20, alignment: .leading)
                // Store name
                Text(storePrice.store)
                    .font(.subheadline)
                    .fontWeight(isBest ? .semibold : .regular)
                    .foregroundColor(isBest ? .green : .primary)
                Spacer()
                // Price
                VStack(alignment: .trailing, spacing: 2) {
                    Text("$\(String(format: "%.2f", storePrice.totalPrice))")
                        .font(.subheadline)
                        .fontWeight(isBest ? .bold : .medium)
                        .foregroundColor(isBest ? .green : .primary)
                    Text("\(storePrice.availableItems)/\(storePrice.availableItems + storePrice.unavailableItems) items")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

        }
        .padding(.vertical, 4)
    }
}
