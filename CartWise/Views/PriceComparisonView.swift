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
            
            if let comparison = priceComparison {
                // Best store summary
                if let bestStore = comparison.bestStore {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Best Price:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(bestStore)
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
                    ForEach(Array(comparison.storePrices.enumerated()), id: \.element.store) { index, storePrice in
                        StorePriceRow(
                            storePrice: storePrice, 
                            isBest: storePrice.store == comparison.bestStore,
                            rank: index + 1
                        )
                    }
                }
                .padding(.horizontal)
            } else {
                // No comparison available
                VStack(spacing: 8) {
                    Text("No price comparison available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Add items with store information to your shopping list to see price comparisons")
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

struct StoreToggleButton: View {
    let store: String
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        Button(action: {
            onToggle(!isSelected)
        }) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                
                Text(store)
                    .font(.caption)
                    .foregroundColor(isSelected ? .primary : .secondary)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StorePriceRow: View {
    let storePrice: StorePrice
    let isBest: Bool
    let rank: Int
    
    var body: some View {
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
        .padding(.vertical, 4)
    }
}
