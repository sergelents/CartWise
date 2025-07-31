//
//  PriceComparisonView.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/19/25.
//

import SwiftUI

struct PriceComparisonView: View {
    let priceComparison: PriceComparison?
    let isLoading: Bool
    let onRefresh: () async -> Void
    let onLocalComparison: () async -> Void
    
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
                    Button(action: {
                        Task {
                            await onLocalComparison()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            Divider()
                .padding(.horizontal)
            
            if let comparison = priceComparison {
                // Best store summary
                if let bestStore = comparison.bestStore {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Best Price:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(bestStore.rawValue)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        }
                        
                        HStack {
                            Text("Total:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("$\(String(format: "%.2f", comparison.bestTotalPrice))")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        
                        HStack {
                            Text("Items Available:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(comparison.availableItems)/\(comparison.totalItems)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Store breakdown
                VStack(spacing: 8) {
                    ForEach(comparison.storePrices, id: \.store) { storePrice in
                        StorePriceRow(storePrice: storePrice, isBest: storePrice.store == comparison.bestStore)
                    }
                }
                .padding(.horizontal)
            } else {
                // No comparison available
                VStack(spacing: 8) {
                    Text("No price comparison available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Add items to your shopping list to see price comparisons")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
        }
        .padding(.vertical, 8)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct StorePriceRow: View {
    let storePrice: StorePrice
    let isBest: Bool
    
    var body: some View {
        HStack {
            // Store icon
            Image(systemName: storeIcon)
                .foregroundColor(storeColor)
                .frame(width: 24, height: 24)
            
            // Store name
            Text(storePrice.store.rawValue)
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
        .padding(.vertical, 4)
    }
    
    private var storeIcon: String {
        let storeName = storePrice.store.rawValue.lowercased()
        switch storeName {
        case "amazon":
            return "cart.fill"
        case "walmart":
            return "building.2.fill"
        case "target":
            return "target"
        case "kroger":
            return "building"
        case "safeway":
            return "building.2"
        case "whole foods":
            return "leaf.fill"
        default:
            return "storefront"
        }
    }
    
    private var storeColor: Color {
        let storeName = storePrice.store.rawValue.lowercased()
        switch storeName {
        case "amazon":
            return .orange
        case "walmart":
            return .blue
        case "target":
            return .red
        case "kroger":
            return .blue
        case "safeway":
            return .green
        case "whole foods":
            return .green
        default:
            return .gray
        }
    }
}

#Preview {
    let sampleComparison = PriceComparison(
        storePrices: [
            StorePrice(
                store: .amazon,
                totalPrice: 45.67,
                currency: "USD",
                availableItems: 8,
                unavailableItems: 2,
                itemPrices: [:]
            ),
            StorePrice(
                store: .walmart,
                totalPrice: 42.99,
                currency: "USD",
                availableItems: 9,
                unavailableItems: 1,
                itemPrices: [:]
            )
        ],
        bestStore: .walmart,
        bestTotalPrice: 42.99,
        bestCurrency: "USD",
        totalItems: 10,
        availableItems: 9
    )
    
    PriceComparisonView(
        priceComparison: sampleComparison,
        isLoading: false,
        onRefresh: {},
        onLocalComparison: {}
    )
    .padding()
} 