import XCTest
@testable import FoodMap

@MainActor
final class ScannerViewModelTests: XCTestCase {
    private func makeModel(
        lookup: FakeProductLookup,
        scanner: FakeBarcodeScanner,
        repository: InMemoryProductRepository = InMemoryProductRepository()
    ) -> ScannerViewModel {
        ScannerViewModel(
            lookup: lookup,
            addProduct: AddScannedProductToInventoryUseCase(repository: repository),
            scanner: scanner
        )
    }

    private func sampleProduct(barcode: String = "123") -> ProductLookupResult {
        ProductLookupResult(barcode: barcode, name: "Milk", brand: "Acme")
    }

    func testBeginScanCapturesBarcodeAndPresentsConfirmation() async {
        let scanner = FakeBarcodeScanner(codes: ["123"])
        let model = makeModel(lookup: FakeProductLookup(product: sampleProduct()), scanner: scanner)

        await model.beginScan()

        XCTAssertEqual(model.barcode, "123")
        XCTAssertEqual(model.pendingProduct?.name, "Milk")
        XCTAssertFalse(model.isScanning)
        XCTAssertEqual(scanner.stopCount, 1)
    }

    func testBeginScanWithDeniedPermissionSurfacesDeniedState() async {
        let scanner = FakeBarcodeScanner(codes: [])
        scanner.startError = .cameraPermissionDenied
        let model = makeModel(lookup: FakeProductLookup(product: sampleProduct()), scanner: scanner)

        await model.beginScan()

        XCTAssertTrue(model.permissionDenied)
        XCTAssertFalse(model.isScanning)
        XCTAssertNil(model.pendingProduct)
    }

    func testConfirmAddPersistsProductAndReportsFound() async throws {
        let repository = InMemoryProductRepository()
        let model = makeModel(
            lookup: FakeProductLookup(product: sampleProduct()),
            scanner: FakeBarcodeScanner(codes: ["123"]),
            repository: repository
        )

        model.barcode = "123"
        await model.lookupManual()
        XCTAssertNotNil(model.pendingProduct)

        await model.confirmAdd()

        XCTAssertEqual(model.state, .found(name: "Milk"))
        XCTAssertNil(model.pendingProduct)
        let stored = try await repository.fetchAll()
        XCTAssertEqual(stored.count, 1)
        XCTAssertEqual(stored.first?.name, "Milk")
    }

    func testLookupNotFoundFailsWithoutPendingProduct() async {
        let model = makeModel(
            lookup: FakeProductLookup(error: .productNotFound(barcode: "999")),
            scanner: FakeBarcodeScanner()
        )

        model.barcode = "999"
        await model.lookupManual()

        XCTAssertNil(model.pendingProduct)
        guard case .failed = model.state else {
            return XCTFail("Expected failed state")
        }
    }

    func testManualLookupRejectsEmptyBarcode() async {
        let model = makeModel(lookup: FakeProductLookup(product: sampleProduct()), scanner: FakeBarcodeScanner())

        model.barcode = "   "
        await model.lookupManual()

        guard case .failed = model.state else {
            return XCTFail("Expected failed state for empty barcode")
        }
        XCTAssertNil(model.pendingProduct)
    }

    func testCancelScanStopsScannerAndDismissesSheet() async {
        let scanner = FakeBarcodeScanner(codes: [])
        let model = makeModel(lookup: FakeProductLookup(product: sampleProduct()), scanner: scanner)
        model.isScanning = true

        await model.cancelScan()

        XCTAssertFalse(model.isScanning)
        XCTAssertEqual(scanner.stopCount, 1)
    }
}
