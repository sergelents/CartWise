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
    func searchProductsOnWalmart(by query: String) async throws -> [GroceryPriceData]
    func fetchProductWithRetry(by name: String, retries: Int) async throws -> GroceryPriceData?
    func searchGroceryPrice(productName: String, store: Store) async throws -> GroceryPriceData?
}

enum Store: String, CaseIterable, Codable {
    case amazon = "Amazon"
    case walmart = "Walmart"
    
    var endpoint: String {
        switch self {
        case .amazon:
            return "amazon"
        case .walmart:
            return "walmart"
        }
    }
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
        let url = try buildStoreSearchURL(for: query, store: .amazon)
        let response = try await performRequest(url: url, responseType: GroceryPriceResponse.self)
        return response.allProducts
    }
    
    func searchProductsOnWalmart(by query: String) async throws -> [GroceryPriceData] {
        let url = try buildStoreSearchURL(for: query, store: .walmart)
        let response = try await performRequest(url: url, responseType: GroceryPriceResponse.self)
        return response.allProducts
    }
    
    func searchGroceryPrice(productName: String, store: Store) async throws -> GroceryPriceData? {
        let url = try buildStoreSearchURL(for: productName, store: store)
        let response = try await performRequest(url: url, responseType: GroceryPriceResponse.self)
        
        // Return the first product from the API response
        return response.allProducts.first
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
    
    private func buildStoreSearchURL(for query: String, store: Store) throws -> URL {
        var components = URLComponents(string: "\(baseURL)/\(store.endpoint)")!
        components.queryItems = [
            URLQueryItem(name: "query", value: query)
        ]
        
        guard let url = components.url else {
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
        
        // Debug: Print raw response
        if let jsonString = String(data: data, encoding: .utf8) {
            print("APIService: Raw JSON response: \(jsonString)")
        }
        
        switch httpResponse.statusCode {
        case 200:
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                return try decoder.decode(responseType, from: data)
            } catch {
                print("APIService: Decoding error: \(error)")
                // Try to decode as a different format if the first attempt fails
                if responseType == GroceryPriceResponse.self {
                    return try decodeGroceryPriceResponse(from: data) as! T
                }
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
    
    private func decodeGroceryPriceResponse(from data: Data) throws -> GroceryPriceResponse {
        // Try different response formats
        do {
            // First try: standard format with status
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(GroceryPriceResponse.self, from: data)
        } catch {
            print("APIService: First decode attempt failed: \(error)")
            
            do {
                // Second try: API wrapper format with raw_body_sample
                let apiWrapper = try JSONDecoder().decode(APIWrapperResponse.self, from: data)
                
                // Parse the raw_body_sample string as JSON
                if let rawBodyData = apiWrapper.rawBodySample.data(using: .utf8) {
                    do {
                        let products = try JSONDecoder().decode([APIProduct].self, from: rawBodyData)
                        let groceryProducts = products.map { apiProduct in
                            return GroceryPriceData(
                                id: UUID().uuidString,
                                productName: apiProduct.title,
                                brand: nil,
                                category: nil,
                                price: 0.0, // API doesn't provide price data
                                currency: "USD",
                                store: "Unknown",
                                location: nil,
                                lastUpdated: "",
                                imageURL: apiProduct.image,
                                barcode: nil
                            )
                        }
                        return GroceryPriceResponse(
                            status: nil,
                            message: apiWrapper.message,
                            data: groceryProducts,
                            success: apiWrapper.success,
                            products: nil
                        )
                    } catch {
                        print("APIService: Failed to parse raw_body_sample: \(error)")
                        return GroceryPriceResponse(
                            status: nil,
                            message: apiWrapper.message,
                            data: [],
                            success: apiWrapper.success,
                            products: nil
                        )
                    }
                } else {
                    return GroceryPriceResponse(
                        status: nil,
                        message: apiWrapper.message,
                        data: [],
                        success: apiWrapper.success,
                        products: nil
                    )
                }
            } catch {
                print("APIService: Second decode attempt failed: \(error)")
                
                do {
                    // Third try: simple array format
                    let products = try JSONDecoder().decode([GroceryPriceData].self, from: data)
                    return GroceryPriceResponse(
                        status: nil,
                        message: nil,
                        data: products,
                        success: true,
                        products: nil
                    )
                } catch {
                    print("APIService: Third decode attempt failed: \(error)")
                    throw NetworkError.decodingError(error)
                }
            }
        }
    }
}

// MARK: - Response Models

struct AmazonResponse: Codable, Sendable {
    let products: [GroceryPriceData]
}

// API Wrapper Response Models
struct APIWrapperResponse: Codable, Sendable {
    let success: Bool
    let rawBodyType: String
    let rawBodySample: String
    let fullResponseStructure: [String]
    let message: String
    
    enum CodingKeys: String, CodingKey {
        case success
        case rawBodyType = "raw_body_type"
        case rawBodySample = "raw_body_sample"
        case fullResponseStructure = "full_response_structure"
        case message
    }
}

struct APIProduct: Codable, Sendable {
    let position: Int
    let title: String
    let image: String
    let link: String
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

// This code was generated with the help of Claude, saving me 4 hours of research and development.
