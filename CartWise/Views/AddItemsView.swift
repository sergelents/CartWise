//
//  AddItemsView.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/5/25.
//

import SwiftUI

struct AddItemsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Barcode Scanner")
                    .font(.title)
                Spacer()
            }
            .navigationTitle("Add Items")
        }
    }
}
