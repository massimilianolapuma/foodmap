import Foundation

/// Computes expiry status and an urgency score for a product.
/// Pure, deterministic logic — no I/O — to keep it fully unit-testable.
public struct CalculateExpiryStatusUseCase: Sendable {
    private let clock: Clock
    private let calendar: Calendar

    public init(clock: Clock = SystemClock(), calendar: Calendar = .current) {
        self.clock = clock
        self.calendar = calendar
    }

    /// Days remaining until the product expires. Negative means already expired.
    /// Returns `nil` when the product has no expiry date.
    public func daysRemaining(for product: Product) -> Int? {
        guard let expiry = product.expiryDate else { return nil }
        let startOfToday = calendar.startOfDay(for: clock.now())
        let startOfExpiry = calendar.startOfDay(for: expiry)
        return calendar.dateComponents([.day], from: startOfToday, to: startOfExpiry).day
    }

    public func status(for product: Product) -> ExpiryStatus {
        guard let days = daysRemaining(for: product) else { return .fresh }
        switch days {
        case ..<0: return .expired
        case 0...1: return .critical
        case 2...3: return .soon
        case 4...7: return .upcoming
        default: return .fresh
        }
    }

    /// Higher score = more urgent. Combines status with quantity weighting.
    public func priorityScore(for product: Product) -> ExpiryPriorityScore {
        let base = switch status(for: product) {
        case .expired: 100
        case .critical: 85
        case .soon: 65
        case .upcoming: 40
        case .fresh: 10
        }
        // Larger quantities are slightly more urgent (more to waste).
        let quantityBoost = min(10, Int(product.quantity.rounded()))
        return ExpiryPriorityScore(value: base + quantityBoost)
    }
}
