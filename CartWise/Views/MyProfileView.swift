//
//  MyProfileView.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/5/25.
//

import SwiftUI

struct MyProfileView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("About Me")
                    .font(.title)
                Spacer()
            }
            .navigationTitle("Profile")
        }
    }
}
