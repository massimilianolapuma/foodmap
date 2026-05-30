import Foundation
import SwiftData

/// A generated meal plan over a horizon, composed of meals.
@Model
public final class MealPlan {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var planTypeRaw: String
    public var startDate: Date
    public var createdAt: Date
    @Relationship(deleteRule: .cascade) public var meals: [Meal]

    public init(
        id: UUID = UUID(),
        title: String,
        planType: MealPlanType = .week,
        startDate: Date = .now,
        createdAt: Date = .now,
        meals: [Meal] = []
    ) {
        self.id = id
        self.title = title
        planTypeRaw = planType.rawValue
        self.startDate = startDate
        self.createdAt = createdAt
        self.meals = meals
    }
}

public extension MealPlan {
    var planType: MealPlanType {
        get { MealPlanType(rawValue: planTypeRaw) ?? .week }
        set { planTypeRaw = newValue.rawValue }
    }
}

/// A single meal within a plan.
@Model
public final class Meal {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var mealTypeRaw: String
    public var dayIndex: Int
    public var recipeSummary: String
    public var estimatedCalories: Int?
    @Relationship(deleteRule: .cascade) public var ingredients: [MealIngredient]

    public init(
        id: UUID = UUID(),
        name: String,
        mealType: MealType = .dinner,
        dayIndex: Int = 0,
        recipeSummary: String = "",
        estimatedCalories: Int? = nil,
        ingredients: [MealIngredient] = []
    ) {
        self.id = id
        self.name = name
        mealTypeRaw = mealType.rawValue
        self.dayIndex = dayIndex
        self.recipeSummary = recipeSummary
        self.estimatedCalories = estimatedCalories
        self.ingredients = ingredients
    }
}

public extension Meal {
    var mealType: MealType {
        get { MealType(rawValue: mealTypeRaw) ?? .dinner }
        set { mealTypeRaw = newValue.rawValue }
    }
}

/// An ingredient required by a meal, with whether it is already in the pantry.
@Model
public final class MealIngredient {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var quantity: Double
    public var unitRaw: String
    public var isAvailableInPantry: Bool
    public var linkedProductID: UUID?

    public init(
        id: UUID = UUID(),
        name: String,
        quantity: Double = 1,
        unit: MeasurementUnit = .piece,
        isAvailableInPantry: Bool = false,
        linkedProductID: UUID? = nil
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        unitRaw = unit.rawValue
        self.isAvailableInPantry = isAvailableInPantry
        self.linkedProductID = linkedProductID
    }
}

public extension MealIngredient {
    var unit: MeasurementUnit {
        get { MeasurementUnit(rawValue: unitRaw) ?? .piece }
        set { unitRaw = newValue.rawValue }
    }
}
