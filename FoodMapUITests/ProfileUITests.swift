import XCTest

/// Exercises the profile screen: the expiry-alerts toggle and the lead-days
/// stepper, including toggling alerts off and back on — all in one launch.
final class ProfileUITests: FoodMapUITestCase {
    func testAlertsToggleControlsLeadDaysStepper() {
        let app = launchApp()
        selectTab("tab.profile", label: "Profile", in: app)

        XCTAssertTrue(app.navigationBars["Profile"].waitForExistence(timeout: defaultTimeout))

        // The expiry-alerts toggle sits below the allergens section, so it can
        // render off-screen — scroll until it appears before asserting.
        let toggle = app.switches["profile.alertsToggle"]
        scrollToElement(toggle, in: app)
        XCTAssertTrue(toggle.waitForExistence(timeout: defaultTimeout), "Expiry-alerts toggle should be present")

        // Alerts default to on, so the lead-days stepper is visible initially.
        let stepper = app.steppers["profile.leadDaysStepper"]
        XCTAssertTrue(stepper.waitForExistence(timeout: defaultTimeout), "Lead-days stepper should be present")

        // Turn alerts off — the lead-days stepper should disappear. Tap the
        // switch control on the trailing edge of the row: tapping the row's
        // centre lands on empty space and does not flip a SwiftUI Toggle.
        let switchControl = toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5))
        switchControl.tap()
        XCTAssertTrue(
            waitForDisappearance(of: stepper, timeout: defaultTimeout),
            "Lead-days stepper should hide when alerts are off"
        )

        // Turn alerts back on — the stepper should reappear.
        switchControl.tap()
        XCTAssertTrue(
            stepper.waitForExistence(timeout: defaultTimeout),
            "Lead-days stepper should reappear when alerts are on"
        )
    }

    private func waitForDisappearance(of element: XCUIElement, timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }
}
