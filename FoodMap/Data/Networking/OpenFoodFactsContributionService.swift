import Foundation

/// Writes user-contributed products to Open Food Facts via its public write API.
///
/// HTTPS only; sends only public product metadata using the user's own account.
/// Never transmits the user's sensitive data (allergies, diet, nutrition targets).
public final class OpenFoodFactsContributionService: ProductContributionService {
    private let httpClient: HTTPClient
    private let baseURL: URL
    private let userAgent: String
    private let maxResponseBytes = 1_000_000

    private static let defaultBaseURL: URL = {
        guard let url = URL(string: "https://world.openfoodfacts.org") else {
            preconditionFailure("Invalid Open Food Facts base URL")
        }
        return url
    }()

    public init(
        httpClient: HTTPClient = URLSession.shared,
        baseURL: URL? = nil,
        userAgent: String = "FoodMap-iOS - https://github.com/massimilianolapuma/foodmap"
    ) {
        self.httpClient = httpClient
        self.baseURL = baseURL ?? Self.defaultBaseURL
        self.userAgent = userAgent
    }

    public func contribute(
        _ contribution: ProductContribution,
        using credentials: OpenFoodFactsCredentials
    ) async throws {
        let sanitizedBarcode = contribution.barcode.filter(\.isNumber)
        guard !sanitizedBarcode.isEmpty, sanitizedBarcode.count <= 14 else {
            throw FoodMapError.invalidInput(reason: "Invalid barcode.")
        }
        let trimmedName = contribution.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw FoodMapError.invalidInput(reason: "Product name is required.")
        }
        guard credentials.isComplete else {
            throw FoodMapError.invalidInput(reason: "Open Food Facts credentials are required.")
        }

        guard let url = URL(string: "/cgi/product_jqm2.pl", relativeTo: baseURL) else {
            throw FoodMapError.network(reason: "Could not build request URL.")
        }

        let fields = Self.fields(
            barcode: sanitizedBarcode,
            name: trimmedName,
            contribution: contribution,
            credentials: credentials
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.httpBody = Self.formEncoded(fields).data(using: .utf8)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await httpClient.data(for: request)
        } catch {
            throw FoodMapError.network(reason: error.localizedDescription)
        }

        try Self.validate(response: response, data: data, maxResponseBytes: maxResponseBytes)
    }

    /// Builds the form fields, omitting empty optional values.
    private static func fields(
        barcode: String,
        name: String,
        contribution: ProductContribution,
        credentials: OpenFoodFactsCredentials
    ) -> [String: String] {
        var fields: [String: String] = [
            "code": barcode,
            "user_id": credentials.username,
            "password": credentials.password,
            "product_name": name
        ]
        addIfPresent(contribution.brand, as: "brands", to: &fields)
        addIfPresent(contribution.categories, as: "categories", to: &fields)
        addIfPresent(contribution.quantity, as: "quantity", to: &fields)
        return fields
    }

    private static func addIfPresent(_ value: String?, as key: String, to fields: inout [String: String]) {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return
        }
        fields[key] = trimmed
    }

    /// Validates the HTTP response and decodes the write-API status.
    private static func validate(response: URLResponse, data: Data, maxResponseBytes: Int) throws {
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw FoodMapError.network(reason: "HTTP \(http.statusCode)")
        }
        guard data.count <= maxResponseBytes else {
            throw FoodMapError.decoding(reason: "Response too large.")
        }

        let result: ContributionResultDTO
        do {
            result = try JSONDecoder().decode(ContributionResultDTO.self, from: data)
        } catch {
            throw FoodMapError.decoding(reason: error.localizedDescription)
        }
        guard result.status == 1 else {
            throw FoodMapError.network(reason: result.statusVerbose ?? "Open Food Facts rejected the contribution.")
        }
    }

    /// Percent-encodes form fields as `application/x-www-form-urlencoded`.
    private static func formEncoded(_ fields: [String: String]) -> String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return fields
            .map { key, value in
                let encodedKey = key.addingPercentEncoding(withAllowedCharacters: allowed) ?? key
                let encodedValue = value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
                return "\(encodedKey)=\(encodedValue)"
            }
            .joined(separator: "&")
    }
}

/// Minimal Open Food Facts write-API response.
private struct ContributionResultDTO: Decodable {
    let status: Int
    let statusVerbose: String?

    enum CodingKeys: String, CodingKey {
        case status
        case statusVerbose = "status_verbose"
    }
}
