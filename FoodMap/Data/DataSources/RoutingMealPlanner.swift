import Foundation

/// Routes meal-plan generation to the engine the user selected, reading the
/// preference fresh on every call so changes take effect immediately.
///
/// `automatic` and `onDevice` both resolve to the on-device planner, which
/// already falls back to the rule-based engine when the model is unavailable.
public struct RoutingMealPlanner: MealPlannerAIService {
    private let store: MealPlannerModelStore
    private let ruleBased: MealPlannerAIService
    private let onDevice: MealPlannerAIService

    public init(
        store: MealPlannerModelStore,
        ruleBased: MealPlannerAIService,
        onDevice: MealPlannerAIService
    ) {
        self.store = store
        self.ruleBased = ruleBased
        self.onDevice = onDevice
    }

    private var active: MealPlannerAIService {
        switch store.selectedModel() {
        case .ruleBased: ruleBased
        case .automatic, .onDevice: onDevice
        }
    }

    public func generatePlan(
        from products: [Product],
        profile: UserProfile,
        planType: MealPlanType
    ) async throws -> MealPlan {
        try await active.generatePlan(from: products, profile: profile, planType: planType)
    }

    public func alternatives(
        for meal: Meal,
        from products: [Product],
        profile: UserProfile,
        count: Int
    ) async throws -> [Meal] {
        try await active.alternatives(for: meal, from: products, profile: profile, count: count)
    }
}
