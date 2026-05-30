import XCTest
@testable import FoodMap

@MainActor
final class ProfileViewModelTests: XCTestCase {
    private func makeModel(
        scheduler: FakeNotificationScheduler,
        repository: ProductRepository
    ) -> ProfileViewModel {
        let sync = SyncExpiryAlertsUseCase(
            scheduler: scheduler,
            products: repository,
            clock: FixedClock.make(year: 2026, month: 5, day: 30),
            calendar: .utcGregorian
        )
        return ProfileViewModel(scheduler: scheduler, syncAlerts: sync)
    }

    func testEnablingAlertsRequestsAuthorizationAndSyncs() async throws {
        let repo = InMemoryProductRepository()
        let product = Product(name: "Milk", expiryDate: .make(year: 2026, month: 6, day: 10))
        try await repo.add(product)
        let scheduler = FakeNotificationScheduler()
        scheduler.authorizationGranted = true
        let model = makeModel(scheduler: scheduler, repository: repo)

        let applied = await model.setAlerts(enabled: true, leadDays: 3)

        XCTAssertTrue(applied)
        XCTAssertFalse(model.permissionDenied)
        XCTAssertEqual(scheduler.requestAuthorizationCount, 1)
        XCTAssertEqual(scheduler.scheduledIDs, [product.id])
    }

    func testEnablingAlertsWhenDeniedRevertsAndCancels() async throws {
        let repo = InMemoryProductRepository()
        try await repo.add(Product(name: "Milk", expiryDate: .make(year: 2026, month: 6, day: 10)))
        let scheduler = FakeNotificationScheduler()
        scheduler.authorizationGranted = false
        let model = makeModel(scheduler: scheduler, repository: repo)

        let applied = await model.setAlerts(enabled: true, leadDays: 3)

        XCTAssertFalse(applied)
        XCTAssertTrue(model.permissionDenied)
        XCTAssertEqual(scheduler.cancelAllCount, 1)
        XCTAssertTrue(scheduler.scheduled.isEmpty)
    }

    func testDisablingAlertsCancelsAll() async {
        let repo = InMemoryProductRepository()
        let scheduler = FakeNotificationScheduler()
        let model = makeModel(scheduler: scheduler, repository: repo)

        let applied = await model.setAlerts(enabled: false, leadDays: 3)

        XCTAssertFalse(applied)
        XCTAssertEqual(scheduler.requestAuthorizationCount, 0)
        XCTAssertEqual(scheduler.cancelAllCount, 1)
    }
}
