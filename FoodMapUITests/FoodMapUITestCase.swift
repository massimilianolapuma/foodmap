import XCTest

/// Base class for FoodMap end-to-end UI tests.
///
/// Each test launches a fresh `XCUIApplication` with the `-uiTesting` argument so
/// the app boots from a deterministic, in-memory SwiftData store seeded with a
/// small sample dataset. Tests are independent and make no assumptions about
/// state left behind by other tests.
class FoodMapUITestCase: XCTestCase {
    /// Default wait used for asynchronous SwiftUI content to appear.
    let defaultTimeout: TimeInterval = 10

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    /// Launches the app in UI-testing mode and returns the running application.
    @discardableResult
    func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-uiTesting"]
        app.launch()
        XCTAssertTrue(
            app.wait(for: .runningForeground, timeout: defaultTimeout),
            "App did not reach the foreground"
        )
        return app
    }

    /// Selects a tab by its accessibility identifier, falling back to its label.
    ///
    /// On iPhone a `TabView` with more than five tabs collapses the extra tabs
    /// into the system **More** tab, so this helper also looks there before
    /// failing — keeping the tests robust against tab-bar overflow.
    func selectTab(_ identifier: String, label: String, in app: XCUIApplication) {
        // SwiftUI does not always forward a tab content's identifier to its
        // tab-bar button, so probe the identifier briefly, then the label.
        let byIdentifier = app.tabBars.buttons[identifier]
        if byIdentifier.waitForExistence(timeout: 2) {
            byIdentifier.tap()
            return
        }
        let byLabel = app.tabBars.buttons[label]
        if byLabel.waitForExistence(timeout: 2) {
            byLabel.tap()
            return
        }
        // The tab overflowed into the system "More" tab.
        let more = app.tabBars.buttons["More"]
        if more.waitForExistence(timeout: defaultTimeout) {
            more.tap()
            // The More tab remembers its last selection, so it may already be
            // showing the target screen (its nav-bar title matches the label).
            if app.navigationBars[label].waitForExistence(timeout: 2) {
                return
            }
            let cell = app.cells.staticTexts[label].firstMatch
            XCTAssertTrue(
                cell.waitForExistence(timeout: defaultTimeout),
                "Tab \(identifier)/\(label) not found under the More tab"
            )
            cell.tap()
            return
        }
        XCTFail("Tab \(identifier)/\(label) not found")
    }

    /// Scrolls the app upward until `element` is present in the hierarchy, which is
    /// needed for rows that render lazily below the fold in long SwiftUI forms —
    /// especially when a screen is nested inside the system "More" navigation.
    @discardableResult
    func scrollToElement(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int = 8) -> Bool {
        var swipes = 0
        while !element.exists, swipes < maxSwipes {
            app.swipeUp()
            swipes += 1
        }
        return element.exists
    }
}
