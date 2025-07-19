//
//  OpenFoodFactsService.swift
//  CartWise
//
//  Created by Alex Kumar on 12/19/25.
//

import Foundation

protocol OpenFoodFactsServiceProtocol: Sendable {
    func searchProduct(by barcode: String) async throws -> OpenFoodFactsProduct?
    func searchProducts(by query: String) async throws -> [OpenFoodFactsProduct]
}

final class OpenFoodFactsService: OpenFoodFactsServiceProtocol, @unchecked Sendable {
    private let session: URLSession
    private let baseURL = "https://world.openfoodfacts.org"
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func searchProduct(by barcode: String) async throws -> OpenFoodFactsProduct? {
        let url = try buildProductURL(for: barcode)
        let response = try await performRequest(url: url, responseType: OpenFoodFactsResponse.self)
        return response.product
    }
    
    func searchProducts(by query: String) async throws -> [OpenFoodFactsProduct] {
        let url = try buildSearchURL(for: query)
        let response = try await performRequest(url: url, responseType: OpenFoodFactsSearchResponse.self)
        return response.products ?? []
    }
    
    // MARK: - Private Methods
    
    private func buildProductURL(for barcode: String) throws -> URL {
        guard let url = URL(string: "\(baseURL)/api/v0/product/\(barcode).json") else {
            throw OpenFoodFactsError.invalidURL
        }
        return url
    }
    
    private func buildSearchURL(for query: String) throws -> URL {
        var components = URLComponents(string: "\(baseURL)/cgi/search.pl")!
        components.queryItems = [
            URLQueryItem(name: "search_terms", value: query),
            URLQueryItem(name: "search_simple", value: "1"),
            URLQueryItem(name: "action", value: "process"),
            URLQueryItem(name: "json", value: "1")
        ]
        
        guard let url = components.url else {
            throw OpenFoodFactsError.invalidURL
        }
        return url
    }
    
    private func performRequest<T: Decodable>(url: URL, responseType: T.Type) async throws -> T {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("CartWise/1.0", forHTTPHeaderField: "User-Agent")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenFoodFactsError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                return try decoder.decode(responseType, from: data)
            } catch {
                throw OpenFoodFactsError.decodingError(error)
            }
        case 404:
            throw OpenFoodFactsError.productNotFound
        case 429:
            throw OpenFoodFactsError.rateLimitExceeded
        case 500...599:
            throw OpenFoodFactsError.serverError(httpResponse.statusCode)
        default:
            throw OpenFoodFactsError.httpError(httpResponse.statusCode)
        }
    }
}

// MARK: - Response Models

struct OpenFoodFactsResponse: Codable, Sendable {
    let status: Int
    let statusVerbose: String?
    let product: OpenFoodFactsProduct?
    
    enum CodingKeys: String, CodingKey {
        case status
        case statusVerbose = "status_verbose"
        case product
    }
}

struct OpenFoodFactsSearchResponse: Codable, Sendable {
    let products: [OpenFoodFactsProduct]?
    let count: Int?
    let page: Int?
    let pageSize: Int?
    
    enum CodingKeys: String, CodingKey {
        case products
        case count
        case page
        case pageSize = "page_size"
    }
}

struct OpenFoodFactsProduct: Codable, Sendable {
    let code: String?
    let productName: String?
    let brands: String?
    let categories: String?
    let imageURL: String?
    let nutritionGrades: String?
    let ingredientsText: String?
    let allergens: String?
    let nutritionDataPer: String?
    let nutritionFacts: NutritionFacts?
    let nutriments: Nutriments?
    let imageFrontURL: String?
    let imageIngredientsURL: String?
    let imageNutritionURL: String?
    let genericName: String?
    let quantity: String?
    let packaging: String?
    let origins: String?
    let manufacturingPlaces: String?
    let labels: String?
    let traces: String?
    let states: String?
    let ecoscoreGrade: String?
    let novaGroup: String?
    
    enum CodingKeys: String, CodingKey {
        case code
        case productName = "product_name"
        case brands
        case categories
        case imageURL = "image_url"
        case nutritionGrades = "nutrition_grade_fr"
        case ingredientsText = "ingredients_text"
        case allergens
        case nutritionDataPer = "nutrition_data_per"
        case nutritionFacts = "nutrition_facts"
        case nutriments
        case imageFrontURL = "image_front_url"
        case imageIngredientsURL = "image_ingredients_url"
        case imageNutritionURL = "image_nutrition_url"
        case genericName = "generic_name"
        case quantity
        case packaging
        case origins
        case manufacturingPlaces = "manufacturing_places"
        case labels
        case traces
        case states
        case ecoscoreGrade = "ecoscore_grade"
        case novaGroup = "nova_group"
    }
}

struct NutritionFacts: Codable, Sendable {
    let energy: String?
    let fat: String?
    let saturatedFat: String?
    let carbohydrates: String?
    let sugars: String?
    let fiber: String?
    let proteins: String?
    let salt: String?
    let sodium: String?
    
    enum CodingKeys: String, CodingKey {
        case energy
        case fat
        case saturatedFat = "saturated-fat"
        case carbohydrates
        case sugars
        case fiber
        case proteins
        case salt
        case sodium
    }
}

struct Nutriments: Codable, Sendable {
    let energy100G: Double?
    let fat100G: Double?
    let saturatedFat100G: Double?
    let carbohydrates100G: Double?
    let sugars100G: Double?
    let fiber100G: Double?
    let proteins100G: Double?
    let salt100G: Double?
    let sodium100G: Double?
    
    enum CodingKeys: String, CodingKey {
        case energy100G = "energy-kcal_100g"
        case fat100G = "fat_100g"
        case saturatedFat100G = "saturated-fat_100g"
        case carbohydrates100G = "carbohydrates_100g"
        case sugars100G = "sugars_100g"
        case fiber100G = "fiber_100g"
        case proteins100G = "proteins_100g"
        case salt100G = "salt_100g"
        case sodium100G = "sodium_100g"
    }
}

// MARK: - Error Handling

enum OpenFoodFactsError: Error, LocalizedError, Sendable {
    case invalidURL
    case invalidResponse
    case noData
    case productNotFound
    case rateLimitExceeded
    case serverError(Int)
    case httpError(Int)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .noData:
            return "No data received"
        case .productNotFound:
            return "Product not found in Open Food Facts database"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .serverError(let code):
            return "Server error (\(code))"
        case .httpError(let code):
            return "HTTP error (\(code))"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .productNotFound:
            return "The product with this barcode was not found in the Open Food Facts database."
        case .rateLimitExceeded:
            return "Please wait a moment before trying again."
        case .serverError, .httpError:
            return "Please check your internet connection and try again."
        default:
            return nil
        }
    }
} 