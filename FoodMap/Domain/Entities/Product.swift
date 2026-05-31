import Foundation
import SwiftData

/// A product tracked in the user's pantry. Persisted with SwiftData.
@Model
public final class Product {
    @Attribute(.unique) public var id: UUID
    public var barcode: String?
    public var name: String
    public var brand: String?
    public var categoryRaw: String
    public var storageLocationRaw: String
    public var quantity: Double
    public var unitRaw: String
    public var imageURLString: String?
    /// User-captured product photo, stored locally on-device as JPEG. Never uploaded to third parties.
    @Attribute(.externalStorage) public var imageData: Data?
    public var expiryDate: Date?
    /// `true` when `expiryDate` was estimated for a perishable without an
    /// explicit date, rather than read from packaging. Advisory only.
    public var expiryIsEstimated: Bool = false
    public var openedDate: Date?
    public var addedDate: Date
    public var sourceRaw: String
    public var allergensRaw: [String]
    public var nutrition: NutritionInfo?

    public init(
        id: UUID = UUID(),
        barcode: String? = nil,
        name: String,
        brand: String? = nil,
        category: ProductCategory = .other,
        storageLocation: StorageLocation = .pantry,
        quantity: Double = 1,
        unit: MeasurementUnit = .piece,
        imageURLString: String? = nil,
        imageData: Data? = nil,
        expiryDate: Date? = nil,
        expiryIsEstimated: Bool = false,
        openedDate: Date? = nil,
        addedDate: Date = .now,
        source: ProductSource = .manual,
        allergens: [Allergen] = [],
        nutrition: NutritionInfo? = nil
    ) {
        self.id = id
        self.barcode = barcode
        self.name = name
        self.brand = brand
        categoryRaw = category.rawValue
        storageLocationRaw = storageLocation.rawValue
        self.quantity = quantity
        unitRaw = unit.rawValue
        self.imageURLString = imageURLString
        self.imageData = imageData
        self.expiryDate = expiryDate
        self.expiryIsEstimated = expiryIsEstimated
        self.openedDate = openedDate
        self.addedDate = addedDate
        sourceRaw = source.rawValue
        allergensRaw = allergens.map(\.rawValue)
        self.nutrition = nutrition
    }
}

public extension Product {
    var category: ProductCategory {
        get { ProductCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var storageLocation: StorageLocation {
        get { StorageLocation(rawValue: storageLocationRaw) ?? .pantry }
        set { storageLocationRaw = newValue.rawValue }
    }

    var unit: MeasurementUnit {
        get { MeasurementUnit(rawValue: unitRaw) ?? .piece }
        set { unitRaw = newValue.rawValue }
    }

    var source: ProductSource {
        get { ProductSource(rawValue: sourceRaw) ?? .manual }
        set { sourceRaw = newValue.rawValue }
    }

    var allergens: [Allergen] {
        get { allergensRaw.compactMap(Allergen.init(rawValue:)) }
        set { allergensRaw = newValue.map(\.rawValue) }
    }
}

/// Per-serving nutrition values. Optional; sourced from Open Food Facts when available.
@Model
public final class NutritionInfo {
    public var energyKcal: Double?
    public var proteinGrams: Double?
    public var carbohydrateGrams: Double?
    public var fatGrams: Double?
    public var sugarGrams: Double?
    public var saltGrams: Double?

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
