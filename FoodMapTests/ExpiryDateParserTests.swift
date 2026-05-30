import XCTest
@testable import FoodMap

final class ExpiryDateParserTests: XCTestCase {
    private let parser = ExpiryDateParser()

    func testParsesISODate() {
        let dates = parser.parseDates(from: "Best before 2026-06-12")
        XCTAssertTrue(dates.contains(.make(year: 2026, month: 6, day: 12)))
    }

    func testParsesSlashShortYear() {
        let dates = parser.parseDates(from: "Scad. 12/06/26")
        XCTAssertTrue(dates.contains(.make(year: 2026, month: 6, day: 12)))
    }

    func testParsesDashLongYear() {
        let dates = parser.parseDates(from: "12-06-2026")
        XCTAssertTrue(dates.contains(.make(year: 2026, month: 6, day: 12)))
    }

    func testParsesItalianMonthAbbreviation() {
        let dates = parser.parseDates(from: "12 giu 2026")
        XCTAssertTrue(dates.contains(.make(year: 2026, month: 6, day: 12)))
    }

    func testReturnsEmptyForNoDate() {
        XCTAssertTrue(parser.parseDates(from: "no date here").isEmpty)
    }
}
