//
//  RatingComponents.swift
//  CartWise
//
//  Extracted from YourListView.swift
//

import SwiftUI

// Rating Prompt View
struct RatingPromptView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showRatingScreen = false
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(AppColors.accentGreen)
                Text("Have you finished shopping?")
                    .font(.poppins(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                Text("Rate your experience")
                    .font(.poppins(size: 16, weight: .regular))
                    .foregroundColor(.gray)
            }
            .padding(.top, 40)
            Spacer()
            // Action Buttons
            VStack(spacing: 12) {
                Button(action: {
                    showRatingScreen = true
                }) {
                    Text("Rate my experience")
                        .font(.poppins(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(AppColors.accentGreen)
                        .cornerRadius(12)
                        .contentShape(Rectangle())
                }
                Button(action: {
                    dismiss()
                }) {
                    Text("No thanks")
                        .font(.poppins(size: 16, weight: .regular))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .contentShape(Rectangle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(AppColors.backgroundSecondary)
        .sheet(isPresented: $showRatingScreen) {
            ShoppingExperienceRatingView(dismissAll: {
                dismiss()
                showRatingScreen = false
            })
        }
    }
}

// Shopping Experience Rating View
struct ShoppingExperienceRatingView: View {
    var dismissAll: () -> Void
    @State private var pricingRating: Int = 0
    @State private var overallRating: Int = 0
    var body: some View {
        VStack(spacing: 32) {
            Text("Rate your shopping Experience!")
                .font(.poppins(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.top, 32)
            VStack(alignment: .leading, spacing: 12) {
                Text("Grocery Store")
                    .font(.poppins(size: 20, weight: .bold))
                // TODO: Connect to Google Maps API for live store info
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(AppColors.accentGreen)
                    Text("Whole Foods Market")
                        .font(.poppins(size: 17, weight: .semibold))
                    Spacer()
                    Text("1701 Wewatta St.")
                        .font(.poppins(size: 15, weight: .regular))
                        .foregroundColor(.gray)
                }
                .padding(12)
                .background(Color.gray.opacity(0.10))
                .cornerRadius(16)
            }
            .padding(.horizontal, 16)
            VStack(alignment: .leading, spacing: 8) {
                Text("Pricing Accuracy")
                    .font(.poppins(size: 20, weight: .bold))
                StarRatingView(rating: $pricingRating, accentColor: AppColors.accentGreen)
            }
            .padding(.horizontal, 16)
            VStack(alignment: .leading, spacing: 8) {
                Text("Overall Experience")
                    .font(.poppins(size: 20, weight: .bold))
                StarRatingView(rating: $overallRating, accentColor: AppColors.accentGreen)
            }
            .padding(.horizontal, 16)
            Spacer()
            // Action Buttons
            VStack(spacing: 12) {
                Button(action: {
                    // TODO: Handle submit logic
                    dismissAll()
                }) {
                    Text("Submit")
                        .font(.poppins(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(AppColors.accentGreen)
                        .cornerRadius(12)
                        .contentShape(Rectangle())
                }
                Button(action: {
                    dismissAll()
                }) {
                    Text("Cancel")
                        .font(.poppins(size: 16, weight: .regular))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .contentShape(Rectangle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(AppColors.backgroundSecondary)
        .cornerRadius(24)
        .padding(8)
    }
}

// Star Rating View
struct StarRatingView: View {
    @Binding var rating: Int
    var accentColor: Color = .yellow
    let maxRating = 5
    var body: some View {
        HStack(spacing: 16) {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: rating >= index ? "star.fill" : "star")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 36, height: 36)
                    .foregroundColor(accentColor)
                    .onTapGesture {
                        rating = index
                    }
            }
        }
    }
}