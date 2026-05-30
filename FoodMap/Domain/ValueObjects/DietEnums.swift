import Foundation

/// Common food allergens (EU-aligned subset). Sensitive personal data — keep on device.
public enum Allergen: String, Codable, CaseIterable, Sendable {
    case gluten
    case crustaceans
    case eggs
    case fish
    case peanuts
    case soybeans
    case milk
    case nuts
    case celery
    case mustard
    case sesame
    case sulphites
    case lupin
    case molluscs

    public var displayName: String {
        rawValue.capitalized
    }
}

/// Diet types the meal planner can respect. Sensitive personal data — keep on device.
public enum DietType: String, Codable, CaseIterable, Sendable {
    case standard
    case mediterranea
    case iposodica
    case ipocalorica
    case iperproteica
    case vegetariana
    case vegana
    case diabetica
    case glutenFree
    case lactoseFree

    public var displayName: String {
        switch self {
        case .standard: "Standard"
        case .mediterranea: "Mediterranean"
        case .iposodica: "Low-sodium"
        case .ipocalorica: "Low-calorie"
        case .iperproteica: "High-protein"
        case .vegetariana: "Vegetarian"
        case .vegana: "Vegan"
        case .diabetica: "Diabetic-friendly"
        case .glutenFree: "Gluten-free"
        case .lactoseFree: "Lactose-free"
        }
    }
}

/// Style of cuisine, used as a soft preference for meal suggestions.
public enum CuisineType: String, Codable, CaseIterable, Sendable {
    case italian
    case mediterranean
    case asian
    case mexican
    case american
    case indian
    case any
}

/// A meal slot within a day.
public enum MealType: String, Codable, CaseIterable, Sendable {
    case breakfast
    case lunch
    case dinner
    case snack

    public var displayName: String {
        rawValue.capitalized
    }
}

/// Horizon a meal plan covers.
public enum MealPlanType: String, Codable, CaseIterable, Sendable {
    case singleDay
    case threeDays
    case week
}

/// Shopping-list grouping for an efficient store route.
public enum GroceryCategory: String, Codable, CaseIterable, Sendable {
    case produce
    case dairy
    case meatFish
    case bakery
    case pantry
    case frozen
    case beverages
    case other

    public var displayName: String {
        switch self {
        case .produce: "Produce"
        case .dairy: "Dairy"
        case .meatFish: "Meat & Fish"
        case .bakery: "Bakery"
        case .pantry: "Pantry"
        case .frozen: "Frozen"
        case .beverages: "Beverages"
        case .other: "Other"
        }
    }
}
