import Foundation
@testable import FoodMap

/// Emits a predetermined list of barcodes and records lifecycle calls.
final class FakeBarcodeScanner: BarcodeScannerService, @unchecked Sendable {
    var codes: [String]
    var startError: FoodMapError?
    private(set) var startCount = 0
    private(set) var stopCount = 0

    init(codes: [String] = []) {
        self.codes = codes
    }

    func scannedBarcodes() -> AsyncStream<String> {
        let codes = codes
        return AsyncStream { continuation in
            for code in codes {
                continuation.yield(code)
            }
            continuation.finish()
        }
    }

    func start() async throws {
        startCount += 1
        if let startError { throw startError }
    }

    func stop() async {
        stopCount += 1
    }
}

/// Returns a fixed product or throws a fixed error for any barcode.
struct FakeProductLookup: ProductLookupService {
    var product: ProductLookupResult?
    var error: FoodMapError?

    func fetchProduct(by barcode: String) async throws -> ProductLookupResult {
        if let error { throw error }
        if let product { return product }
        throw FoodMapError.productNotFound(barcode: barcode)
    }
}

/// Returns a fixed list of candidate dates or throws a fixed error for any image.
struct FakeExpiryOCR: ExpiryOCRService {
    var dates: [Date] = []
    var error: FoodMapError?

    func recognizeExpiryDates(in imageData: Data) async throws -> [Date] {
        if let error { throw error }
        return dates
    }
}

/// Records scheduling/cancellation calls for verifying alert sync behavior.
final class FakeNotificationScheduler: NotificationScheduler, @unchecked Sendable {
    var authorizationGranted = true
    var authorizationError: FoodMapError?
    private(set) var requestAuthorizationCount = 0
    private(set) var scheduled: [(id: UUID, leadDays: Int)] = []
    private(set) var cancelled: [UUID] = []
    private(set) var cancelAllCount = 0

    var scheduledIDs: [UUID] {
        scheduled.map(\.id)
    }

    func requestAuthorization() async throws -> Bool {
        requestAuthorizationCount += 1
        if let authorizationError { throw authorizationError }
        return authorizationGranted
    }

    func scheduleExpiryAlert(for product: Product, leadDays: Int) async throws {
        scheduled.append((product.id, leadDays))
    }

    func cancelAlert(for productID: UUID) async {
        cancelled.append(productID)
    }

    func cancelAll() async {
        cancelAllCount += 1
    }
}

/// Minimal in-memory `ProductRepository` for exercising use cases in tests.
final class InMemoryProductRepository: ProductRepository, @unchecked Sendable {
    private var products: [UUID: Product] = [:]

    func add(_ product: Product) async throws {
        products[product.id] = product
    }

    func update(_ product: Product) async throws {
        products[product.id] = product
    }

    func delete(id: UUID) async throws {
        products[id] = nil
    }

    func fetchAll() async throws -> [Product] {
        Array(products.values)
    }

    func fetch(id: UUID) async throws -> Product? {
        products[id]
    }

    func fetch(byBarcode barcode: String) async throws -> Product? {
        products.values.first { $0.barcode == barcode }
    }

    func fetch(in location: StorageLocation) async throws -> [Product] {
        products.values.filter { $0.storageLocation == location }
    }
}
