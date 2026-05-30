import XCTest
@testable import FoodMap

final class CalculateExpiryStatusUseCaseTests: XCTestCase {
    private func makeUseCase(today: Date) -> CalculateExpiryStatusUseCase {
        CalculateExpiryStatusUseCase(clock: FixedClock(fixed: today), calendar: .utcGregorian)
    }

    func testExpiredWhenPastDate() {
        let useCase = makeUseCase(today: .make(year: 2026, month: 6, day: 12))
        let product = Product(name: "Milk", expiryDate: .make(year: 2026, month: 6, day: 10))
        XCTAssertEqual(useCase.status(for: product), .expired)
        XCTAssertEqual(useCase.daysRemaining(for: product), -2)
    }

    func testCriticalWithinOneDay() {
        let useCase = makeUseCase(today: .make(year: 2026, month: 6, day: 12))
        let product = Product(name: "Yogurt", expiryDate: .make(year: 2026, month: 6, day: 13))
        XCTAssertEqual(useCase.status(for: product), .critical)
    }

    func testFreshWhenFarAway() {
        let useCase = makeUseCase(today: .make(year: 2026, month: 6, day: 12))
        let product = Product(name: "Pasta", expiryDate: .make(year: 2026, month: 12, day: 1))
        XCTAssertEqual(useCase.status(for: product), .fresh)
    }

    func testNoExpiryIsFresh() {
        let useCase = makeUseCase(today: .make(year: 2026, month: 6, day: 12))
        let product = Product(name: "Salt")
        XCTAssertEqual(useCase.status(for: product), .fresh)
        XCTAssertNil(useCase.daysRemaining(for: product))
    }

    func testExpiredScoresHigherThanFresh() {
        let useCase = makeUseCase(today: .make(year: 2026, month: 6, day: 12))
        let expired = Product(name: "A", expiryDate: .make(year: 2026, month: 6, day: 1))
        let fresh = Product(name: "B", expiryDate: .make(year: 2026, month: 12, day: 1))
        XCTAssertGreaterThan(useCase.priorityScore(for: expired), useCase.priorityScore(for: fresh))
    }
}
