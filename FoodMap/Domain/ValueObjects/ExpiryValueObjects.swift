import Foundation

/// Expiry urgency derived from days remaining until the expiry date.
public enum ExpiryStatus: String, Codable, CaseIterable, Sendable {
    case expired
    case critical // 0–1 days
    case soon // 2–3 days
    case upcoming // 4–7 days
    case fresh // > 7 days

    public var displayName: String {
        switch self {
        case .expired: "Expired"
        case .critical: "Use today"
        case .soon: "Use soon"
        case .upcoming: "This week"
        case .fresh: "Fresh"
        }
    }

    /// VoiceOver-friendly description of the expiry status, used as a text
    /// accessibility label for color-only indicators (color alone is not
    /// sufficient for colorblind users). Pure presentation-agnostic string.
    public var accessibilityDescription: String {
        switch self {
        case .expired: "Expiry: expired"
        case .critical: "Expiry: critical, use today"
        case .soon: "Expiry: use soon"
        case .upcoming: "Expiry: this week"
        case .fresh: "Expiry: fresh"
        }
    }

    /// Lower is more urgent — used for sorting prioritized lists.
    public var sortRank: Int {
        switch self {
        case .expired: 0
        case .critical: 1
        case .soon: 2
        case .upcoming: 3
        case .fresh: 4
        }
    }
}

/// A normalized 0–100 score expressing how urgently a product should be consumed.
/// Higher means more urgent. Combines expiry status with quantity.
public struct ExpiryPriorityScore: Codable, Hashable, Sendable, Comparable {
    public let value: Int

    public init(value: Int) {
        self.value = min(100, max(0, value))
    }

    public static func < (lhs: ExpiryPriorityScore, rhs: ExpiryPriorityScore) -> Bool {
        lhs.value < rhs.value
    }
}
