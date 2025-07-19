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
    func testAPI() async
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
        print("🔍 Searching Open Food Facts for: \(query)")
        print("🌐 URL: \(url)")
        
        do {
            let response = try await performRequest(url: url, responseType: OpenFoodFactsSearchResponse.self)
            let products = response.products ?? []
            print("📦 Found \(products.count) products")
            
            // Debug: Print first product details if available
            if let firstProduct = products.first {
                print("🍎 First product: \(firstProduct.productName ?? "Unknown")")
            }
            
            return products
        } catch {
            print("❌ Search failed, trying alternative endpoint...")
            // Try alternative search method
            return try await searchProductsAlternative(by: query)
        }
    }
    
    private func searchProductsAlternative(by query: String) async throws -> [OpenFoodFactsProduct] {
        // Alternative search using different endpoint
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "\(baseURL)/api/v0/search?search_terms=\(encodedQuery)&page_size=20&json=1"
        
        guard let url = URL(string: urlString) else {
            throw OpenFoodFactsError.invalidURL
        }
        
        print("🔄 Trying alternative URL: \(url)")
        
        let response = try await performRequest(url: url, responseType: OpenFoodFactsSearchResponse.self)
        let products = response.products ?? []
        print("📦 Alternative search found \(products.count) products")
        
        return products
    }
    
    func testAPI() async {
        print("🧪 Testing Open Food Facts API...")
        
        // Test with a known product
        do {
            let products = try await searchProducts(by: "apple")
            print("✅ API test successful - found \(products.count) products for 'apple'")
            
            if let firstProduct = products.first {
                print("📋 First product details:")
                print("   Name: \(firstProduct.productName ?? "Unknown")")
                print("   Brand: \(firstProduct.brands ?? "Unknown")")
                print("   Code: \(firstProduct.code ?? "Unknown")")
            }
        } catch {
            print("❌ API test failed: \(error)")
        }
        
        // Test with a known barcode
        do {
            let product = try await searchProduct(by: "3017620422003") // Nutella barcode
            print("✅ Barcode test successful")
            if let product = product {
                print("📋 Barcode product details:")
                print("   Name: \(product.productName ?? "Unknown")")
                print("   Brand: \(product.brands ?? "Unknown")")
                print("   Code: \(product.code ?? "Unknown")")
            } else {
                print("❌ No product found for barcode")
            }
        } catch {
            print("❌ Barcode test failed: \(error)")
        }
    }
    
    // MARK: - Private Methods
    
    private func buildProductURL(for barcode: String) throws -> URL {
        guard let url = URL(string: "\(baseURL)/api/v0/product/\(barcode).json") else {
            throw OpenFoodFactsError.invalidURL
        }
        return url
    }
    
    private func buildSearchURL(for query: String) throws -> URL {
        // Use the correct Open Food Facts search API
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "\(baseURL)/cgi/search.pl?search_terms=\(encodedQuery)&search_simple=1&action=process&json=1&page_size=20&page=1"
        
        guard let url = URL(string: urlString) else {
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
        
        print("📡 HTTP Status: \(httpResponse.statusCode)")
        
        switch httpResponse.statusCode {
        case 200:
            do {
                // Print raw response for debugging
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📄 Raw JSON Response (first 500 chars): \(String(jsonString.prefix(500)))")
                }
                
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                return try decoder.decode(responseType, from: data)
            } catch {
                print("❌ Decoding error: \(error)")
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
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Try to decode products as an array
        if let productsArray = try? container.decode([OpenFoodFactsProduct].self, forKey: .products) {
            self.products = productsArray
        } else {
            // If that fails, the API might return products as a dictionary with product codes as keys
            if let productsDict = try? container.decode([String: OpenFoodFactsProduct].self, forKey: .products) {
                self.products = Array(productsDict.values)
            } else {
                self.products = []
            }
        }
        
        self.count = try? container.decode(Int.self, forKey: .count)
        self.page = try? container.decode(Int.self, forKey: .page)
        self.pageSize = try? container.decode(Int.self, forKey: .pageSize)
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
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Try to decode each field, with fallbacks
        self.code = try? container.decode(String.self, forKey: .code)
        
        // Try product_name first, then generic_name as fallback
        if let productName = try? container.decode(String.self, forKey: .productName) {
            self.productName = productName
        } else {
            self.productName = try? container.decode(String.self, forKey: .genericName)
        }
        
        self.brands = try? container.decode(String.self, forKey: .brands)
        self.categories = try? container.decode(String.self, forKey: .categories)
        self.imageURL = try? container.decode(String.self, forKey: .imageURL)
        self.nutritionGrades = try? container.decode(String.self, forKey: .nutritionGrades)
        self.ingredientsText = try? container.decode(String.self, forKey: .ingredientsText)
        self.allergens = try? container.decode(String.self, forKey: .allergens)
        self.nutritionDataPer = try? container.decode(String.self, forKey: .nutritionDataPer)
        self.nutritionFacts = try? container.decode(NutritionFacts.self, forKey: .nutritionFacts)
        self.nutriments = try? container.decode(Nutriments.self, forKey: .nutriments)
        self.imageFrontURL = try? container.decode(String.self, forKey: .imageFrontURL)
        self.imageIngredientsURL = try? container.decode(String.self, forKey: .imageIngredientsURL)
        self.imageNutritionURL = try? container.decode(String.self, forKey: .imageNutritionURL)
        self.genericName = try? container.decode(String.self, forKey: .genericName)
        self.quantity = try? container.decode(String.self, forKey: .quantity)
        self.packaging = try? container.decode(String.self, forKey: .packaging)
        self.origins = try? container.decode(String.self, forKey: .origins)
        self.manufacturingPlaces = try? container.decode(String.self, forKey: .manufacturingPlaces)
        self.labels = try? container.decode(String.self, forKey: .labels)
        self.traces = try? container.decode(String.self, forKey: .traces)
        self.states = try? container.decode(String.self, forKey: .states)
        self.ecoscoreGrade = try? container.decode(String.self, forKey: .ecoscoreGrade)
        self.novaGroup = try? container.decode(String.self, forKey: .novaGroup)
        
        print("🔍 Decoded product: \(self.productName ?? "nil") with code: \(self.code ?? "nil")")
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