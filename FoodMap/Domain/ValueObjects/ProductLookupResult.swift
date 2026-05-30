import Foundation

/// A product looked up from an external provider, decoupled from persistence.
/// This is a pure domain value type — no DTO/SwiftData details leak here.
public struct ProductLookupResult: Equatable, Sendable {
    public let barcode: String
    public let name: String
    public let brand: String?
    public let category: ProductCategory
    public let imageURLString: String?
    public let allergens: [Allergen]
    public let nutrition: NutritionSnapshot?
    public let source: ProductSource

    public init(
        barcode: String,
        name: String,
        brand: String? = nil,
        category: ProductCategory = .other,
        imageURLString: String? = nil,
        allergens: [Allergen] = [],
        nutrition: NutritionSnapshot? = nil,
        source: ProductSource = .openFoodFacts
    ) {
        self.barcode = barcode
        self.name = name
        self.brand = brand
        self.category = category
        self.imageURLString = imageURLString
        self.allergens = allergens
        self.nutrition = nutrition
        self.source = source
    }
}

/// Immutable nutrition snapshot used in lookup results (separate from the SwiftData model).
public struct NutritionSnapshot: Equatable, Sendable {
    public let energyKcal: Double?
    public let proteinGrams: Double?
    public let carbohydrateGrams: Double?
    public let fatGrams: Double?
    public let sugarGrams: Double?
    public let saltGrams: Double?

    public init(
        energyKcal: Double? = nil,
        proteinGrams: Double? = nil,
        carbohydrateGrams: Double? = nil,
        fatGrams: Double? = nil,
        sugarGrams: Double? = nil,
        saltGrams: Double? = nil
    ) {
        self.energyKcal = energyKcal
        self.proteinGrams = proteinGrams
        self.carbohydrateGrams = carbohydrateGrams
        self.fatGrams = fatGrams
        self.sugarGrams = sugarGrams
        self.saltGrams = saltGrams
    }
}
