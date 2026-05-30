import XCTest
@testable import FoodMap

/// Tests for the on-device FoundationModels planner adapter (issue #14).
///
/// On the iOS 17 simulator the FoundationModels path is unavailable, so the
/// adapter must transparently delegate to its `fallback` and still return a
/// valid plan. This guarantees deterministic behavior in CI.
final class FoundationModelsMealPlannerTests: XCTestCase {
    /// Records delegation and returns a sentinel plan.
    private final class SpyPlanner: MealPlannerAIService, @unchecked Sendable {
        let title: String
        private(set) var callCount = 0

        init(title: String) {
            self.title = title
        }

        func generatePlan(
            from _: [Product],
            profile _: UserProfile,
            planType: MealPlanType
        ) async throws -> MealPlan {
            callCount += 1
            return MealPlan(title: title, planType: planType)
        }
    }

    func testFallsBackToFallbackPlannerWhenOnDeviceUnavailable() async throws {
        let spy = SpyPlanner(title: "Sentinel plan")
        let planner = FoundationModelsMealPlanner(fallback: spy)
        let products = [Product(name: "Tomato", expiryDate: .make(year: 2026, month: 6, day: 2))]

        let plan = try await planner.generatePlan(
            from: products,
            profile: UserProfile(dietType: .standard),
            planType: .singleDay
        )

        // On the simulator the on-device model is unavailable → fallback is used.
        XCTAssertEqual(spy.callCount, 1)
        XCTAssertEqual(plan.title, "Sentinel plan")
    }

    func testProducesValidPlanWithRuleBasedFallback() async throws {
        let planner = FoundationModelsMealPlanner(fallback: RuleBasedMealPlanner())
        let products = [
            Product(name: "Spinach", expiryDate: .make(year: 2026, month: 6, day: 1)),
            Product(name: "Rice", expiryDate: .make(year: 2026, month: 6, day: 20))
        ]

        let plan = try await planner.generatePlan(
            from: products,
            profile: UserProfile(dietType: .standard),
            planType: .threeDays
        )

        XCTAssertEqual(plan.meals.count, 6)
        XCTAssertFalse(plan.title.isEmpty)
    }
}
