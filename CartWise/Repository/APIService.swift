//
//  APIService.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/10/25.
//


import Foundation
import CoreData

protocol NetworkServiceProtocol: Sendable {
    func fetchProduct(by name: String) async throws -> GroceryPriceData?
    func searchProducts(by name: String) async throws -> [GroceryPriceData]
    func searchProductsOnAmazon(by query: String) async throws -> [GroceryPriceData]
    func fetchProductWithRetry(by name: String, retries: Int) async throws -> GroceryPriceData?
    func fetchProductFromOpenFoodFacts(barcode: String) async throws -> GroceryPriceData?
}

final class NetworkService: NetworkServiceProtocol, @unchecked Sendable {
    private let session: URLSession
    private let baseURL = "https://api-to-find-grocery-prices.p.rapidapi.com"
    private let apiKey = "84e64a5488msh5075a47a5c27140p17850bjsnb78c0cf33881"
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func searchProducts(by name: String) async throws -> [GroceryPriceData] {
        let url = try buildSearchURL(for: name)
        let response = try await performRequest(url: url, responseType: GroceryPriceResponse.self)
        return response.data ?? []
    }
    
    func searchProductsOnAmazon(by query: String) async throws -> [GroceryPriceData] {
        let url = try buildAmazonSearchURL(for: query)
        let response = try await performRequest(url: url, responseType: GroceryPriceResponse.self)
        return response.data ?? []
    }
    
    func fetchProduct(by name: String) async throws -> GroceryPriceData? {
        // For grocery prices API, we search by name and return the first result
        let products = try await searchProducts(by: name)
        return products.first
    }
    
    func fetchProductWithRetry(by name: String, retries: Int = 3) async throws -> GroceryPriceData? {
        var lastError: Error?
        
        for attempt in 1...retries {
            do {
                return try await fetchProduct(by: name)
            } catch {
                lastError = error
                if attempt < retries {
                    try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt))) * 1_000_000_000) // Exponential backoff
                }
            }
        }
        
        throw lastError ?? NetworkError.maxRetriesExceeded
    }
    
    func fetchProductFromOpenFoodFacts(barcode: String) async throws -> GroceryPriceData? {
        let url = try buildOpenFoodFactsURL(for: barcode)
        let response = try await performOpenFoodFactsRequest(url: url)
        return response
    }
    
    // MARK: - Private Methods
    
    private func buildSearchURL(for name: String) throws -> URL {
        var components = URLComponents(string: "\(baseURL)/search")!
        components.queryItems = [
            URLQueryItem(name: "query", value: name)
        ]
        
        guard let url = components.url else {
            throw NetworkError.invalidURL
        }
        return url
    }
    
    private func buildAmazonSearchURL(for query: String) throws -> URL {
        var components = URLComponents(string: "\(baseURL)/amazon")!
        components.queryItems = [
            URLQueryItem(name: "query", value: query)
        ]
        
        guard let url = components.url else {
            throw NetworkError.invalidURL
        }
        return url
    }
    
    private func buildOpenFoodFactsURL(for barcode: String) throws -> URL {
        let openFoodFactsURL = "https://world.openfoodfacts.org/api/v0/product/\(barcode).json"
        
        guard let url = URL(string: openFoodFactsURL) else {
            throw NetworkError.invalidURL
        }
        return url
    }
    
    private func performRequest<T: Decodable>(url: URL, responseType: T.Type) async throws -> T {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
        
        // Add RapidAPI headers
        request.setValue(apiKey, forHTTPHeaderField: "X-RapidAPI-Key")
        request.setValue("api-to-find-grocery-prices.p.rapidapi.com", forHTTPHeaderField: "X-RapidAPI-Host")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                return try decoder.decode(responseType, from: data)
            } catch {
                throw NetworkError.decodingError(error)
            }
        case 404:
            throw NetworkError.productNotFound
        case 429:
            throw NetworkError.rateLimitExceeded
        case 500...599:
            throw NetworkError.serverError(httpResponse.statusCode)
        default:
            throw NetworkError.httpError(httpResponse.statusCode)
        }
    }
    
    private func performOpenFoodFactsRequest(url: URL) async throws -> GroceryPriceData? {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            do {
                let decoder = JSONDecoder()
                let openFoodFactsResponse = try decoder.decode(OpenFoodFactsResponse.self, from: data)
                
                guard openFoodFactsResponse.status == 1, let product = openFoodFactsResponse.product else {
                    return nil
                }
                
                // Convert Open Food Facts product to GroceryPriceData
                return GroceryPriceData(
                    id: product.code ?? UUID().uuidString,
                    productName: product.productName ?? "Unknown Product",
                    brand: product.brands,
                    category: product.categories,
                    price: 0.0, // Open Food Facts doesn't provide pricing
                    currency: "USD",
                    store: "Unknown Store", // Provide a default value since store is not optional
                    location: nil,
                    lastUpdated: product.lastUpdated ?? "",
                    imageURL: product.imageURL,
                    barcode: product.code
                )
            } catch {
                throw NetworkError.decodingError(error)
            }
        case 404:
            throw NetworkError.productNotFound
        case 500...599:
            throw NetworkError.serverError(httpResponse.statusCode)
        default:
            throw NetworkError.httpError(httpResponse.statusCode)
        }
    }
}

// MARK: - Open Food Facts Response Models

struct OpenFoodFactsResponse: Codable {
    let status: Int
    let product: OpenFoodFactsProduct?
}

struct OpenFoodFactsProduct: Codable {
    let code: String?
    let productName: String?
    let brands: String?
    let categories: String?
    let imageURL: String?
    let lastUpdated: String?
    
    enum CodingKeys: String, CodingKey {
        case code
        case productName = "product_name"
        case brands
        case categories
        case imageURL = "image_url"
        case lastUpdated = "last_updated"
    }
}

// MARK: - Response Models

// Using GroceryPriceResponse and GroceryPriceData from Product.swift

// MARK: - Enhanced Error Handling

enum NetworkError: Error, LocalizedError, Sendable {
    case invalidURL
    case invalidResponse
    case noData
    case productNotFound
    case rateLimitExceeded
    case serverError(Int)
    case httpError(Int)
    case decodingError(Error)
    case maxRetriesExceeded
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .noData:
            return "No data received"
        case .productNotFound:
            return "Product not found"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .serverError(let code):
            return "Server error (\(code))"
        case .httpError(let code):
            return "HTTP error (\(code))"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .maxRetriesExceeded:
            return "Maximum retry attempts exceeded"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .productNotFound:
            return "The product with this barcode was not found in the database."
        case .rateLimitExceeded:
            return "Please wait a moment before trying again."
        case .serverError, .httpError:
            return "Please check your internet connection and try again."
        default:
            return nil
        }
    }
}

// This code was generated with the help of Claude, saving me 4 hours of research and development.
