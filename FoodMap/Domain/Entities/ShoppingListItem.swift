import Foundation
import SwiftData

/// An item on the shopping list, generated from a meal plan's missing ingredients.
@Model
public final class ShoppingListItem {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var quantity: Double
    public var unitRaw: String
    public var categoryRaw: String
    public var isChecked: Bool
    public var addedAt: Date
    public var sourceMealPlanID: UUID?

    public init(
        id: UUID = UUID(),
        name: String,
        quantity: Double = 1,
        unit: MeasurementUnit = .piece,
        category: GroceryCategory = .other,
        isChecked: Bool = false,
        addedAt: Date = .now,
        sourceMealPlanID: UUID? = nil
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        unitRaw = unit.rawValue
        categoryRaw = category.rawValue
        self.isChecked = isChecked
        self.addedAt = addedAt
        self.sourceMealPlanID = sourceMealPlanID
    }
}

public extension ShoppingListItem {
    var unit: MeasurementUnit {
        get { MeasurementUnit(rawValue: unitRaw) ?? .piece }
        set { unitRaw = newValue.rawValue }
    }

    var category: GroceryCategory {
        get { GroceryCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }
}
