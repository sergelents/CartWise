//
//  YourListView.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/5/25.
//

import SwiftUI

struct YourListView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("List")
                    .font(.title)
                Spacer()
            }
            .navigationTitle("Your Shopping List")
        }
    }
}
