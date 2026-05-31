import Foundation

/// Suggests products the user might want to buy, using simple, deterministic and
/// fully testable rules — no machine learning, no network calls.
///
/// The result is an ordered, de-duplicated list. When the same product qualifies
/// under multiple reasons, the strongest reason wins (see `SuggestionReason.priority`):
/// `missingForMealPlan` > `recurring` > `lowCategory` > `staple`.
///
/// Privacy: operates entirely on data already on-device (purchase history, the
/// current pantry, and an optional meal plan). It never contacts third parties.
public struct SuggestProductsUseCase: Sendable {
    /// Default household staples used as a last-resort suggestion source.
    public static let defaultStaples: [StapleProduct] = [
        StapleProduct(name: "Salt", category: .condiments),
        StapleProduct(name: "Olive oil", category: .condiments),
        StapleProduct(name: "Pasta", category: .pantryStaples),
        StapleProduct(name: "Rice", category: .pantryStaples),
        StapleProduct(name: "Flour", category: .pantryStaples),
        StapleProduct(name: "Sugar", category: .pantryStaples),
        StapleProduct(name: "Eggs", category: .dairy),
        StapleProduct(name: "Milk", category: .dairy),
        StapleProduct(name: "Bread", category: .bakery),
        StapleProduct(name: "Butter", category: .dairy)
    ]

    public init() {}

    /// - Parameters:
    ///   - history: Products bought in the past (may include items no longer in the pantry).
    ///   - pantry: Products currently in the pantry. Suggestions never include these.
    ///   - plan: Optional current meal plan; missing ingredients become strong suggestions.
    ///   - productsByID: Lookup used to derive a category for linked meal-plan ingredients.
    ///   - staples: Household staples used as a fallback source. Defaults to `defaultStaples`.
    ///   - maxResults: Maximum number of suggestions returned.
    /// - Returns: Ordered, de-duplicated suggestions, strongest reason first.
    public func callAsFunction(
        history: [Product],
        pantry: [Product],
        plan: MealPlan? = nil,
        productsByID: [UUID: Product] = [:],
        staples: [StapleProduct] = SuggestProductsUseCase.defaultStaples,
        maxResults: Int = 10
    ) -> [ProductSuggestion] {
        let pantryNames = Set(pantry.map { Self.normalized($0.name) })
        let pantryCategories = Set(pantry.map(\.category))

        var ordered: [ProductSuggestion] = []
        ordered += missingForMealPlan(plan: plan, pantryNames: pantryNames, productsByID: productsByID)
        ordered += recurring(history: history, pantryNames: pantryNames)
        ordered += lowCategory(history: history, pantryNames: pantryNames, pantryCategories: pantryCategories)
        ordered += stapleSuggestions(staples: staples, pantryNames: pantryNames)

        // De-duplicate by normalized name, keeping the first (highest-priority) occurrence.
        var seen = Set<String>()
        var deduped: [ProductSuggestion] = []
        for suggestion in ordered {
            let key = Self.normalized(suggestion.name)
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            deduped.append(suggestion)
        }

        return Array(deduped.prefix(max(0, maxResults)))
    }

    // MARK: - Rules

    private func missingForMealPlan(
        plan: MealPlan?,
        pantryNames: Set<String>,
        productsByID: [UUID: Product]
    ) -> [ProductSuggestion] {
        guard let plan else { return [] }

        var byName: [String: ProductSuggestion] = [:]
        for meal in plan.meals {
            for ingredient in meal.ingredients where !ingredient.isAvailableInPantry {
                let key = Self.normalized(ingredient.name)
                guard !key.isEmpty, !pantryNames.contains(key), byName[key] == nil else { continue }
                let category = ingredient.linkedProductID
                    .flatMap { productsByID[$0]?.category } ?? .other
                byName[key] = ProductSuggestion(
                    name: ingredient.name,
                    reason: .missingForMealPlan,
                    category: category
                )
            }
        }

        return byName.values.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func recurring(history: [Product], pantryNames: Set<String>) -> [ProductSuggestion] {
        var counts: [String: Int] = [:]
        var display: [String: String] = [:]
        var category: [String: ProductCategory] = [:]
        for product in history {
            let key = Self.normalized(product.name)
            guard !key.isEmpty else { continue }
            counts[key, default: 0] += 1
            if display[key] == nil { display[key] = product.name }
            if category[key] == nil { category[key] = product.category }
        }

        let recurringKeys = counts
            .filter { $0.value >= 2 && !pantryNames.contains($0.key) }
            .sorted { lhs, rhs in
                if lhs.value != rhs.value { return lhs.value > rhs.value }
                return (display[lhs.key] ?? lhs.key)
                    .localizedCaseInsensitiveCompare(display[rhs.key] ?? rhs.key) == .orderedAscending
            }

        return recurringKeys.map { key, _ in
            ProductSuggestion(
                name: display[key] ?? key,
                reason: .recurring,
                category: category[key] ?? .other
            )
        }
    }

    private func lowCategory(
        history: [Product],
        pantryNames: Set<String>,
        pantryCategories: Set<ProductCategory>
    ) -> [ProductSuggestion] {
        // Categories the user has bought before but that are now empty in the pantry.
        let missingCategories = Set(history.map(\.category)).subtracting(pantryCategories)
        guard !missingCategories.isEmpty else { return [] }

        var suggestions: [ProductSuggestion] = []
        for category in missingCategories {
            // Pick the most frequently bought product of that category, not already stocked.
            var counts: [String: Int] = [:]
            var display: [String: String] = [:]
            for product in history where product.category == category {
                let key = Self.normalized(product.name)
                guard !key.isEmpty, !pantryNames.contains(key) else { continue }
                counts[key, default: 0] += 1
                if display[key] == nil { display[key] = product.name }
            }
            guard let best = counts.sorted(by: { lhs, rhs in
                if lhs.value != rhs.value { return lhs.value > rhs.value }
                return (display[lhs.key] ?? lhs.key)
                    .localizedCaseInsensitiveCompare(display[rhs.key] ?? rhs.key) == .orderedAscending
            }).first else { continue }
            suggestions.append(
                ProductSuggestion(
                    name: display[best.key] ?? best.key,
                    reason: .lowCategory,
                    category: category
                )
            )
        }

        return suggestions.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func stapleSuggestions(staples: [StapleProduct], pantryNames: Set<String>) -> [ProductSuggestion] {
        staples
            .filter { !pantryNames.contains(Self.normalized($0.name)) }
            .map { ProductSuggestion(name: $0.name, reason: .staple, category: $0.category) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    // MARK: - Helpers

    private static func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
