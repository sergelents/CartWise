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
        // Use retry with exponential backoff for resilience
        let response: MealMeSearchResponse = try await performMealMeRequestWithRetry(
            url: url,
            responseType: MealMeSearchResponse.self,
            retries: 3,
            initialDelaySeconds: 0.6
        )
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
    
    // MARK: - MealMe helpers
    private func buildMealMeSearchURL(query: String) -> URL? {
        // Common image/search path; adjust per MealMe docs if different
        var components = URLComponents(string: "\(mealMeBaseURL)/search")
        components?.queryItems = [
            URLQueryItem(name: "query", value: query)
        ]
        return components?.url
    }

    // MARK: - MealMe Retry Wrapper
    private func performMealMeRequestWithRetry<T: Decodable>(
        url: URL,
        responseType: T.Type,
        retries: Int = 3,
        initialDelaySeconds: Double = 0.5
    ) async throws -> T {
        var attempt = 0
        var delay = initialDelaySeconds
        var lastError: Error?
        while attempt < retries {
            do {
                return try await performMealMeRequest(url: url, responseType: responseType)
            } catch {
                lastError = error
                // Decide if this error is retryable
                if shouldRetryMealMe(error: error) {
                    attempt += 1
                    if attempt >= retries { break }
                    // Exponential backoff with jitter (±20%)
                    let jitter = Double.random(in: 0.8...1.2)
                    let sleepSeconds = max(0.2, delay * jitter)
                    let nanos = UInt64(sleepSeconds * 1_000_000_000)
                    try? await Task.sleep(nanoseconds: nanos)
                    delay *= 2
                    continue
                } else {
                    throw error
                }
            }
        }
        throw lastError ?? NetworkError.maxRetriesExceeded
    }

    private func shouldRetryMealMe(error: Error) -> Bool {
        if let netErr = error as? NetworkError {
            switch netErr {
            case .rateLimitExceeded:
                return true
            case .serverError:
                return true
            case .httpError(let code):
                // Retry on 408, 425, 429 and all 5xx
                return code == 408 || code == 425 || code == 429 || (500...599).contains(code)
            case .invalidResponse, .noData:
                // transient transport issues
                return true
            default:
                return false
            }
        }
        // Unknown errors: do not retry
        return false
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
    
    // MARK: - Keychain Management

    func setMealMeAPIKey(_ apiKey: String) -> Bool {
        return keychainHelper.saveMealMeAPIKey(apiKey)
    }

    func hasMealMeAPIKey() -> Bool {
        return keychainHelper.loadMealMeAPIKey() != nil
    }

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

