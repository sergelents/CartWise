//
//  ShareExperienceView.swift
//  CartWise
//
//  Created by AI Assistant on 12/19/24.
//

import SwiftUI

struct ShareExperienceView: View {
    let priceComparison: PriceComparison?
    @StateObject private var viewModel = SocialFeedViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var comment = ""
    @State private var rating: Int16 = 0
    @State private var selectedType = "price_update"
    
    private let types = [
        ("price_update", "Price Update"),
        ("store_review", "Store Review"),
        ("general", "General Comment")
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Experience Details") {
                    Picker("Type", selection: $selectedType) {
                        ForEach(types, id: \.0) { type in
                            Text(type.1).tag(type.0)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Rating")
                            .font(.headline)
                        
                        HStack(spacing: 12) {
                            ForEach(1...5, id: \.self) { star in
                                Button(action: {
                                    // If tapping the same star, clear the rating, otherwise set to the tapped star
                                    rating = rating == Int16(star) ? 0 : Int16(star)
                                }) {
                                    Image(systemName: star <= rating ? "star.fill" : "star")
                                        .foregroundColor(star <= rating ? .orange : .gray)
                                        .font(.title2)
                                        .frame(width: 32, height: 32)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
                
                if let comparison = priceComparison, let bestStore = comparison.bestStore {
                    Section("Price Comparison Info") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Best Store: \(bestStore)")
                                .font(.headline)
                                .foregroundColor(.green)
                            
                            Text("Total Price: $\(String(format: "%.2f", comparison.bestTotalPrice))")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            
                            if !comparison.storePrices.isEmpty {
                                Text("Available at \(comparison.storePrices.count) stores")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section("Your Comment") {
                    TextEditor(text: $comment)
                        .frame(minHeight: 100)
                        .onAppear {
                            if let comparison = priceComparison, let bestStore = comparison.bestStore {
                                comment = "Found great prices at \(bestStore)! Total: $\(String(format: "%.2f", comparison.bestTotalPrice))"
                            }
                        }
                }
            }
            .navigationTitle("Share Experience")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Post") {
                        postExperience()
                    }
                    .disabled(comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func postExperience() {
        viewModel.createExperience(
            comment: comment.trimmingCharacters(in: .whitespacesAndNewlines),
            rating: rating,
            type: selectedType,
            user: viewModel.getCurrentUser()
        )
        dismiss()
    }
}

#Preview {
    ShareExperienceView(priceComparison: nil)
} 