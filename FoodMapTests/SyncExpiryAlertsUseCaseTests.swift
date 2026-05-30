import XCTest
@testable import FoodMap

final class SyncExpiryAlertsUseCaseTests: XCTestCase {
    private let clock = FixedClock.make(year: 2026, month: 5, day: 30)

    private func makeUseCase(
        scheduler: FakeNotificationScheduler,
        repository: ProductRepository
    ) -> SyncExpiryAlertsUseCase {
        SyncExpiryAlertsUseCase(
            scheduler: scheduler,
            products: repository,
            clock: clock,
            calendar: .utcGregorian
        )
    }

    func testEnabledSchedulesProductWithFutureFireDate() async throws {
        let repo = InMemoryProductRepository()
        let product = Product(name: "Milk", expiryDate: .make(year: 2026, month: 6, day: 10))
        try await repo.add(product)
        let scheduler = FakeNotificationScheduler()
        let sut = makeUseCase(scheduler: scheduler, repository: repo)

        try await sut(leadDays: 3, alertsEnabled: true)

        XCTAssertEqual(scheduler.scheduledIDs, [product.id])
        XCTAssertEqual(scheduler.scheduled.first?.leadDays, 3)
        XCTAssertEqual(scheduler.cancelAllCount, 0)
    }

    func testDisabledCancelsAllAndSchedulesNothing() async throws {
        let repo = InMemoryProductRepository()
        try await repo.add(Product(name: "Milk", expiryDate: .make(year: 2026, month: 6, day: 10)))
        let scheduler = FakeNotificationScheduler()
        let sut = makeUseCase(scheduler: scheduler, repository: repo)

        try await sut(leadDays: 3, alertsEnabled: false)

        XCTAssertEqual(scheduler.cancelAllCount, 1)
        XCTAssertTrue(scheduler.scheduled.isEmpty)
    }

    func testProductWithoutExpiryIsNotScheduled() async throws {
        let repo = InMemoryProductRepository()
        let product = Product(name: "Salt", expiryDate: nil)
        try await repo.add(product)
        let scheduler = FakeNotificationScheduler()
        let sut = makeUseCase(scheduler: scheduler, repository: repo)

        try await sut(leadDays: 3, alertsEnabled: true)

        XCTAssertTrue(scheduler.scheduled.isEmpty)
        XCTAssertEqual(scheduler.cancelled, [product.id])
    }

    func testProductPastLeadTimeIsNotScheduled() async throws {
        let repo = InMemoryProductRepository()
        // Expiry in 1 day, lead time 3 days -> fire date already in the past.
        let product = Product(name: "Yogurt", expiryDate: .make(year: 2026, month: 5, day: 31))
        try await repo.add(product)
        let scheduler = FakeNotificationScheduler()
        let sut = makeUseCase(scheduler: scheduler, repository: repo)

        try await sut(leadDays: 3, alertsEnabled: true)

        XCTAssertTrue(scheduler.scheduled.isEmpty)
        XCTAssertEqual(scheduler.cancelled, [product.id])
    }

    func testLeadDaysChangeReschedulesWithNewLeadDays() async throws {
        let repo = InMemoryProductRepository()
        let product = Product(name: "Cheese", expiryDate: .make(year: 2026, month: 6, day: 10))
        try await repo.add(product)
        let scheduler = FakeNotificationScheduler()
        let sut = makeUseCase(scheduler: scheduler, repository: repo)

        try await sut(leadDays: 3, alertsEnabled: true)
        try await sut(leadDays: 5, alertsEnabled: true)

        XCTAssertEqual(scheduler.scheduled.map(\.leadDays), [3, 5])
        XCTAssertEqual(scheduler.scheduled.map(\.id), [product.id, product.id])
    }
}
