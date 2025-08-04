//
//  ImageService.swift
//  CartWise
//
//  Created by Kelly Yong on 8/4/25.
//  Enhanced with AI assistance from Cursor AI for UI improvements and functionality.
//

import Foundation
import SwiftUI

protocol ImageServiceProtocol {
    func fetchImageURL(for productName: String) async throws -> String?
    func loadImage(from url: URL) async throws -> UIImage?
}

class ImageService: ImageServiceProtocol {
    private let networkService: NetworkService
    
    init(networkService: NetworkService = NetworkService()) {
        self.networkService = networkService
    }
    
    // Fetches image URL for a product from Amazon API
    func fetchImageURL(for productName: String) async throws -> String? {
        do {
            let amazonProducts = try await networkService.searchProductsOnAmazon(by: productName)
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