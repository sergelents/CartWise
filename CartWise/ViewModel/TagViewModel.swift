//
//  TagViewModel.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 11/7/25.
//
import SwiftUI
import Combine
import CoreData
import Foundation

@MainActor
final class TagViewModel: ObservableObject {
    @Published var tags: [Tag] = []
    @Published var errorMessage: String?
    
    private let repository: ProductRepositoryProtocol
    
    init(repository: ProductRepositoryProtocol) {
        self.repository = repository
        Task {
            await loadTags()
        }
    }
    
    // MARK: - Tag Management
    
    func loadTags() async {
        do {
            tags = try await repository.fetchAllTags()
            errorMessage = nil
        } catch {
            print("Error loading tags: \(error)")
            tags = []
            errorMessage = "Failed to load tags: \(error.localizedDescription)"
        }
    }
    
    func fetchAllTags() async -> [Tag] {
        do {
            return try await repository.fetchAllTags()
        } catch {
            print("Error fetching tags: \(error)")
            return []
        }
    }
    
    func createTag(name: String, color: String) async {
        do {
            let id = UUID().uuidString
            _ = try await repository.createTag(id: id, name: name, color: color)
            await loadTags()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to create tag: \(error.localizedDescription)"
        }
    }
    
    func updateTag(_ tag: Tag) async {
        do {
            try await repository.updateTag(tag)
            await loadTags()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to update tag: \(error.localizedDescription)"
        }
    }
    
    func initializeDefaultTags() async {
        do {
            try await repository.initializeDefaultTags()
            await loadTags()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to initialize default tags: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Product-Tag Association
    
    func addTagsToProduct(_ product: GroceryItem, tags: [Tag]) async {
        do {
            try await repository.addTagsToProduct(product, tags: tags)
            errorMessage = nil
        } catch {
            errorMessage = "Failed to add tags to product: \(error.localizedDescription)"
        }
    }
    
    func replaceTagsForProduct(_ product: GroceryItem, tags: [Tag]) async {
        do {
            try await repository.replaceTagsForProduct(product, tags: tags)
            errorMessage = nil
        } catch {
            errorMessage = "Failed to replace tags for product: \(error.localizedDescription)"
        }
    }
    
    func removeTagsFromProduct(_ product: GroceryItem, tags: [Tag]) async {
        do {
            try await repository.removeTagsFromProduct(product, tags: tags)
            errorMessage = nil
        } catch {
            errorMessage = "Failed to remove tags from product: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Helper Methods
    
    func getTagByName(_ name: String) -> Tag? {
        return tags.first { $0.name?.lowercased() == name.lowercased() }
    }
    
    func getTagsByColor(_ color: String) -> [Tag] {
        return tags.filter { $0.color == color }
    }
    
    func searchTags(by query: String) -> [Tag] {
        guard !query.isEmpty else { return tags }
        return tags.filter { tag in
            tag.name?.lowercased().contains(query.lowercased()) ?? false
        }
    }
}

