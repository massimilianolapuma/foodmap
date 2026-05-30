import Foundation

/// Reconciles scheduled expiry notifications with the current inventory.
///
/// When alerts are enabled, schedules a notification for every product whose
/// fire date (`expiryDate − leadDays`) is still in the future and cancels any
/// stale alert for products that no longer qualify (no expiry, or lead time
/// already passed). When alerts are disabled, cancels everything.
public struct SyncExpiryAlertsUseCase: Sendable {
    private let scheduler: NotificationScheduler
    private let products: ProductRepository
    private let clock: Clock
    private let calendar: Calendar

    public init(
        scheduler: NotificationScheduler,
        products: ProductRepository,
        clock: Clock = SystemClock(),
        calendar: Calendar = .current
    ) {
        self.scheduler = scheduler
        self.products = products
        self.clock = clock
        self.calendar = calendar
    }

    public func callAsFunction(leadDays: Int, alertsEnabled: Bool) async throws {
        guard alertsEnabled else {
            await scheduler.cancelAll()
            return
        }

        let now = clock.now()
        let all = try await products.fetchAll()
        for product in all {
            if let fireDate = fireDate(for: product, leadDays: leadDays), fireDate > now {
                try await scheduler.scheduleExpiryAlert(for: product, leadDays: leadDays)
            } else {
                await scheduler.cancelAlert(for: product.id)
            }
        }
    }

    private func fireDate(for product: Product, leadDays: Int) -> Date? {
        guard let expiry = product.expiryDate else { return nil }
        return calendar.date(byAdding: .day, value: -leadDays, to: expiry)
    }
}
