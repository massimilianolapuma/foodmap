import Foundation
import SwiftData

/// Composition root for dependency injection. Builds and owns the app's
/// repositories, services, and use cases. Avoids singletons; passed via the environment.
@MainActor
public final class AppContainer: ObservableObject {
    public let modelContainer: ModelContainer

    // Services
    public let productLookup: ProductLookupService
    public let mealPlanner: MealPlannerAIService
    public let mealPlannerModelStore: MealPlannerModelStore
    public let notificationScheduler: NotificationScheduler
    public let expiryDateParser: ExpiryDateParser
    public let expiryOCR: ExpiryOCRService
    public let barcodeScanner: BarcodeScannerService
    public let cameraPreviewProvider: CameraPreviewProviding
    public let authService: AuthenticationService
    let authViewModel: AuthViewModel

    // Repositories
    public let productRepository: ProductRepository
    public let inventoryRepository: InventoryRepository
    public let userProfileRepository: UserProfileRepository
    public let mealPlanRepository: MealPlanRepository
    public let shoppingListRepository: ShoppingListRepository

    // Use cases
    public let expiryCalculator: CalculateExpiryStatusUseCase
    public let getExpiringProducts: GetExpiringProductsUseCase
    public let addScannedProduct: AddScannedProductToInventoryUseCase
    public let updateProduct: UpdateProductUseCase
    public let generateShoppingList: GenerateShoppingListFromMealPlanUseCase
    public let syncExpiryAlerts: SyncExpiryAlertsUseCase

    public init(inMemory: Bool = false) {
        // Persistence
        let container: ModelContainer
        do {
            container = try PersistenceController.makeContainer(inMemory: inMemory)
        } catch {
            fatalError("Failed to initialize persistence: \(error)")
        }
        modelContainer = container

        // Repositories (SwiftData-backed actors)
        let productRepo = SwiftDataProductRepository(modelContainer: container)
        let appRepo = SwiftDataAppRepository(modelContainer: container)
        productRepository = productRepo
        inventoryRepository = productRepo
        userProfileRepository = appRepo
        mealPlanRepository = appRepo
        shoppingListRepository = appRepo

        // Services
        productLookup = OpenFoodFactsService()
        // On-device AI when available (iOS 26+); deterministic rule-based fallback otherwise.
        // Under UI testing, use the deterministic rule-based planner directly so the app
        // never spins up the on-device model subsystem (which keeps the app from reaching
        // an idle state the automation can drive).
        let modelStore = UserDefaultsMealPlannerModelStore()
        mealPlannerModelStore = modelStore
        if Self.isUITesting {
            mealPlanner = RuleBasedMealPlanner()
        } else {
            let ruleBased = RuleBasedMealPlanner()
            mealPlanner = RoutingMealPlanner(
                store: modelStore,
                ruleBased: ruleBased,
                onDevice: FoundationModelsMealPlanner(fallback: ruleBased)
            )
        }
        notificationScheduler = LocalNotificationScheduler()
        let parser = ExpiryDateParser()
        expiryDateParser = parser
        expiryOCR = VisionExpiryOCRService(parser: parser)
        let scanner = AVBarcodeScannerService()
        barcodeScanner = scanner
        cameraPreviewProvider = scanner

        // Authentication. Under UI testing, start pre-authenticated with a local
        // anonymous session so end-to-end flows reach the tab interface without
        // driving the system Sign in with Apple sheet. Otherwise persist the
        // session in the Keychain.
        let credentialStore: CredentialStore = Self.isUITesting
            ? InMemoryCredentialStore(seed: .anonymous)
            : KeychainCredentialStore()
        authService = AppleAuthenticationService(store: credentialStore)
        authViewModel = AuthViewModel(service: authService)

        // Use cases
        let calculator = CalculateExpiryStatusUseCase()
        expiryCalculator = calculator
        getExpiringProducts = GetExpiringProductsUseCase(inventory: productRepo, expiryCalculator: calculator)
        addScannedProduct = AddScannedProductToInventoryUseCase(repository: productRepo)
        updateProduct = UpdateProductUseCase(repository: productRepo)
        generateShoppingList = GenerateShoppingListFromMealPlanUseCase()
        syncExpiryAlerts = SyncExpiryAlertsUseCase(scheduler: notificationScheduler, products: productRepo)
    }
}

public extension AppContainer {
    /// True when the app is launched by the XCUITest suite with the `-uiTesting` argument.
    /// Used to start from a deterministic, in-memory state so UI tests are repeatable.
    static var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("-uiTesting")
    }

    /// Seeds a small, deterministic dataset for UI testing. No-op unless launched
    /// with `-uiTesting`. Inserts a couple of pantry products so the inventory and
    /// dashboard screens render real content (and their filters) during E2E runs.
    @MainActor
    func seedUITestDataIfNeeded() {
        guard Self.isUITesting else { return }
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<Product>()
        if let existing = try? context.fetch(descriptor), !existing.isEmpty { return }

        let calendar = Calendar.current
        let soon = calendar.date(byAdding: .day, value: 2, to: .now)
        let later = calendar.date(byAdding: .day, value: 5, to: .now)

        context.insert(Product(
            name: "Milk",
            brand: "Seed Dairy",
            storageLocation: .fridge,
            quantity: 1,
            unit: .liter,
            expiryDate: soon
        ))
        context.insert(Product(
            name: "Pasta",
            brand: "Seed Foods",
            storageLocation: .pantry,
            quantity: 2,
            unit: .piece,
            expiryDate: later
        ))
        try? context.save()
    }
}
