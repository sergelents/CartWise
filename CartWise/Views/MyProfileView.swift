//
//  MyProfileView.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/5/25.
//

import SwiftUI
import CoreData

let accentGreen = Color(red: 0/255, green: 181/255, blue: 83/255)
let accentYellow = Color(red: 255/255, green: 215/255, blue: 0/255)

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    Text("Profile")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(accentGreen)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 24)
                        .padding(.horizontal)
                        .accessibilityAddTraits(.isHeader)
                    
                    // Current Location Section
                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: "location.fill")
                            .foregroundColor(accentGreen)
                            .font(.system(size: 24))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.currentPlaceName)
                                .font(.headline)
                            Text(viewModel.currentPlaceAddress)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Button(action: { viewModel.requestLocation() }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.gray)
                        }
                        .accessibilityLabel("Refresh Location")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    .animation(.easeInOut, value: viewModel.currentPlaceName)
                    
                    // Saved Grocery Stores Section
                    SectionHeader(title: "Saved Grocery Stores", onEdit: { viewModel.isEditingStores.toggle() })
                        .padding(.horizontal)
                    VStack(spacing: 0) {
                        ForEach(viewModel.savedStores) { store in
                            StoreRow(store: store, isEditing: viewModel.isEditingStores, onDelete: { viewModel.deleteStore(store) })
                        }
                        Button(action: { viewModel.showAddStoreSheet = true }) {
                            HStack {
                                Spacer()
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(accentGreen)
                                    .font(.system(size: 32))
                                    .padding(8)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(radius: 2)
                                    .accessibilityLabel("Add Store")
                                Spacer()
                            }
                        }
                        .padding(.top, 8)
                    }
                    .background(Color.white)
                    .cornerRadius(16)
                    .padding(.horizontal)
                    .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                    
                    // Favorite Items Section
                    SectionHeader(title: "Favorite Items", onEdit: { viewModel.isEditingFavorites.toggle() })
                        .padding(.horizontal)
                    VStack(spacing: 0) {
                        ForEach(viewModel.favoriteItems) { item in
                            FavoriteItemRow(item: item, isEditing: viewModel.isEditingFavorites, onDelete: { viewModel.deleteFavorite(item) })
                        }
                        Button(action: { viewModel.showAddFavoriteSheet = true }) {
                            HStack {
                                Spacer()
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(accentGreen)
                                    .font(.system(size: 32))
                                    .padding(8)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(radius: 2)
                                    .accessibilityLabel("Add Favorite Item")
                                Spacer()
                            }
                        }
                        .padding(.top, 8)
                    }
                    .background(Color.white)
                    .cornerRadius(16)
                    .padding(.horizontal)
                    .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                    
                    // Logout Button
                    Button(action: { isLoggedIn = false }) {
                        HStack {
                            Image(systemName: "minus.circle")
                                .foregroundColor(.white)
                            Text("Log Out")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(accentGreen)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                    .accessibilityLabel("Log Out")
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $viewModel.showAddStoreSheet) {
                // TODO: Add store search/browse screen
                Text("Add Store Sheet")
            }
            .sheet(isPresented: $viewModel.showAddFavoriteSheet) {
                // TODO: Add favorite item search/browse screen
                Text("Add Favorite Item Sheet")
            }
        }
    }
}

struct SectionHeader: View {
    let title: String
    let onEdit: () -> Void
    var body: some View {
        HStack {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
            Spacer()
            Button(action: onEdit) {
                Text("Edit")
                    .font(.subheadline)
                    .foregroundColor(accentGreen)
            }
            .accessibilityLabel("Edit \(title)")
        }
        .padding(.vertical, 8)
    }
}

struct StoreRow: View {
    let store: StoreModel
    let isEditing: Bool
    let onDelete: () -> Void
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "mappin.circle")
                .foregroundColor(accentGreen)
                .font(.system(size: 24))
            VStack(alignment: .leading, spacing: 2) {
                Text(store.name)
                    .font(.body)
                    .fontWeight(.medium)
                Text(store.address)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            if isEditing {
                Button(action: onDelete) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 22))
                }
                .accessibilityLabel("Delete Store")
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.vertical, 2)
    }
}

struct FavoriteItemRow: View {
    let item: FavoriteItemModel
    let isEditing: Bool
    let onDelete: () -> Void
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "star.fill")
                .foregroundColor(accentYellow)
                .font(.system(size: 22))
            VStack(alignment: .leading, spacing: 2) {
                Text(item.productName)
                    .font(.body)
                    .fontWeight(.medium)
                HStack(spacing: 6) {
                    if let brand = item.brand {
                        Text(brand)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    if let size = item.size {
                        Text(size)
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
            Spacer()
            if isEditing {
                Button(action: onDelete) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 22))
                }
                .accessibilityLabel("Delete Favorite Item")
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.vertical, 2)
    }
}

// MARK: - Models for UI
struct StoreModel: Identifiable {
    let id: UUID
    let name: String
    let address: String
}

struct FavoriteItemModel: Identifiable {
    let id: UUID
    let productName: String
    let brand: String?
    let size: String?
}

// MARK: - ProfileViewModel
class ProfileViewModel: ObservableObject {
    @Published var currentPlaceName: String = "Current Location"
    @Published var currentPlaceAddress: String = ""
    @Published var savedStores: [StoreModel] = []
    @Published var favoriteItems: [FavoriteItemModel] = []
    @Published var isEditingStores = false
    @Published var isEditingFavorites = false
    @Published var showAddStoreSheet = false
    @Published var showAddFavoriteSheet = false
    
    private var context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        fetchStores()
        fetchFavorites()
    }
    
    func requestLocation() {
        // TODO: Integrate location logic
        currentPlaceName = "Whole Foods Market"
        currentPlaceAddress = "1701 Wewatta St, Denver, CO"
    }
    
    func fetchStores() {
        // TODO: Fetch from Core Data
        savedStores = [
            StoreModel(id: UUID(), name: "Whole Foods Market", address: "1701 Wewatta St, Denver, CO"),
            StoreModel(id: UUID(), name: "Trader Joe's", address: "789 Pine St, Portland, OR")
        ]
    }
    
    func fetchFavorites() {
        // TODO: Fetch from Core Data
        favoriteItems = [
            FavoriteItemModel(id: UUID(), productName: "Organic Bananas", brand: "Dole", size: "2 lb"),
            FavoriteItemModel(id: UUID(), productName: "Almond Milk", brand: "Silk", size: "64 oz")
        ]
    }
    
    func deleteStore(_ store: StoreModel) {
        // TODO: Delete from Core Data
        savedStores.removeAll { $0.id == store.id }
    }
    
    func deleteFavorite(_ item: FavoriteItemModel) {
        // TODO: Delete from Core Data
        favoriteItems.removeAll { $0.id == item.id }
    }
}
