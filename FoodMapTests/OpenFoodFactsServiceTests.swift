import XCTest
@testable import FoodMap

final class OpenFoodFactsServiceTests: XCTestCase {
    private struct StubHTTPClient: HTTPClient {
        let result: Result<(Data, URLResponse), Error>
        func data(from _: URL) async throws -> (Data, URLResponse) {
            try result.get()
        }
    }

    private func response(_ code: Int, url: URL = URL(string: "https://world.openfoodfacts.org")!) -> URLResponse {
        HTTPURLResponse(url: url, statusCode: code, httpVersion: nil, headerFields: nil)!
    }

    func testFetchesAndMapsProduct() async throws {
        let json = """
        {"status":1,"code":"123","product":{"product_name":"Milk","allergens_tags":["en:milk"]}}
        """.data(using: .utf8)!
        let client = StubHTTPClient(result: .success((json, response(200))))
        let service = OpenFoodFactsService(httpClient: client)

        let result = try await service.fetchProduct(by: "123")
        XCTAssertEqual(result.name, "Milk")
        XCTAssertEqual(result.allergens, [.milk])
    }

    func testNotFoundOn404() async {
        let client = StubHTTPClient(result: .success((Data(), response(404))))
        let service = OpenFoodFactsService(httpClient: client)
        do {
            _ = try await service.fetchProduct(by: "404")
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(error as? FoodMapError, .productNotFound(barcode: "404"))
        }
    }

    func testRejectsInvalidBarcode() async {
        let client = StubHTTPClient(result: .success((Data(), response(200))))
        let service = OpenFoodFactsService(httpClient: client)
        do {
            _ = try await service.fetchProduct(by: "abc")
            XCTFail("Expected error")
        } catch {
            guard case FoodMapError.invalidInput = error as? FoodMapError ?? .ocrFailed else {
                return XCTFail("Expected invalidInput, got \(error)")
            }
        }
    }
}
