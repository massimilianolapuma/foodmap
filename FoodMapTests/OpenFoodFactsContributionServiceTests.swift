import XCTest
@testable import FoodMap

final class OpenFoodFactsContributionServiceTests: XCTestCase {
    private actor RequestRecorder {
        private(set) var lastRequest: URLRequest?
        func store(_ request: URLRequest) {
            lastRequest = request
        }
    }

    private struct StubHTTPClient: HTTPClient {
        let result: Result<(Data, URLResponse), Error>
        let recorder: RequestRecorder

        func data(from _: URL) async throws -> (Data, URLResponse) {
            try result.get()
        }

        func data(for request: URLRequest) async throws -> (Data, URLResponse) {
            await recorder.store(request)
            return try result.get()
        }
    }

    private let baseURL = URL(string: "https://world.openfoodfacts.net")!
    private let credentials = OpenFoodFactsCredentials(username: "tester", password: "secret")

    private func response(_ code: Int, url: URL) -> URLResponse {
        HTTPURLResponse(url: url, statusCode: code, httpVersion: nil, headerFields: nil)!
    }

    private func bodyString(_ request: URLRequest?) -> String {
        guard let body = request?.httpBody else { return "" }
        return String(data: body, encoding: .utf8) ?? ""
    }

    func testContributeSendsPostWithProductFields() async throws {
        let recorder = RequestRecorder()
        let json = #"{"status":1,"status_verbose":"fields saved"}"#.data(using: .utf8)!
        let client = StubHTTPClient(result: .success((json, response(200, url: baseURL))), recorder: recorder)
        let service = OpenFoodFactsContributionService(httpClient: client, baseURL: baseURL)

        let contribution = ProductContribution(
            barcode: "5038862014229",
            name: "Esselunga Succo",
            brand: "Esselunga",
            categories: "beverages",
            quantity: "1 L"
        )
        try await service.contribute(contribution, using: credentials)

        let request = await recorder.lastRequest
        XCTAssertEqual(request?.httpMethod, "POST")
        XCTAssertEqual(request?.url?.absoluteString, "https://world.openfoodfacts.net/cgi/product_jqm2.pl")
        XCTAssertEqual(request?.value(forHTTPHeaderField: "Content-Type"), "application/x-www-form-urlencoded")
        XCTAssertNotNil(request?.value(forHTTPHeaderField: "User-Agent"))

        let body = bodyString(request)
        XCTAssertTrue(body.contains("code=5038862014229"))
        XCTAssertTrue(body.contains("user_id=tester"))
        XCTAssertTrue(body.contains("password=secret"))
        XCTAssertTrue(body.contains("product_name=Esselunga%20Succo"))
        XCTAssertTrue(body.contains("brands=Esselunga"))
        XCTAssertTrue(body.contains("categories=beverages"))
        XCTAssertTrue(body.contains("quantity=1%20L"))
    }

    func testContributeOmitsEmptyOptionalFields() async throws {
        let recorder = RequestRecorder()
        let json = #"{"status":1}"#.data(using: .utf8)!
        let client = StubHTTPClient(result: .success((json, response(200, url: baseURL))), recorder: recorder)
        let service = OpenFoodFactsContributionService(httpClient: client, baseURL: baseURL)

        let contribution = ProductContribution(barcode: "123456789", name: "Plain")
        try await service.contribute(contribution, using: credentials)

        let body = await bodyString(recorder.lastRequest)
        XCTAssertFalse(body.contains("brands="))
        XCTAssertFalse(body.contains("categories="))
        XCTAssertFalse(body.contains("quantity="))
    }

    func testContributeThrowsWhenStatusNotOne() async {
        let recorder = RequestRecorder()
        let json = #"{"status":0,"status_verbose":"missing fields"}"#.data(using: .utf8)!
        let client = StubHTTPClient(result: .success((json, response(200, url: baseURL))), recorder: recorder)
        let service = OpenFoodFactsContributionService(httpClient: client, baseURL: baseURL)

        do {
            try await service.contribute(ProductContribution(barcode: "123", name: "X"), using: credentials)
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(error as? FoodMapError, .network(reason: "missing fields"))
        }
    }

    func testContributeRejectsInvalidBarcode() async {
        let recorder = RequestRecorder()
        let client = StubHTTPClient(result: .success((Data(), response(200, url: baseURL))), recorder: recorder)
        let service = OpenFoodFactsContributionService(httpClient: client, baseURL: baseURL)

        do {
            try await service.contribute(ProductContribution(barcode: "abc", name: "X"), using: credentials)
            XCTFail("Expected error")
        } catch {
            guard case FoodMapError.invalidInput = error as? FoodMapError ?? .ocrFailed else {
                return XCTFail("Expected invalidInput, got \(error)")
            }
        }
    }

    func testContributeRejectsEmptyName() async {
        let recorder = RequestRecorder()
        let client = StubHTTPClient(result: .success((Data(), response(200, url: baseURL))), recorder: recorder)
        let service = OpenFoodFactsContributionService(httpClient: client, baseURL: baseURL)

        do {
            try await service.contribute(ProductContribution(barcode: "123", name: "   "), using: credentials)
            XCTFail("Expected error")
        } catch {
            guard case FoodMapError.invalidInput = error as? FoodMapError ?? .ocrFailed else {
                return XCTFail("Expected invalidInput, got \(error)")
            }
        }
    }

    func testContributeThrowsOnHTTPError() async {
        let recorder = RequestRecorder()
        let client = StubHTTPClient(result: .success((Data(), response(500, url: baseURL))), recorder: recorder)
        let service = OpenFoodFactsContributionService(httpClient: client, baseURL: baseURL)

        do {
            try await service.contribute(ProductContribution(barcode: "123", name: "X"), using: credentials)
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(error as? FoodMapError, .network(reason: "HTTP 500"))
        }
    }
}

final class ContributeProductUseCaseTests: XCTestCase {
    private final class SpyContributionService: ProductContributionService, @unchecked Sendable {
        private(set) var didCall = false
        func contribute(_: ProductContribution, using _: OpenFoodFactsCredentials) async throws {
            didCall = true
        }
    }

    func testThrowsWhenCredentialsIncomplete() async {
        let spy = SpyContributionService()
        let useCase = ContributeProductToOpenFoodFactsUseCase(service: spy)
        do {
            try await useCase(
                ProductContribution(barcode: "123", name: "X"),
                using: OpenFoodFactsCredentials(username: "", password: "")
            )
            XCTFail("Expected error")
        } catch {
            guard case FoodMapError.invalidInput = error as? FoodMapError ?? .ocrFailed else {
                return XCTFail("Expected invalidInput, got \(error)")
            }
        }
        XCTAssertFalse(spy.didCall)
    }

    func testForwardsToServiceWhenComplete() async throws {
        let spy = SpyContributionService()
        let useCase = ContributeProductToOpenFoodFactsUseCase(service: spy)
        try await useCase(
            ProductContribution(barcode: "123", name: "X"),
            using: OpenFoodFactsCredentials(username: "u", password: "p")
        )
        XCTAssertTrue(spy.didCall)
    }
}
