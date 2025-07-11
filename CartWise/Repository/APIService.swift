//
//  APIService.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/10/25.
//


import Foundation

protocol NetworkServiceProtocol: Sendable {
    func fetchProduct(by barcode: String) async throws -> OpenFoodFactsProduct?
    func searchProducts(by name: String) async throws -> [OpenFoodFactsProduct]
    func fetchProductWithRetry(by barcode: String, retries: Int) async throws -> OpenFoodFactsProduct?
}

final class NetworkService: NetworkServiceProtocol, @unchecked Sendable {
    private let session: URLSession
    private let baseURL = "https://world.openfoodfacts.org/api/v0/product/"
    private let searchURL = "https://world.openfoodfacts.org/cgi/search.pl"
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func fetchProduct(by barcode: String) async throws -> OpenFoodFactsProduct? {
        let url = try buildProductURL(for: barcode)
        return try await performRequest(url: url, responseType: OpenFoodFactsResponse.self).product
    }
    
    func searchProducts(by name: String) async throws -> [OpenFoodFactsProduct] {
        let url = try buildSearchURL(for: name)
        let response: SearchResponse = try await performRequest(url: url, responseType: SearchResponse.self)
        return response.products
    }
    
    func fetchProductWithRetry(by barcode: String, retries: Int = 3) async throws -> OpenFoodFactsProduct? {
        var lastError: Error?
        
        for attempt in 1...retries {
            do {
                return try await fetchProduct(by: barcode)
            } catch {
                lastError = error
                if attempt < retries {
                    try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt))) * 1_000_000_000) // Exponential backoff
                }
            }
        }
        
        throw lastError ?? NetworkError.maxRetriesExceeded
    }
    
    // MARK: - Private Methods
    
    private func buildProductURL(for barcode: String) throws -> URL {
        guard let url = URL(string: "\(baseURL)\(barcode).json") else {
            throw NetworkError.invalidURL
        }
        return url
    }
    
    private func buildSearchURL(for name: String) throws -> URL {
        var components = URLComponents(string: searchURL)!
        components.queryItems = [
            URLQueryItem(name: "search_terms", value: name),
            URLQueryItem(name: "search_simple", value: "1"),
            URLQueryItem(name: "action", value: "process"),
            URLQueryItem(name: "json", value: "1"),
            URLQueryItem(name: "page_size", value: "20") // Limit results
        ]
        
        guard let url = components.url else {
            throw NetworkError.invalidURL
        }
        return url
    }
    
    private func performRequest<T: Decodable>(url: URL, responseType: T.Type) async throws -> T {
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
        
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
}

// MARK: - Response Models

struct SearchResponse: Codable, Sendable {
    let products: [OpenFoodFactsProduct]
    let count: Int?
    let page: Int?
    let pageSize: Int?
}

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
