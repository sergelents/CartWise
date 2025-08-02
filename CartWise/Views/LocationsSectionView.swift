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
        VStack(alignment: .leading, spacing: 20) {
            // Enhanced Header
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    AppColors.accentGreen.opacity(0.2),
                                    AppColors.accentGreen.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "location.circle.fill")
                        .foregroundColor(AppColors.accentGreen)
                        .font(.system(size: 18, weight: .medium))
                }
                
                Text("My Locations")
                    .font(.poppins(size: 22, weight: .bold))
                    .foregroundColor(.primary)
                    .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Text("\(locations.count) locations")
                        .font(.poppins(size: 15, weight: .medium))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.1))
                        )
                    
                    Button(action: {
                        showAddLocation = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            AppColors.accentGreen.opacity(0.2),
                                            AppColors.accentGreen.opacity(0.1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "plus")
                                .foregroundColor(AppColors.accentGreen)
                                .font(.system(size: 14, weight: .medium))
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            
            // Enhanced Locations List
            if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading locations...")
                        .font(.poppins(size: 14, weight: .regular))
                        .foregroundColor(.gray)
                }
                .frame(height: 100)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else if locations.isEmpty {
                // Enhanced Empty State
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.gray.opacity(0.1),
                                        Color.gray.opacity(0.05)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "heart.slash")
                            .font(.system(size: 36, weight: .light))
                            .foregroundColor(.gray.opacity(0.6))
                    }
                    
                    VStack(spacing: 8) {
                        Text("No favorite locations yet")
                            .font(.poppins(size: 20, weight: .semibold))
                            .foregroundColor(.gray)
                        
                        Text("Add locations and mark them as favorites to see them here")
                            .font(.poppins(size: 15, weight: .regular))
                            .foregroundColor(.gray.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    
                    Button(action: {
                        showAddLocation = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16, weight: .medium))
                            Text("Add Location")
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
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                // Enhanced Locations List
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(locations) { location in
                            LocationRowView(location: location, productViewModel: productViewModel)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .frame(maxHeight: 320)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
        )
        .padding(.vertical, 16)
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
            
            // Fetch only favorited locations
            let locationFetchRequest: NSFetchRequest<Location> = Location.fetchRequest()
            locationFetchRequest.predicate = NSPredicate(format: "user == %@ AND favorited == YES", currentUser)
            locationFetchRequest.sortDescriptors = [
                NSSortDescriptor(keyPath: \Location.isDefault, ascending: false),
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
    let productViewModel: ProductViewModel
    @State private var showEditLocation: Bool = false
    
    var body: some View {
        Button(action: {
            showEditLocation = true
        }) {
            HStack(spacing: 16) {
            // Enhanced Location icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                AppColors.accentGreen.opacity(0.2),
                                AppColors.accentGreen.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: "location.circle.fill")
                            .foregroundColor(AppColors.accentGreen)
                            .font(.system(size: 24, weight: .medium))
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(location.name ?? "Unknown Location")
                        .font(.poppins(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    if location.isDefault {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.yellow)
                    }
                }
                
                Text(formatAddress())
                    .font(.poppins(size: 14, weight: .regular))
                    .foregroundColor(.gray)
                    .lineLimit(2)
                
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                    Text("Favorite Location")
                        .font(.poppins(size: 12, weight: .medium))
                        .foregroundColor(.red)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Edit Icon
            Image(systemName: "pencil.circle.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(AppColors.accentGreen)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showEditLocation) {
            EditLocationView(location: location)
                .environmentObject(productViewModel)
        }
    }
    
    private func formatAddress() -> String {
        var components: [String] = []
        
        if let address = location.address, !address.isEmpty {
            components.append(address)
        }
        
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