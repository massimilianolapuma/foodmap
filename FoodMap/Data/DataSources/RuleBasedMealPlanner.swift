import Foundation

/// Deterministic meal planner that prioritizes products closest to expiry, then
/// availability, then minimal missing ingredients. Implements `MealPlannerAIService`
/// so an on-device (FoundationModels) or cloud AI adapter can be swapped in later.
public struct RuleBasedMealPlanner: MealPlannerAIService {
    private let expiryCalculator: CalculateExpiryStatusUseCase
    private let dietFilter: FilterMealsByDietRestrictionsUseCase

    public init(
        expiryCalculator: CalculateExpiryStatusUseCase = .init(),
        dietFilter: FilterMealsByDietRestrictionsUseCase = .init()
    ) {
        self.expiryCalculator = expiryCalculator
        self.dietFilter = dietFilter
    }

    public func generatePlan(
        from products: [Product],
        profile: UserProfile,
        planType: MealPlanType
    ) async throws -> MealPlan {
        let dayCount = switch planType {
        case .singleDay: 1
        case .threeDays: 3
        case .week: 7
        }

        // Sort the pantry by urgency so the most-expiring items are used first.
        let prioritized = products.sorted {
            expiryCalculator.priorityScore(for: $0) > expiryCalculator.priorityScore(for: $1)
        }
        let productsByID = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })

        var meals: [Meal] = []
        var cursor = 0

        for day in 0..<dayCount {
            for slot in [MealType.lunch, MealType.dinner] {
                let primary = prioritized.isEmpty ? nil : prioritized[cursor % prioritized.count]
                cursor += 1

                let meal = makeMeal(
                    around: primary,
                    pantry: prioritized,
                    mealType: slot,
                    dayIndex: day
                )
                meals.append(meal)
            }
        }

        let allowed = dietFilter(meals: meals, profile: profile, productsByID: productsByID)
        let finalMeals = allowed.isEmpty ? meals : allowed

        return MealPlan(
            title: planTitle(for: planType),
            planType: planType,
            startDate: .now,
            meals: finalMeals
        )
    }

    private func makeMeal(around primary: Product?, pantry: [Product], mealType: MealType, dayIndex: Int) -> Meal {
        guard let primary else {
            return Meal(
                name: "\(mealType.displayName): pantry pick",
                mealType: mealType,
                dayIndex: dayIndex,
                recipeSummary: "Add products to your pantry to get tailored suggestions."
            )
        }

        // Pair the primary item with up to two complementary pantry items.
        let companions = pantry.filter { $0.id != primary.id }.prefix(2)
        var ingredients = [
            MealIngredient(
                name: primary.name,
                quantity: 1,
                unit: primary.unit,
                isAvailableInPantry: true,
                linkedProductID: primary.id
            )
        ]
        for companion in companions {
            ingredients.append(
                MealIngredient(
                    name: companion.name,
                    quantity: 1,
                    unit: companion.unit,
                    isAvailableInPantry: true,
                    linkedProductID: companion.id
                )
            )
        }

        return Meal(
            name: "\(mealType.displayName) with \(primary.name)",
            mealType: mealType,
            dayIndex: dayIndex,
            recipeSummary: "Use \(primary.name) before it expires, combined with what you already have.",
            estimatedCalories: primary.nutrition?.energyKcal.map { Int($0) },
            ingredients: ingredients
        )
    }

    private func planTitle(for type: MealPlanType) -> String {
        switch type {
        case .singleDay: "Today's plan"
        case .threeDays: "3-day plan"
        case .week: "Weekly plan"
        }
    }
}
