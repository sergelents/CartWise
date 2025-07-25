//
//  MyProfileView.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/5/25.
//

import SwiftUI
import CoreData
import MapKit
import Combine

let accentGreen = Color(red: 0/255, green: 181/255, blue: 83/255)
let accentYellow = Color(red: 255/255, green: 215/255, blue: 0/255)

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    // Add state for add store form
    @State private var newStoreName: String = ""
    @State private var newStoreAddress: String = ""
    @State private var addStoreError: String? = nil
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
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
                        
                        // Saved Grocery Stores Section
                        SectionHeader(title: "Saved Grocery Stores", onEdit: { viewModel.isEditingStores.toggle() }, isEditing: viewModel.isEditingStores)
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
                        Spacer(minLength: 100)
                        
                        // Nearby Grocery Stores Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Nearby Grocery Stores")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .padding(.horizontal)
                            Button(action: { viewModel.findNearbyGroceryStores() }) {
                                HStack {
                                    Image(systemName: "location.circle.fill")
                                        .foregroundColor(accentGreen)
                                    Text(viewModel.isFindingNearbyStores ? "Finding..." : "Find Nearby Grocery Stores")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .padding(.horizontal)
                            }
                            if let error = viewModel.locationError {
                                Text(error)
                                    .foregroundColor(.red)
                                    .padding(.horizontal)
                            }
                            if !viewModel.nearbyStores.isEmpty {
                                ForEach(viewModel.nearbyStores) { store in
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(store.name)
                                            .font(.body)
                                            .fontWeight(.medium)
                                        Text(store.address)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        if let distance = store.distance {
                                            Text(String(format: "%.1f meters away", distance))
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                }
                VStack {
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
                NavigationView {
                    Form {
                        Section(header: Text("Store Name")) {
                            TextField("Enter store name", text: $newStoreName)
                        }
                        Section(header: Text("Store Address")) {
                            TextField("Enter store address", text: $newStoreAddress)
                        }
                        if let error = addStoreError {
                            Text(error)
                                .foregroundColor(.red)
                        }
                    }
                    .navigationTitle("Add Store")
                    .navigationBarItems(leading: Button("Cancel") {
                        viewModel.showAddStoreSheet = false
                        newStoreName = ""
                        newStoreAddress = ""
                        addStoreError = nil
                    }, trailing: Button("Add") {
                        if newStoreName.trimmingCharacters(in: .whitespaces).isEmpty || newStoreAddress.trimmingCharacters(in: .whitespaces).isEmpty {
                            addStoreError = "Please enter both name and address."
                        } else {
                            viewModel.addStore(name: newStoreName, address: newStoreAddress)
                            viewModel.showAddStoreSheet = false
                            newStoreName = ""
                            newStoreAddress = ""
                            addStoreError = nil
                        }
                    })
                }
            }
        }
    }
}

struct SectionHeader: View {
    let title: String
    let onEdit: () -> Void
    var isEditing: Bool = false
    var body: some View {
        HStack {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
            Spacer()
            Button(action: onEdit) {
                Text(isEditing ? "Done" : "Edit")
                    .font(.subheadline)
                    .foregroundColor(accentGreen)
            }
            .accessibilityLabel(isEditing ? "Done editing \(title)" : "Edit \(title)")
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

// MARK: - Models for UI
struct StoreModel: Identifiable {
    let id: UUID
    let name: String
    let address: String
}

struct NearbyGroceryStore: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let distance: Double? // in meters
}

// MARK: - ProfileViewModel
class ProfileViewModel: ObservableObject {
    @Published var savedStores: [StoreModel] = []
    @Published var isEditingStores = false
    @Published var showAddStoreSheet = false
    @Published var nearbyStores: [NearbyGroceryStore] = []
    @Published var isFindingNearbyStores = false
    @Published var locationError: String? = nil
    
    private var context: NSManagedObjectContext
    private var locationManager = LocationManager()
    private var cancellables = Set<AnyCancellable>()
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        fetchStores()
        locationManager.$lastLocation
            .sink { [weak self] location in
                guard let self = self, let location = location, self.isFindingNearbyStores else { return }
                self.searchNearbyGroceryStores(location: location)
            }
            .store(in: &cancellables)
    }
    
    func fetchStores() {
        // TODO: Fetch from Core Data
        savedStores = [
            StoreModel(id: UUID(), name: "Whole Foods Market", address: "1701 Wewatta St, Denver, CO"),
            StoreModel(id: UUID(), name: "Trader Joe's", address: "789 Pine St, Portland, OR")
        ]
    }
    
    func addStore(name: String, address: String) {
        let newStore = StoreModel(id: UUID(), name: name, address: address)
        savedStores.append(newStore)
    }
    
    func deleteStore(_ store: StoreModel) {
        // TODO: Delete from Core Data
        savedStores.removeAll { $0.id == store.id }
    }
    
    func findNearbyGroceryStores() {
        isFindingNearbyStores = true
        locationError = nil
        locationManager.requestLocation()
    }
    private func searchNearbyGroceryStores(location: CLLocation) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "grocery store"
        request.region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 5000, longitudinalMeters: 5000)
        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, error in
            DispatchQueue.main.async {
                self?.isFindingNearbyStores = false
                if let error = error {
                    self?.locationError = error.localizedDescription
                    self?.nearbyStores = []
                    return
                }
                guard let mapItems = response?.mapItems else {
                    self?.locationError = "No stores found."
                    self?.nearbyStores = []
                    return
                }
                self?.nearbyStores = mapItems.map { item in
                    NearbyGroceryStore(
                        name: item.name ?? "Unknown",
                        address: item.placemark.title ?? "",
                        distance: item.placemark.location?.distance(from: location)
                    )
                }
            }
        }
    }
}
