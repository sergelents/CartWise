//
//  APIService.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/10/25.
//
import Foundation
import CoreData
protocol NetworkServiceProtocol: Sendable {
    func searchProductsOnMealMe(by query: String) async throws -> [APIProduct]
    // Keychain management
    func setMealMeAPIKey(_ apiKey: String) -> Bool
    func hasMealMeAPIKey() -> Bool
}

final class NetworkService: NetworkServiceProtocol, @unchecked Sendable {
    private let session: URLSession
    // MealMe configuration
    private let mealMeBaseURL = "https://api.mealme.ai"
    private let mealMeApiKeyHeader = "X-API-Key" // adjust to "Authorization" with Bearer if required
    private let keychainHelper = KeychainHelper.shared
    init(session: URLSession = .shared) {
        self.session = session
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
