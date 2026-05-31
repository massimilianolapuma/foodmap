import XCTest
@testable import FoodMap

final class RemoteImageLoaderTests: XCTestCase {
    func testSecureURLAcceptsHTTPS() {
        let url = RemoteImageLoader.secureURL(from: "https://images.openfoodfacts.org/front.jpg")
        XCTAssertEqual(url?.scheme, "https")
        XCTAssertEqual(url?.host, "images.openfoodfacts.org")
    }

    func testSecureURLRejectsHTTP() {
        XCTAssertNil(RemoteImageLoader.secureURL(from: "http://images.openfoodfacts.org/front.jpg"))
    }

    func testSecureURLRejectsNonAbsoluteOrEmpty() {
        XCTAssertNil(RemoteImageLoader.secureURL(from: ""))
        XCTAssertNil(RemoteImageLoader.secureURL(from: "not a url"))
        XCTAssertNil(RemoteImageLoader.secureURL(from: "ftp://example.com/x.jpg"))
    }
}
