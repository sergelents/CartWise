//
//  LocationsSectionView.swift
//  CartWise
//
//  Created by AI Assistant on 12/19/24.
//
import SwiftUI
import CoreData
struct LocationsSectionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var productViewModel: ProductViewModel
    @State private var showAddLocation: Bool = false
    @State private var locations: [Location] = []
    @State private var isLoading: Bool = true
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("My Locations")
                        .font(.poppins(size: 20, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                    Text("Manage your shopping locations")
                        .font(.poppins(size: 14, weight: .regular))
                        .foregroundColor(.gray)
                }
                Spacer()
                Button(action: {
                    showAddLocation = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppColors.accentGreen)
                }
            }
            // Locations List
            if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading locations...")
                        .font(.poppins(size: 14, weight: .regular))
                        .foregroundColor(.gray)
                }
                .frame(height: 100)
            } else if locations.isEmpty {
                // Empty State
                VStack(spacing: 16) {
                    Image(systemName: "location.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.gray.opacity(0.6))
                    VStack(spacing: 8) {
                        Text("No Locations Yet")
                            .font(.poppins(size: 18, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                        Text("Add your favorite shopping locations to track prices")
                            .font(.poppins(size: 14, weight: .regular))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    Button(action: {
                        showAddLocation = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16, weight: .medium))
                            Text("Add First Location")
                                .font(.poppins(size: 16, weight: .semibold))
                        }
                        .foregroundColor(AppColors.accentGreen)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppColors.accentGreen, lineWidth: 2)
                        )
                    }
                }
                .frame(height: 200)
            } else {
                // Locations List
                VStack(spacing: 12) {
                    ForEach(locations.prefix(3)) { location in
                        LocationRowView(location: location)
                    }
                    if locations.count > 3 {
                        Button(action: {
                            // TODO: Navigate to full locations list
                        }) {
                            HStack(spacing: 8) {
                                Text("View All \(locations.count) Locations")
                                    .font(.poppins(size: 14, weight: .medium))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(AppColors.accentGreen)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
        )
        .task {
            await loadLocations()
        }
        .sheet(isPresented: $showAddLocation) {
            AddLocationView()
                .environmentObject(productViewModel)
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { _ in
            Task {
                await loadLocations()
            }
        }
    }
    private func loadLocations() async {
        isLoading = true
        do {
            // Get current user
            let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \UserEntity.createdAt, ascending: false)]
            fetchRequest.fetchLimit = 1
            let users = try viewContext.fetch(fetchRequest)
            guard let currentUser = users.first else { return }
            // Fetch user's locations
            let locationFetchRequest: NSFetchRequest<Location> = Location.fetchRequest()
            locationFetchRequest.predicate = NSPredicate(format: "user == %@", currentUser)
            locationFetchRequest.sortDescriptors = [
                NSSortDescriptor(keyPath: \Location.isDefault, ascending: false),
                NSSortDescriptor(keyPath: \Location.favorited, ascending: false),
                NSSortDescriptor(keyPath: \Location.name, ascending: true)
            ]
            let fetchedLocations = try viewContext.fetch(locationFetchRequest)
            await MainActor.run {
                self.locations = fetchedLocations
                self.isLoading = false
            }
        } catch {
            print("Error loading locations: \(error)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}
struct LocationRowView: View {
    let location: Location
    var body: some View {
        HStack(spacing: 12) {
            // Location Icon
            ZStack {
                Circle()
                    .fill(AppColors.accentGreen.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.accentGreen)
            }
            // Location Details
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(location.name ?? "Unknown Location")
                        .font(.poppins(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    if location.isDefault {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.yellow)
                    }
                    if location.favorited {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                    }
                }
                Text(formatAddress())
                    .font(.poppins(size: 14, weight: .regular))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            Spacer()
            // Arrow
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray.opacity(0.6))
        }
        .padding(.vertical, 8)
    }
    private func formatAddress() -> String {
        var components: [String] = []
        if let city = location.city, !city.isEmpty {
            components.append(city)
        }
        if let state = location.state, !state.isEmpty {
            components.append(state)
        }
        if let zipCode = location.zipCode, !zipCode.isEmpty {
            components.append(zipCode)
        }
        return components.isEmpty ? "No address" : components.joined(separator: ", ")
    }
}