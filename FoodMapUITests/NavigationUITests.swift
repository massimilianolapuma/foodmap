import XCTest

/// Verifies the app boots and every primary tab is reachable, showing the
/// expected root screen for each feature — all within a single app launch.
final class NavigationUITests: FoodMapUITestCase {
    func testAppLaunchesAndEveryTabIsReachable() {
        let app = launchApp()

        XCTAssertTrue(
            app.tabBars.firstMatch.waitForExistence(timeout: defaultTimeout),
            "Tab bar should be visible at launch"
        )
        // The app exposes five primary tabs, so every one stays visible on
        // iPhone without overflowing into a system "More" tab.
        let hasTabs = NSPredicate(format: "count >= 5")
        let expectation = XCTNSPredicateExpectation(predicate: hasTabs, object: app.tabBars.buttons)
        XCTAssertEqual(
            XCTWaiter().wait(for: [expectation], timeout: defaultTimeout),
            .completed,
            "Tab bar should expose the feature tabs"
        )

        selectTab("tab.dashboard", label: "Today", in: app)
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: defaultTimeout))

        selectTab("tab.inventory", label: "Pantry", in: app)
        XCTAssertTrue(app.navigationBars["Pantry"].waitForExistence(timeout: defaultTimeout))

        // Scanning is reached from within the Pantry tab.
        let scanButton = app.buttons["inventory.scanButton"]
        XCTAssertTrue(scanButton.waitForExistence(timeout: defaultTimeout))
        scanButton.tap()
        XCTAssertTrue(app.navigationBars["Scan"].waitForExistence(timeout: defaultTimeout))
        app.buttons["scanner.doneButton"].tap()

        selectTab("tab.meals", label: "Meals", in: app)
        XCTAssertTrue(app.navigationBars["Meals"].waitForExistence(timeout: defaultTimeout))

        selectTab("tab.shopping", label: "Shopping", in: app)
        XCTAssertTrue(app.navigationBars["Shopping"].waitForExistence(timeout: defaultTimeout))

        selectTab("tab.profile", label: "Profile", in: app)
        XCTAssertTrue(app.navigationBars["Profile"].waitForExistence(timeout: defaultTimeout))
    }
}
