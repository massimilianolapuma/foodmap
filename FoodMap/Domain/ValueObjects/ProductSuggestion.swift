import Foundation

/// A product the app proposes the user might want to buy, with a typed reason.
///
/// Pure value type produced by `SuggestProductsUseCase`. Carries no persistence
/// or UI concerns; the Presentation layer renders the reason and offers an
/// "add" action.
public struct ProductSuggestion: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let name: String
    public let reason: SuggestionReason
    public let category: ProductCategory

    public init(
        id: UUID = UUID(),
        name: String,
        reason: SuggestionReason,
        category: ProductCategory = .other
    ) {
        self.id = id
        self.name = name
        self.reason = reason
        self.category = category
    }
}

/// Why a product is suggested. Ordered by `priority` (lower = stronger signal).
public enum SuggestionReason: String, Codable, CaseIterable, Sendable {
    /// Required by the current meal plan but not yet in the pantry.
    case missingForMealPlan
    /// Bought repeatedly in the past but currently absent from the pantry.
    case recurring
    /// A category the user usually keeps stocked is currently empty.
    case lowCategory
    /// A common household staple that is not in the pantry.
    case staple

    /// Ordering weight; lower values rank higher in the suggestion list.
    public var priority: Int {
        switch self {
        case .missingForMealPlan: 0
        case .recurring: 1
        case .lowCategory: 2
        case .staple: 3
        }
    }
}

/// A household staple used as a fallback suggestion source. Configurable so the
/// user can curate their own list; a sensible default is provided.
public struct StapleProduct: Equatable, Sendable {
    public let name: String
    public let category: ProductCategory

    public init(name: String, category: ProductCategory = .pantryStaples) {
        self.name = name
        self.category = category
    }
}
