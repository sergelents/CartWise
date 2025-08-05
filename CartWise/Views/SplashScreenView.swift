//
//  SplashScreenView.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 8/5/25.
//

import SwiftUI

struct SplashScreenView: View {
    var body: some View {
        ZStack {
            // Background
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 8) {
                // CartWise logo
                Text("CartWise")
                    .font(.system(size: 52, weight: .bold, design: .default))
                    .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.2))
                
                // Tagline
                Text("Smart Shopping Made Simple")
                    .font(.system(size: 16, weight: .medium, design: .default))
                    .foregroundColor(.gray)
            }
        }
    }
}

#Preview {
    SplashScreenView()
} 