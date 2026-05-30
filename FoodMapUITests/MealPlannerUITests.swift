import XCTest

/// Exercises the meal planner: the generate action, the empty state, and the
/// plan list produced by the deterministic on-device rule-based planner.
final class MealPlannerUITests: FoodMapUITestCase {
    func testMealPlannerGeneratesPlan() {
        let app = launchApp()
        selectTab("tab.meals", label: "Meals", in: app)

        XCTAssertTrue(app.navigationBars["Meals"].waitForExistence(timeout: defaultTimeout))

        let generate = app.buttons["meals.generateButton"]
        XCTAssertTrue(generate.waitForExistence(timeout: defaultTimeout), "Generate action should be present")

        let emptyState = app.descendants(matching: .any)["meals.emptyState"]
        XCTAssertTrue(emptyState.waitForExistence(timeout: defaultTimeout), "Empty state should be shown before generating")

        generate.tap()

        // The rule-based planner runs on-device and deterministically produces a plan.
        let list = app.descendants(matching: .any)["meals.list"]
        XCTAssertTrue(
            list.waitForExistence(timeout: defaultTimeout),
            "A meal plan list should appear after generating"
        )
    }
}
