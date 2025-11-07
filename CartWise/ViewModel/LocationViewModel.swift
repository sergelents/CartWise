//
//  LocationViewModel.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 11/7/25.
//
import SwiftUI
import Combine
import CoreData
import Foundation

@MainActor
final class LocationViewModel: ObservableObject {
    @Published var locations: [Location] = []
    @Published var errorMessage: String?
    
    private let repository: ProductRepositoryProtocol
    
    init(repository: ProductRepositoryProtocol) {
        self.repository = repository
    }
    
    // MARK: - Location Management
    
    func loadLocations() async {
        do {
            locations = try await repository.fetchUserLocations()
            errorMessage = nil
        } catch {
            print("Error loading locations: \(error)")
            locations = []
            errorMessage = "Failed to load locations: \(error.localizedDescription)"
        }
    }
    
    func createLocation(name: String, address: String, city: String?, state: String?, zipCode: String?) async {
        do {
            let id = UUID().uuidString
            _ = try await repository.createLocation(
                id: id,
                name: name,
                address: address,
                city: city ?? "",
                state: state ?? "",
                zipCode: zipCode ?? ""
            )
            await loadLocations()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to create location: \(error.localizedDescription)"
        }
    }
    
    func updateLocation(_ location: Location, name: String?, address: String?, city: String?, state: String?, zipCode: String?) async {
        do {
            if let name = name {
                location.name = name
            }
            if let address = address {
                location.address = address
            }
            if let city = city {
                location.city = city
            }
            if let state = state {
                location.state = state
            }
            if let zipCode = zipCode {
                location.zipCode = zipCode
            }
            
            try await repository.updateLocation(location)
            await loadLocations()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to update location: \(error.localizedDescription)"
        }
    }
    
    func deleteLocation(_ location: Location) async {
        do {
            try await repository.deleteLocation(location)
            await loadLocations()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to delete location: \(error.localizedDescription)"
        }
    }
    
    func toggleLocationFavorite(_ location: Location) async {
        do {
            try await repository.toggleLocationFavorite(location)
            await loadLocations()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to toggle favorite: \(error.localizedDescription)"
        }
    }
    
    func setDefaultLocation(_ location: Location) async {
        do {
            try await repository.setLocationAsDefault(location)
            await loadLocations()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to set default location: \(error.localizedDescription)"
        }
    }
    
    func getDefaultLocation() -> Location? {
        return locations.first { $0.isDefault }
    }
    
    func getFavoriteLocations() -> [Location] {
        return locations.filter { $0.favorited }
    }
}
