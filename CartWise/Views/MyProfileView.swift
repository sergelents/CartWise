//
//  MyProfileView.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/5/25.
//

import SwiftUI

struct MyProfileView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @StateObject private var productViewModel = ProductViewModel(repository: ProductRepository())
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundSecondary
                    .ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 28) {
                        // Profile Card
                        VStack(spacing: 12) {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .frame(width: 80, height: 80)
                                .foregroundColor(AppColors.accentGreen)
                                .padding(.top, 24)
                            Text("My Profile")
                                .font(.poppins(size: 24, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)
                            Text("Manage your favorites and account")
                                .font(.poppins(size: 15, weight: .regular))
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(18)
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                        .padding(.horizontal)
                        
                        // Favorites Section (Card)
                        FavoriteItemsView(productViewModel: productViewModel)
                            .padding(.horizontal)
                            .padding(.top, 4)
                        
                        // Log Out Button (Card style)
                        Button(action: {
                            isLoggedIn = false
                        }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 18))
                                Text("Log Out")
                                    .font(.poppins(size: 17, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(AppColors.accentRed)
                            .cornerRadius(14)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                    }
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
