//
//  TestContributionView.swift
//  CartWise
//
//  Created by Alex Kumar on 7/12/25.
//

import SwiftUI

struct TestContributionView: View {
    @ObservedObject var reputationViewModel: ReputationViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Test Contributions")
                        .font(.poppins(size: 24, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Tap the buttons below to simulate different types of contributions and see how they affect your reputation!")
                        .font(.poppins(size: 16, weight: .regular))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 16) {
                        ContributionButton(
                            title: "Add Price Update",
                            subtitle: "+10 points",
                            icon: "dollarsign.circle.fill",
                            color: .green
                        ) {
                            await reputationViewModel.addPriceUpdate()
                        }
                        
                        ContributionButton(
                            title: "Add New Product",
                            subtitle: "+25 points",
                            icon: "plus.circle.fill",
                            color: .orange
                        ) {
                            await reputationViewModel.addProductAddition()
                        }
                        
                        ContributionButton(
                            title: "Submit Review",
                            subtitle: "+15 points",
                            icon: "star.circle.fill",
                            color: .yellow
                        ) {
                            await reputationViewModel.addReviewSubmission()
                        }
                        
                        ContributionButton(
                            title: "Upload Photo",
                            subtitle: "+20 points",
                            icon: "camera.circle.fill",
                            color: .blue
                        ) {
                            await reputationViewModel.addPhotoUpload()
                        }
                        
                        ContributionButton(
                            title: "Store Review",
                            subtitle: "+30 points",
                            icon: "building.2.circle.fill",
                            color: .purple
                        ) {
                            await reputationViewModel.addStoreReview()
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Current Stats Display
                    let stats = reputationViewModel.getContributionStats()
                    VStack(spacing: 12) {
                        Text("Current Stats")
                            .font(.poppins(size: 18, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                        
                        HStack(spacing: 20) {
                            StatDisplay(label: "Points", value: "\(Int(stats.points))", color: .blue)
                            StatDisplay(label: "Total", value: "\(Int(stats.totalContributions))", color: .green)
                        }
                        
                        HStack(spacing: 20) {
                            StatDisplay(label: "Prices", value: "\(Int(stats.priceUpdates))", color: .orange)
                            StatDisplay(label: "Products", value: "\(Int(stats.productAdditions))", color: .purple)
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                    )
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 20)
            }
            .navigationTitle("Test Contributions")
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

struct ContributionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () async -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button {
            Task {
                await action()
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(color)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.poppins(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(subtitle)
                        .font(.poppins(size: 14, weight: .regular))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

struct StatDisplay: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.poppins(size: 20, weight: .bold))
                .foregroundColor(color)
            
            Text(label)
                .font(.poppins(size: 12, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
} 