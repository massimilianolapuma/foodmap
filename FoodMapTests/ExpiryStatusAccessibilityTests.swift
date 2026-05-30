import XCTest
@testable import FoodMap

final class ExpiryStatusAccessibilityTests: XCTestCase {
    func testAccessibilityDescriptionIsNonEmptyAndStatusSpecific() {
        let descriptions = ExpiryStatus.allCases.map(\.accessibilityDescription)
        XCTAssertTrue(descriptions.allSatisfy { !$0.isEmpty })
        XCTAssertEqual(Set(descriptions).count, ExpiryStatus.allCases.count, "Each status must have a distinct label")
    }

    func testAccessibilityDescriptionStrings() {
        XCTAssertEqual(ExpiryStatus.expired.accessibilityDescription, "Expiry: expired")
        XCTAssertEqual(ExpiryStatus.critical.accessibilityDescription, "Expiry: critical, use today")
        XCTAssertEqual(ExpiryStatus.soon.accessibilityDescription, "Expiry: use soon")
        XCTAssertEqual(ExpiryStatus.upcoming.accessibilityDescription, "Expiry: this week")
        XCTAssertEqual(ExpiryStatus.fresh.accessibilityDescription, "Expiry: fresh")
    }
}
