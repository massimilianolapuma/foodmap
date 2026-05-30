import Foundation

/// Filters meals so they respect the user's diet type and allergen restrictions.
/// Pure logic operating on domain types — fully unit-testable.
public struct FilterMealsByDietRestrictionsUseCase: Sendable {
    public init() {}

    public func callAsFunction(meals: [Meal], profile: UserProfile, productsByID: [UUID: Product]) -> [Meal] {
        meals.filter { meal in
            isAllowed(meal: meal, profile: profile, productsByID: productsByID)
        }
    }

    private func isAllowed(meal: Meal, profile: UserProfile, productsByID: [UUID: Product]) -> Bool {
        let allergens = mealAllergens(meal, productsByID: productsByID)
        // Reject if any ingredient carries an allergen the user must avoid.
        if !profile.allergens.isEmpty, !allergens.isDisjoint(with: Set(profile.allergens)) {
            return false
        }

        switch profile.dietType {
        case .vegana:
            return allergens.isDisjoint(with: [.milk, .eggs, .fish, .crustaceans, .molluscs])
                && !mealMentions(meal, any: ["meat", "beef", "pork", "chicken", "fish", "carne", "pesce", "pollo"])
        case .vegetariana:
            return !mealMentions(meal, any: ["meat", "beef", "pork", "chicken", "fish", "carne", "pesce", "pollo"])
        case .glutenFree:
            return !allergens.contains(.gluten)
        case .lactoseFree:
            return !allergens.contains(.milk)
        case .standard, .mediterranea, .iposodica, .ipocalorica, .iperproteica, .diabetica:
            return true
        }
    }

    private func mealAllergens(_ meal: Meal, productsByID: [UUID: Product]) -> Set<Allergen> {
        var result: Set<Allergen> = []
        for ingredient in meal.ingredients {
            if let id = ingredient.linkedProductID, let product = productsByID[id] {
                result.formUnion(product.allergens)
            }
        }
        return result
    }

    private func mealMentions(_ meal: Meal, any keywords: [String]) -> Bool {
        let haystack = (meal.name + " " + meal.recipeSummary + " "
            + meal.ingredients.map(\.name).joined(separator: " ")).lowercased()
        return keywords.contains { haystack.contains($0) }
    }
}

/// Builds a shopping list from a meal plan's ingredients that are not in the pantry,
/// aggregating duplicates by name+unit.
public struct GenerateShoppingListFromMealPlanUseCase: Sendable {
    public init() {}

    public func callAsFunction(plan: MealPlan) -> [ShoppingListItem] {
        var aggregated: [String: ShoppingListItem] = [:]
        for meal in plan.meals {
            for ingredient in meal.ingredients where !ingredient.isAvailableInPantry {
                let key = ingredient.name.lowercased() + "|" + ingredient.unit.rawValue
                if let existing = aggregated[key] {
                    existing.quantity += ingredient.quantity
                } else {
                    aggregated[key] = ShoppingListItem(
                        name: ingredient.name,
                        quantity: ingredient.quantity,
                        unit: ingredient.unit,
                        category: .other,
                        sourceMealPlanID: plan.id
                    )
                }
            }
        }
        return aggregated.values.sorted { $0.name < $1.name }
    }
}
