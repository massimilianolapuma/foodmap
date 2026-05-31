import Foundation

/// Looks up product metadata by barcode from an external provider (e.g. Open Food Facts).
public protocol ProductLookupService: Sendable {
    func fetchProduct(by barcode: String) async throws -> ProductLookupResult
}

/// Uploads a user-contributed product to an external database (e.g. Open Food Facts).
///
/// Contributing is opt-in and uses the user's own account credentials. Only
/// public product metadata is sent — never the user's sensitive data.
public protocol ProductContributionService: Sendable {
    func contribute(
        _ contribution: ProductContribution,
        using credentials: OpenFoodFactsCredentials
    ) async throws
}

/// Recognizes an expiry date from an image using on-device OCR.
public protocol ExpiryOCRService: Sendable {
    /// Returns candidate dates parsed from the recognized text, most-likely first.
    func recognizeExpiryDates(in imageData: Data) async throws -> [Date]
}

/// A continuous stream of scanned barcodes from the camera.
public protocol BarcodeScannerService: Sendable {
    /// Emits unique barcode strings as they are detected.
    func scannedBarcodes() -> AsyncStream<String>
    func start() async throws
    func stop() async
}

/// Schedules and cancels local expiry notifications.
public protocol NotificationScheduler: Sendable {
    func requestAuthorization() async throws -> Bool
    func scheduleExpiryAlert(for product: Product, leadDays: Int) async throws
    func cancelAlert(for productID: UUID) async
    func cancelAll() async
}

/// Generates a meal plan from available products and the user's profile.
/// Implemented by a deterministic rule-based engine and, optionally, an AI adapter.
public protocol MealPlannerAIService: Sendable {
    func generatePlan(
        from products: [Product],
        profile: UserProfile,
        planType: MealPlanType
    ) async throws -> MealPlan
}
