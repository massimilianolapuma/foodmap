import XCTest
@testable import FoodMap

/// Tests for #52 — selecting the meal-planner engine. Covers the UserDefaults
/// store and the routing planner that delegates per the stored choice.
final class MealPlannerModelSelectionTests: XCTestCase {
    private func makeStore() -> UserDefaultsMealPlannerModelStore {
        let suite = UserDefaults(suiteName: "test.\(UUID().uuidString)")!
        return UserDefaultsMealPlannerModelStore(defaults: suite)
    }

    func testDefaultsToAutomatic() {
        let store = makeStore()
        XCTAssertEqual(store.selectedModel(), .automatic)
    }

    func testPersistsRuleBasedSelection() {
        let store = makeStore()
        store.select(.ruleBased)
        XCTAssertEqual(store.selectedModel(), .ruleBased)
    }

    func testOnDeviceSelectionHonoredOrDegradedByCapability() {
        let store = makeStore()
        store.select(.onDevice)
        if store.isOnDeviceModelAvailable() {
            XCTAssertEqual(store.selectedModel(), .onDevice)
        } else {
            // On a device without the engine, an on-device choice degrades to automatic.
            XCTAssertEqual(store.selectedModel(), .automatic)
        }
    }

    func testAvailableModelsReflectCapability() {
        let store = makeStore()
        let models = store.availableModels()
        XCTAssertEqual(models.contains(.onDevice), store.isOnDeviceModelAvailable())
        XCTAssertTrue(models.contains(.automatic))
        XCTAssertTrue(models.contains(.ruleBased))
    }

    func testRoutingUsesRuleBasedWhenSelected() async throws {
        let store = makeStore()
        store.select(.ruleBased)
        let ruleBased = SpyPlanner(label: "rule")
        let onDevice = SpyPlanner(label: "device")
        let router = RoutingMealPlanner(store: store, ruleBased: ruleBased, onDevice: onDevice)

        let plan = try await router.generatePlan(
            from: [],
            profile: UserProfile(),
            planType: .singleDay
        )
        XCTAssertEqual(plan.title, "rule")
    }

    func testRoutingUsesOnDeviceForAutomatic() async throws {
        let store = makeStore()
        let ruleBased = SpyPlanner(label: "rule")
        let onDevice = SpyPlanner(label: "device")
        let router = RoutingMealPlanner(store: store, ruleBased: ruleBased, onDevice: onDevice)

        let plan = try await router.generatePlan(
            from: [],
            profile: UserProfile(),
            planType: .singleDay
        )
        XCTAssertEqual(plan.title, "device")
    }
}

/// Minimal planner that tags its plan with a label so routing can be asserted.
private struct SpyPlanner: MealPlannerAIService {
    let label: String

    func generatePlan(
        from _: [Product],
        profile _: UserProfile,
        planType _: MealPlanType
    ) async throws -> MealPlan {
        MealPlan(title: label, meals: [])
    }
}
