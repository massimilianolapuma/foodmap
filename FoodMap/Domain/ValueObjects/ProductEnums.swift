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
        case .fruitsVegetables: "Fruits & Vegetables"
        case .dairy: "Dairy"
        case .meatFish: "Meat & Fish"
        case .bakery: "Bakery"
        case .pantryStaples: "Pantry Staples"
        case .frozen: "Frozen"
        case .beverages: "Beverages"
        case .snacks: "Snacks"
        case .condiments: "Condiments"
        case .other: "Other"
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
        case .fridge: "Fridge"
        case .freezer: "Freezer"
        case .pantry: "Pantry"
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
        case .piece: "pc"
        case .gram: "g"
        case .kilogram: "kg"
        case .milliliter: "ml"
        case .liter: "l"
        case .pack: "pack"
        }
    }
}

/// Origin of a product's data.
public enum ProductSource: String, Codable, CaseIterable, Sendable {
    case openFoodFacts
    case manual
    case cache
}
