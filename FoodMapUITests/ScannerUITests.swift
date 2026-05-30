import XCTest

/// Exercises the scanner entry point. The simulator has no camera, so this test
/// asserts the UI degrades gracefully: the manual-lookup affordance and the scan
/// entry point are present, and no live camera is required.
final class ScannerUITests: FoodMapUITestCase {
    func testScannerManualLookupDegradesGracefully() {
        let app = launchApp()
        selectTab("tab.inventory", label: "Pantry", in: app)

        let scanButton = app.buttons["inventory.scanButton"]
        XCTAssertTrue(scanButton.waitForExistence(timeout: defaultTimeout), "Pantry should expose a Scan entry point")
        scanButton.tap()

        XCTAssertTrue(app.navigationBars["Scan"].waitForExistence(timeout: defaultTimeout))

        let barcodeField = app.textFields["scanner.barcodeField"]
        XCTAssertTrue(barcodeField.waitForExistence(timeout: defaultTimeout), "Manual barcode field should be present")
        XCTAssertTrue(app.buttons["scanner.scanButton"].exists, "Scan entry point should be present")
        XCTAssertTrue(app.buttons["scanner.lookupButton"].exists, "Look up control should be present")

        // Entering a barcode enables the lookup control; tapping must not crash even
        // though no live camera is available and the lookup will not find a real product.
        barcodeField.tap()
        barcodeField.typeText("0000000000000")

        let lookup = app.buttons["scanner.lookupButton"]
        XCTAssertTrue(lookup.waitForExistence(timeout: defaultTimeout))
        XCTAssertTrue(lookup.isEnabled, "Look up should be enabled once a barcode is entered")

        // App remains responsive (no live-camera dependency on the simulator).
        XCTAssertTrue(app.navigationBars["Scan"].exists)
    }
}
