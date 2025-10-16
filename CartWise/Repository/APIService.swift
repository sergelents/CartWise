//
//  APIService.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/10/25.
//
import Foundation
import CoreData
protocol NetworkServiceProtocol: Sendable {
    func fetchProduct(by name: String) async throws -> APIProduct?
    func searchProducts(by name: String) async throws -> [APIProduct]
    func searchProductsOnAmazon(by query: String) async throws -> [APIProduct]
    func searchProductsOnWalmart(by query: String) async throws -> [APIProduct]
    func fetchProductWithRetry(by name: String, retries: Int) async throws -> APIProduct?
    func searchGroceryPrice(productName: String, store: Store) async throws -> APIProduct?
    // MealMe: image-focused search
    func searchProductsOnMealMe(by query: String) async throws -> [APIProduct]
    // Keychain management
    func setMealMeAPIKey(_ apiKey: String) -> Bool
    func hasMealMeAPIKey() -> Bool
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
    // MealMe configuration
    private let mealMeBaseURL = "https://api.mealme.ai"
    private let mealMeApiKeyHeader = "X-API-Key" // adjust to "Authorization" with Bearer if required
    private let keychainHelper = KeychainHelper.shared
    init(session: URLSession = .shared) {
        self.session = session
    }
    func searchProducts(by name: String) async throws -> [APIProduct] {
        let url = try buildSearchURL(for: name)
        let response = try await performRequest(url: url, responseType: APIResponse.self)
        return response.products
    }
    func searchProductsOnAmazon(by query: String) async throws -> [APIProduct] {
        let url = try buildStoreSearchURL(for: query, store: .amazon)
        let response = try await performRequest(url: url, responseType: APIResponse.self)
        return response.products
    }
    func searchProductsOnWalmart(by query: String) async throws -> [APIProduct] {
        let url = try buildStoreSearchURL(for: query, store: .walmart)
        let response = try await performRequest(url: url, responseType: APIResponse.self)
        return response.products
    }

    // MARK: - MealMe: Product/Image search
    func searchProductsOnMealMe(by query: String) async throws -> [APIProduct] {
        guard let url = buildMealMeSearchURL(query: query) else {
            throw NetworkError.invalidURL
        }
        let response: MealMeSearchResponse = try await performMealMeRequest(url: url, responseType: MealMeSearchResponse.self)
        // Map MealMe items to APIProduct minimally for image fetching
        let products: [APIProduct] = response.results.compactMap { item in
            let name = item.title ?? item.name ?? ""
            let image = item.imageUrl ?? item.image ?? ""
            guard !name.isEmpty, !image.isEmpty else { return nil }
            return APIProduct(
                name: name,
                price: item.price ?? "",
                currency: item.currency ?? "",
                customerReview: "",
                customerReviewCount: "",
                shippingMessage: "",
                amazonLink: item.link ?? item.url ?? "",
                image: image,
                boughtInfo: ""
            )
        }
        return products
    }
    
    // MARK: - Keychain Management
    
    func setMealMeAPIKey(_ apiKey: String) -> Bool {
        return keychainHelper.saveMealMeAPIKey(apiKey)
    }
    
    func hasMealMeAPIKey() -> Bool {
        return keychainHelper.loadMealMeAPIKey() != nil
    }
    
    func searchGroceryPrice(productName: String, store: Store) async throws -> APIProduct? {
        let url = try buildStoreSearchURL(for: productName, store: store)
        let response = try await performRequest(url: url, responseType: APIResponse.self)
        // Return the first product from the API response
        return response.products.first
    }
    func fetchProduct(by name: String) async throws -> APIProduct? {
        // For grocery prices API, we search by name and return the first result
        let products = try await searchProducts(by: name)
        return products.first
    }
    func fetchProductWithRetry(by name: String, retries: Int = 3) async throws -> APIProduct? {
        var lastError: Error?
        for attempt in 1...retries {
            do {
                return try await fetchProduct(by: name)
            } catch {
                lastError = error
                if attempt < retries {
                    // Exponential backoff
                    try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt))) * 1_000_000_000)
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

    // MARK: - MealMe helpers
    private func buildMealMeSearchURL(query: String) -> URL? {
        // Common image/search path; adjust per MealMe docs if different
        var components = URLComponents(string: "\(mealMeBaseURL)/search")
        components?.queryItems = [
            URLQueryItem(name: "query", value: query)
        ]
        return components?.url
    }

    private func performMealMeRequest<T: Decodable>(url: URL, responseType: T.Type) async throws -> T {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Get API key from Keychain
        if let mealMeApiKey = keychainHelper.loadMealMeAPIKey(), !mealMeApiKey.isEmpty {
            request.setValue(mealMeApiKey, forHTTPHeaderField: mealMeApiKeyHeader)
        } else {
            print("MealMe: No API key found in Keychain")
            throw NetworkError.invalidResponse
        }
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        if let jsonString = String(data: data, encoding: .utf8) {
            print("MealMe: Raw JSON response: \(jsonString)")
        }
        switch httpResponse.statusCode {
        case 200:
            do {
                let decoder = JSONDecoder()
                return try decoder.decode(responseType, from: data)
            } catch {
                print("MealMe: Decoding error: \(error)")
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

// MARK: - MealMe Response Models (minimal for images)
struct MealMeSearchResponse: Decodable {
    let results: [MealMeItem]
}

struct MealMeItem: Decodable {
    let title: String?
    let name: String?
    let imageUrl: String?
    let image: String?
    let url: String?
    let link: String?
    let price: String?
    let currency: String?
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
