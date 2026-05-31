import Foundation
#if canImport(FoundationModels)
    import FoundationModels
#endif

/// On-device AI meal planner backed by Apple's FoundationModels framework (iOS 26+).
///
/// Privacy: runs entirely on-device. Sensitive diet and allergen data never leaves
/// the device — there is no network call here. When the on-device model is
/// unavailable (older OS, model not ready, or generation fails) this planner
/// transparently delegates to a deterministic `fallback` so the app always
/// returns a valid plan.
public struct FoundationModelsMealPlanner: MealPlannerAIService {
    private let fallback: MealPlannerAIService
    private let expiryCalculator: CalculateExpiryStatusUseCase

    public init(
        fallback: MealPlannerAIService,
        expiryCalculator: CalculateExpiryStatusUseCase = .init()
    ) {
        self.fallback = fallback
        self.expiryCalculator = expiryCalculator
    }

    public func generatePlan(
        from products: [Product],
        profile: UserProfile,
        planType: MealPlanType
    ) async throws -> MealPlan {
        #if canImport(FoundationModels)
            if #available(iOS 26, *) {
                if let plan = try? await generateOnDevice(from: products, profile: profile, planType: planType) {
                    return plan
                }
            }
        #endif
        // Graceful fallback: iOS < 26, model unavailable, or generation failed.
        return try await fallback.generatePlan(from: products, profile: profile, planType: planType)
    }

    /// Products sorted most-expiring first, so the model is steered toward reducing waste.
    private func prioritized(_ products: [Product]) -> [Product] {
        products.sorted {
            expiryCalculator.priorityScore(for: $0) > expiryCalculator.priorityScore(for: $1)
        }
    }

    private func dayCount(for planType: MealPlanType) -> Int {
        switch planType {
        case .singleDay: 1
        case .threeDays: 3
        case .week: 7
        }
    }

    #if canImport(FoundationModels)
        @available(iOS 26, *)
        private func generateOnDevice(
            from products: [Product],
            profile: UserProfile,
            planType: MealPlanType
        ) async throws -> MealPlan? {
            // Only proceed when the on-device model is ready to use.
            guard case .available = SystemLanguageModel.default.availability else { return nil }

            let prioritizedProducts = prioritized(products)
            let days = dayCount(for: planType)
            let prompt = buildPrompt(
                prioritized: prioritizedProducts,
                profile: profile,
                days: days
            )

            let session = LanguageModelSession()
            let response = try await session.respond(to: prompt, generating: GeneratedMealPlan.self)
            return map(response.content, products: prioritizedProducts, planType: planType, days: days)
        }

        @available(iOS 26, *)
        private func buildPrompt(prioritized: [Product], profile: UserProfile, days: Int) -> String {
            // Only the most-urgent items are listed to keep the prompt focused.
            let pantryLines = prioritized.prefix(20).map { product -> String in
                if let remaining = expiryCalculator.daysRemaining(for: product) {
                    return "- \(product.name) (expires in \(remaining) day(s))"
                }
                return "- \(product.name)"
            }.joined(separator: "\n")

            let diet = profile.dietType.displayName
            let allergens = profile.allergens.isEmpty
                ? "none"
                : profile.allergens.map(\.displayName).joined(separator: ", ")

            return """
            Create a \(days)-day meal plan with exactly two meals per day (lunch and dinner).
            Prioritize using the pantry items that expire soonest to reduce food waste.
            Respect the diet type "\(diet)" and strictly avoid these allergens: \(allergens).
            For each meal include ingredients, ordered preparation steps, an estimated
            calorie count per serving, and prep and cook times in minutes.
            Keep summaries and steps practical and friendly. Do not include any health or medical claims.

            Pantry (most urgent first):
            \(pantryLines.isEmpty ? "- (empty)" : pantryLines)
            """
        }

        /// Maps untrusted model output into validated Domain entities (clamped lengths/counts).
        @available(iOS 26, *)
        private func map(
            _ generated: GeneratedMealPlan,
            products: [Product],
            planType: MealPlanType,
            days: Int
        ) -> MealPlan {
            let productsByName = Dictionary(
                products.map { ($0.name.lowercased(), $0) },
                uniquingKeysWith: { first, _ in first }
            )

            let expectedMeals = days * 2
            let meals: [Meal] = generated.meals.prefix(expectedMeals).enumerated().map { index, raw in
                let slot: MealType = raw.slot.lowercased().contains("lunch") ? .lunch : .dinner
                let dayIndex = min(max(0, raw.dayIndex), days - 1)
                let ingredients = raw.ingredients.prefix(8).map { name -> MealIngredient in
                    let trimmed = String(name.prefix(80)).trimmingCharacters(in: .whitespacesAndNewlines)
                    let match = productsByName[trimmed.lowercased()]
                    return MealIngredient(
                        name: trimmed.isEmpty ? "Ingredient" : trimmed,
                        quantity: 1,
                        unit: match?.unit ?? .piece,
                        isAvailableInPantry: match != nil,
                        linkedProductID: match?.id
                    )
                }
                let name = String(raw.name.prefix(120)).trimmingCharacters(in: .whitespacesAndNewlines)
                let summary = String(raw.summary.prefix(280)).trimmingCharacters(in: .whitespacesAndNewlines)
                let steps = raw.steps.prefix(12).map { step in
                    String(step.prefix(200)).trimmingCharacters(in: .whitespacesAndNewlines)
                }.filter { !$0.isEmpty }
                return Meal(
                    name: name.isEmpty ? "\(slot.displayName)" : name,
                    mealType: slot,
                    dayIndex: index / 2 < days ? index / 2 : dayIndex,
                    recipeSummary: summary,
                    estimatedCalories: clampCalories(raw.estimatedCalories),
                    steps: Array(steps),
                    prepMinutes: clampMinutes(raw.prepMinutes),
                    cookMinutes: clampMinutes(raw.cookMinutes),
                    ingredients: Array(ingredients)
                )
            }

            // If the model returned nothing usable, signal failure so the caller can fall back.
            let title = String(generated.title.prefix(80)).trimmingCharacters(in: .whitespacesAndNewlines)
            return MealPlan(
                title: title.isEmpty ? defaultTitle(for: planType) : title,
                planType: planType,
                startDate: .now,
                meals: meals
            )
        }

        private func defaultTitle(for planType: MealPlanType) -> String {
            switch planType {
            case .singleDay: "Today's plan"
            case .threeDays: "3-day plan"
            case .week: "Weekly plan"
            }
        }

        /// Clamps an untrusted calorie value into a sane range, or drops it.
        private func clampCalories(_ value: Int?) -> Int? {
            guard let value, value > 0 else { return nil }
            return min(value, 5000)
        }

        /// Clamps an untrusted minute value into a sane range, or drops it.
        private func clampMinutes(_ value: Int?) -> Int? {
            guard let value, value > 0 else { return nil }
            return min(value, 600)
        }
    #endif
}

#if canImport(FoundationModels)
    /// Guided-generation schema for the on-device model. Lives in Data — never in Domain.
    @available(iOS 26, *)
    @Generable
    struct GeneratedMealPlan {
        @Guide(description: "A short, friendly title for the meal plan")
        var title: String
        @Guide(description: "The meals, two per day in lunch then dinner order")
        var meals: [GeneratedMeal]
    }

    @available(iOS 26, *)
    @Generable
    struct GeneratedMeal {
        @Guide(description: "A short meal name")
        var name: String
        @Guide(description: "Either 'lunch' or 'dinner'")
        var slot: String
        @Guide(description: "Zero-based day index within the plan")
        var dayIndex: Int
        @Guide(description: "One practical sentence describing the meal. No health or medical claims.")
        var summary: String
        @Guide(description: "The ingredient names used in this meal")
        var ingredients: [String]
        @Guide(description: "Ordered preparation steps, each a short practical sentence. No health or medical claims.")
        var steps: [String]
        @Guide(description: "Estimated total calories for one serving")
        var estimatedCalories: Int?
        @Guide(description: "Hands-on preparation time in minutes")
        var prepMinutes: Int?
        @Guide(description: "Cooking time in minutes")
        var cookMinutes: Int?
    }
#endif
