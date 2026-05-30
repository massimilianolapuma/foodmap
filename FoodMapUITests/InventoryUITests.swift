import XCTest

/// Exercises the pantry inventory: list/empty state and the per-location filter.
final class InventoryUITests: FoodMapUITestCase {
    func testInventoryListFilterAndSeededProducts() {
        let app = launchApp()
        selectTab("tab.inventory", label: "Pantry", in: app)

        XCTAssertTrue(app.navigationBars["Pantry"].waitForExistence(timeout: defaultTimeout))

        let list = app.descendants(matching: .any)["inventory.list"]
        let emptyState = app.descendants(matching: .any)["inventory.emptyState"]
        XCTAssertTrue(
            list.waitForExistence(timeout: defaultTimeout) || emptyState.exists,
            "Inventory should show either the product list or an empty state"
        )

        // Seeded products are present, so the list and its filter are shown.
        XCTAssertTrue(
            app.staticTexts["Pasta"].waitForExistence(timeout: defaultTimeout),
            "Seeded pantry product should appear in the inventory"
        )

        if list.exists {
            let filter = app.descendants(matching: .any)["inventory.filter"]
            XCTAssertTrue(filter.waitForExistence(timeout: defaultTimeout), "Filter control should be present")
            XCTAssertTrue(filter.isHittable, "Filter control should be tappable")
            filter.tap()
        }
    }
}
