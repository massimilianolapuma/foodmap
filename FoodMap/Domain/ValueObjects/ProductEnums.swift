import Foundation

/// High-level grouping for a product, used for filtering and meal planning.
public enum ProductCategory: String, Codable, CaseIterable, Sendable {
    case fruitsVegetables
    case dairy
    case meatFish
    case bakery
    case pantryStaples
    case frozen
    case beverages
    case snacks
    case condiments
    case other

    public var displayName: String {
        switch self {
        case .fruitsVegetables: String(localized: "Fruits & Vegetables")
        case .dairy: String(localized: "Dairy")
        case .meatFish: String(localized: "Meat & Fish")
        case .bakery: String(localized: "Bakery")
        case .pantryStaples: String(localized: "Pantry Staples")
        case .frozen: String(localized: "Frozen")
        case .beverages: String(localized: "Beverages")
        case .snacks: String(localized: "Snacks")
        case .condiments: String(localized: "Condiments")
        case .other: String(localized: "Other")
        }
    }

    /// SF Symbol used as an on-device representative icon when no product photo is
    /// available. Generated locally — never a cloud image — to preserve privacy.
    public var iconName: String {
        switch self {
        case .fruitsVegetables: "carrot.fill"
        case .dairy: "drop.fill"
        case .meatFish: "fish.fill"
        case .bakery: "birthday.cake.fill"
        case .pantryStaples: "shippingbox.fill"
        case .frozen: "snowflake"
        case .beverages: "cup.and.saucer.fill"
        case .snacks: "popcorn.fill"
        case .condiments: "fork.knife"
        case .other: "bag.fill"
        }
    }
}

/// Where a product is physically stored. Affects default expiry windows.
public enum StorageLocation: String, Codable, CaseIterable, Sendable {
    case fridge
    case freezer
    case pantry

    public var displayName: String {
        switch self {
        case .fridge: String(localized: "Fridge")
        case .freezer: String(localized: "Freezer")
        case .pantry: String(localized: "Pantry")
        }
    }
}

/// Unit of measurement for quantities.
public enum MeasurementUnit: String, Codable, CaseIterable, Sendable {
    case piece
    case gram
    case kilogram
    case milliliter
    case liter
    case pack

    public var abbreviation: String {
        switch self {
        case .piece: String(localized: "unit.pc")
        case .gram: String(localized: "unit.g")
        case .kilogram: String(localized: "unit.kg")
        case .milliliter: String(localized: "unit.ml")
        case .liter: String(localized: "unit.l")
        case .pack: String(localized: "unit.pack")
        }
    }
}

/// Origin of a product's data.
public enum ProductSource: String, Codable, CaseIterable, Sendable {
    case openFoodFacts
    case manual
    case cache
}
