import Foundation

/// Estimates a use-by date for perishables that ship without an explicit expiry
/// date (e.g. loose fruit, vegetables, fresh meat or fish). The estimate is a
/// conservative shelf life measured from a reference date — typically the
/// packaging date when known, otherwise the date the item was added.
///
/// Estimates are advisory only: they help surface items before they spoil and
/// are clearly flagged as estimated (`Product.expiryIsEstimated`). No medical
/// or food-safety claims are made.
public struct EstimateExpiryDateUseCase: Sendable {
    private let calendar: Calendar

    public init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    /// Returns an estimated expiry date, or `nil` when the category is not a
    /// perishable we can reasonably estimate (e.g. shelf-stable staples).
    public func callAsFunction(
        category: ProductCategory,
        storageLocation: StorageLocation,
        from referenceDate: Date = .now
    ) -> Date? {
        guard let days = Self.shelfLifeDays(category: category, storageLocation: storageLocation) else {
            return nil
        }
        return calendar.date(byAdding: .day, value: days, to: referenceDate)
    }

    /// Conservative shelf life in days by category and storage location.
    /// Returns `nil` for shelf-stable or non-perishable categories.
    static func shelfLifeDays(category: ProductCategory, storageLocation: StorageLocation) -> Int? {
        guard let window = shelfLifeWindow(for: category) else { return nil }
        switch storageLocation {
        case .fridge: return window.fridge
        case .pantry: return window.pantry
        case .freezer: return window.freezer
        }
    }

    /// Per-location shelf life (in days) for a perishable category.
    private struct ShelfLife {
        let fridge: Int
        let pantry: Int
        let freezer: Int
    }

    /// Shelf-life window for a perishable category, or `nil` when the category
    /// is shelf-stable and should not be estimated.
    private static func shelfLifeWindow(for category: ProductCategory) -> ShelfLife? {
        switch category {
        case .fruitsVegetables: ShelfLife(fridge: 7, pantry: 5, freezer: 240)
        case .meatFish: ShelfLife(fridge: 2, pantry: 1, freezer: 180)
        case .dairy: ShelfLife(fridge: 10, pantry: 1, freezer: 90)
        case .bakery: ShelfLife(fridge: 7, pantry: 4, freezer: 90)
        case .pantryStaples, .frozen, .beverages, .snacks, .condiments, .other: nil
        }
    }
}
