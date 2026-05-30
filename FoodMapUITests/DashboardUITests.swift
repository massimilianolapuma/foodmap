import XCTest

/// Exercises the "Today" dashboard. With the seeded UI-testing dataset, the
/// dashboard surfaces products expiring within a week.
final class DashboardUITests: FoodMapUITestCase {
    func testDashboardShowsExpiringContent() {
        let app = launchApp()
        selectTab("tab.dashboard", label: "Today", in: app)

        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: defaultTimeout))

        // Either the expiring list or the empty state must be present.
        let list = app.descendants(matching: .any)["dashboard.list"]
        let emptyState = app.descendants(matching: .any)["dashboard.emptyState"]
        XCTAssertTrue(
            list.waitForExistence(timeout: defaultTimeout) || emptyState.exists,
            "Dashboard should show either the expiring list or an empty state"
        )

        // The seeded "Milk" product expires within the dashboard's 7-day window.
        XCTAssertTrue(
            app.staticTexts["Milk"].waitForExistence(timeout: defaultTimeout),
            "Seeded expiring product should appear on the dashboard"
        )
    }
}
