import Foundation

/// Abstraction over HTTP so the lookup service can be tested with a mock.
public protocol HTTPClient: Sendable {
    func data(from url: URL) async throws -> (Data, URLResponse)
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

public extension HTTPClient {
    /// Default fallback for clients that only model GET. Real network clients
    /// (URLSession) provide their own implementation that sends the request body.
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        guard let url = request.url else {
            throw FoodMapError.network(reason: "Request is missing a URL.")
        }
        return try await data(from: url)
    }
}

extension URLSession: HTTPClient {
    public func data(from url: URL) async throws -> (Data, URLResponse) {
        try await data(from: url, delegate: nil)
    }

    public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await data(for: request, delegate: nil)
    }
}

/// Looks up products from the Open Food Facts public API.
/// HTTPS only; validates and bounds responses; treats payloads as untrusted.
public final class OpenFoodFactsService: ProductLookupService {
    private let httpClient: HTTPClient
    private let baseURL: URL
    private let maxResponseBytes = 2_000_000

    private static let defaultBaseURL: URL = {
        guard let url = URL(string: "https://world.openfoodfacts.org") else {
            preconditionFailure("Invalid Open Food Facts base URL")
        }
        return url
    }()

    public init(
        httpClient: HTTPClient = URLSession.shared,
        baseURL: URL? = nil
    ) {
        self.httpClient = httpClient
        self.baseURL = baseURL ?? Self.defaultBaseURL
    }

    public func fetchProduct(by barcode: String) async throws -> ProductLookupResult {
        let sanitized = barcode.filter(\.isNumber)
        guard !sanitized.isEmpty, sanitized.count <= 14 else {
            throw FoodMapError.invalidInput(reason: "Invalid barcode.")
        }

        let fields = "product_name,product_name_it,brands,categories_tags,image_url,image_front_url,allergens_tags,nutriments"
        guard let url = URL(string: "/api/v2/product/\(sanitized).json?fields=\(fields)", relativeTo: baseURL) else {
            throw FoodMapError.network(reason: "Could not build request URL.")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await httpClient.data(from: url)
        } catch {
            throw FoodMapError.network(reason: error.localizedDescription)
        }

        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            if http.statusCode == 404 { throw FoodMapError.productNotFound(barcode: sanitized) }
            throw FoodMapError.network(reason: "HTTP \(http.statusCode)")
        }

        guard data.count <= maxResponseBytes else {
            throw FoodMapError.decoding(reason: "Response too large.")
        }

        do {
            let dto = try JSONDecoder().decode(OpenFoodFactsResponseDTO.self, from: data)
            return try OpenFoodFactsMapper.map(dto, barcode: sanitized)
        } catch let error as FoodMapError {
            throw error
        } catch {
            throw FoodMapError.decoding(reason: error.localizedDescription)
        }
    }
}
