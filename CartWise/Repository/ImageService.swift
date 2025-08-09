//
//  ImageService.swift
//  CartWise
//
//  Created by Kelly Yong on 8/4/25.
//  Enhanced with AI assistance from Cursor AI for UI improvements and functionality.
//

import Foundation
import SwiftUI
import UIKit

protocol ImageServiceProtocol {
    func fetchImageURL(for productName: String, brand: String?, category: String?) async throws -> String?
    func loadImage(from url: URL) async throws -> UIImage?
}

class ImageService: ImageServiceProtocol {
    private let networkService: NetworkService

    init(networkService: NetworkService = NetworkService()) {
        self.networkService = networkService
    }
    // Fetches image URL for a product from Amazon API
    func fetchImageURL(for productName: String, brand: String? = nil, category: String? = nil) async throws -> String? {
        do {
            // Build search query with available information
            var searchQuery = productName

            // Add brand if available
            if let brand = brand, !brand.isEmpty {
                searchQuery += " \(brand)"
            }

            // Add category if available
            if let category = category, !category.isEmpty {
                searchQuery += " \(category)"
            }

            print("ImageService: Searching for image with query: '\(searchQuery)'")
            let amazonProducts = try await networkService.searchProductsOnAmazon(by: searchQuery)
            return amazonProducts.first?.image
        } catch {
            print("ImageService: Error fetching image for '\(productName)': \(error.localizedDescription)")
            throw error
        }
    }

    // Loads image data from URL
    func loadImage(from url: URL) async throws -> UIImage? {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return UIImage(data: data)
        } catch {
            print("ImageService: Error loading image from \(url): \(error.localizedDescription)")
            throw error
        }
    }
}
