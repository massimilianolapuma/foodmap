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

    /// Produces up to `count` alternative recipes that could stand in for `meal`,
    /// keeping the same meal slot and day while still prioritizing expiring products.
    func alternatives(
        for meal: Meal,
        from products: [Product],
        profile: UserProfile,
        count: Int
    ) async throws -> [Meal]
}

public extension MealPlannerAIService {
    /// Default: no alternatives. Concrete planners override to offer real choices.
    func alternatives(
        for _: Meal,
        from _: [Product],
        profile _: UserProfile,
        count _: Int
    ) async throws -> [Meal] {
        []
    }
}

/// Persists the user's preferred meal-planner engine and reports which engines
/// the current device can actually run.
public protocol MealPlannerModelStore: Sendable {
    /// The engine the user selected. Defaults to ``MealPlannerModel/automatic``.
    func selectedModel() -> MealPlannerModel
    /// Persists the user's engine choice.
    func select(_ model: MealPlannerModel)
    /// Whether the on-device FoundationModels engine is ready on this device.
    func isOnDeviceModelAvailable() -> Bool
}

public extension MealPlannerModelStore {
    /// Engines the user can actually choose on this device, hiding the on-device
    /// option when it cannot run.
    func availableModels() -> [MealPlannerModel] {
        MealPlannerModel.allCases.filter { model in
            model != .onDevice || isOnDeviceModelAvailable()
        }
    }
}
