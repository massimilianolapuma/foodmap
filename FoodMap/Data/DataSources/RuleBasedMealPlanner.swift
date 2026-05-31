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
        let dayCount = planType.dayCount

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
                recipeSummary: "Add products to your pantry to get tailored suggestions.",
                steps: [String(localized: "Add a few products to your pantry, then generate a plan again.")],
                ingredients: []
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
            estimatedCalories: estimatedCalories(for: ingredients, products: pantry),
            steps: steps(for: primary, ingredients: ingredients, mealType: mealType),
            prepMinutes: 10,
            cookMinutes: cookMinutes(for: mealType),
            ingredients: ingredients
        )
    }

    /// Sums known per-product energy values across the meal's pantry-linked ingredients.
    private func estimatedCalories(for ingredients: [MealIngredient], products: [Product]) -> Int? {
        let byID = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
        let total = ingredients.reduce(into: 0.0) { sum, ingredient in
            if let id = ingredient.linkedProductID, let kcal = byID[id]?.nutrition?.energyKcal {
                sum += kcal
            }
        }
        return total > 0 ? Int(total.rounded()) : nil
    }

    /// Builds simple, practical preparation steps. No health or medical claims.
    private func steps(for primary: Product, ingredients: [MealIngredient], mealType: MealType) -> [String] {
        let others = ingredients.dropFirst().map(\.name)
        var steps = [
            String(localized: "Gather your ingredients and wash anything fresh."),
            String(localized: "Prepare \(primary.name): peel, chop, or portion as needed.")
        ]
        if !others.isEmpty {
            steps.append(String(localized: "Combine with \(others.joined(separator: ", "))."))
        }
        switch mealType {
        case .breakfast:
            steps.append(String(localized: "Assemble and serve fresh."))
        case .lunch, .dinner, .snack:
            steps.append(String(localized: "Cook over medium heat until done, season to taste, and serve."))
        }
        return steps
    }

    private func cookMinutes(for mealType: MealType) -> Int {
        switch mealType {
        case .breakfast: 5
        case .snack: 5
        case .lunch: 20
        case .dinner: 25
        }
    }

    private func planTitle(for type: MealPlanType) -> String {
        switch type {
        case .singleDay: "Today's plan"
        case .threeDays: "3-day plan"
        case .week: "Weekly plan"
        case .month: "Monthly plan"
        }
    }
}
