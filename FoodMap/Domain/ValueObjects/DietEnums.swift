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
        switch self {
        case .gluten: String(localized: "Gluten")
        case .crustaceans: String(localized: "Crustaceans")
        case .eggs: String(localized: "Eggs")
        case .fish: String(localized: "Fish")
        case .peanuts: String(localized: "Peanuts")
        case .soybeans: String(localized: "Soybeans")
        case .milk: String(localized: "Milk")
        case .nuts: String(localized: "Nuts")
        case .celery: String(localized: "Celery")
        case .mustard: String(localized: "Mustard")
        case .sesame: String(localized: "Sesame")
        case .sulphites: String(localized: "Sulphites")
        case .lupin: String(localized: "Lupin")
        case .molluscs: String(localized: "Molluscs")
        }
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
        case .standard: String(localized: "Standard")
        case .mediterranea: String(localized: "Mediterranean")
        case .iposodica: String(localized: "Low-sodium")
        case .ipocalorica: String(localized: "Low-calorie")
        case .iperproteica: String(localized: "High-protein")
        case .vegetariana: String(localized: "Vegetarian")
        case .vegana: String(localized: "Vegan")
        case .diabetica: String(localized: "Diabetic-friendly")
        case .glutenFree: String(localized: "Gluten-free")
        case .lactoseFree: String(localized: "Lactose-free")
        }
    }

    // swiftlint:disable line_length
    /// A short, informational description of the diet's principles and the foods
    /// it typically includes or excludes. Informational only — not medical or
    /// nutritional advice.
    public var explanation: String {
        switch self {
        case .standard:
            String(localized: "A balanced everyday diet with no specific restrictions. Includes a variety of foods across all groups.")
        case .mediterranea:
            String(
                localized: "Emphasizes vegetables, fruit, whole grains, legumes, fish and olive oil. Limits red meat and processed foods."
            )
        case .iposodica:
            String(
                localized: "Keeps salt low. Favors fresh, unprocessed foods and herbs for flavor; limits cured meats, cheese and salty snacks."
            )
        case .ipocalorica:
            String(
                localized: "Reduces total calories while keeping meals balanced. Favors vegetables, lean protein and whole grains; limits sugary and fatty foods."
            )
        case .iperproteica:
            String(
                localized: "Increases protein intake. Favors lean meat, fish, eggs, dairy and legumes; balances with vegetables and whole grains."
            )
        case .vegetariana:
            String(localized: "Excludes meat and fish. Includes vegetables, fruit, grains, legumes, eggs and dairy.")
        case .vegana:
            String(localized: "Excludes all animal products. Includes vegetables, fruit, grains, legumes, nuts and seeds.")
        case .diabetica:
            String(
                localized: "Focuses on steady blood-sugar choices: high-fiber foods, whole grains and lean protein; limits refined sugars and simple carbs."
            )
        case .glutenFree:
            String(
                localized: "Excludes gluten (wheat, barley, rye). Favors naturally gluten-free grains like rice, corn and certified gluten-free oats."
            )
        case .lactoseFree:
            String(localized: "Excludes lactose. Favors lactose-free dairy or plant-based alternatives and naturally lactose-free foods.")
        }
    }
    // swiftlint:enable line_length
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
        switch self {
        case .breakfast: String(localized: "Breakfast")
        case .lunch: String(localized: "Lunch")
        case .dinner: String(localized: "Dinner")
        case .snack: String(localized: "Snack")
        }
    }
}

/// Horizon a meal plan covers.
public enum MealPlanType: String, Codable, CaseIterable, Sendable {
    case singleDay
    case threeDays
    case week
    case month

    /// Number of days the horizon spans. A month is modeled as 30 days.
    public var dayCount: Int {
        switch self {
        case .singleDay: 1
        case .threeDays: 3
        case .week: 7
        case .month: 30
        }
    }

    public var displayName: String {
        switch self {
        case .singleDay: String(localized: "1 day")
        case .threeDays: String(localized: "3 days")
        case .week: String(localized: "Week")
        case .month: String(localized: "Month")
        }
    }
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
        case .produce: String(localized: "Produce")
        case .dairy: String(localized: "Dairy")
        case .meatFish: String(localized: "Meat & Fish")
        case .bakery: String(localized: "Bakery")
        case .pantry: String(localized: "Pantry")
        case .frozen: String(localized: "Frozen")
        case .beverages: String(localized: "Beverages")
        case .other: String(localized: "Other")
        }
    }
}
