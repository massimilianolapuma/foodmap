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
    public let notificationScheduler: NotificationScheduler
    public let expiryDateParser: ExpiryDateParser
    public let expiryOCR: ExpiryOCRService
    public let barcodeScanner: BarcodeScannerService
    public let cameraPreviewProvider: CameraPreviewProviding

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
        mealPlanner = FoundationModelsMealPlanner(fallback: RuleBasedMealPlanner())
        notificationScheduler = LocalNotificationScheduler()
        let parser = ExpiryDateParser()
        expiryDateParser = parser
        expiryOCR = VisionExpiryOCRService(parser: parser)
        let scanner = AVBarcodeScannerService()
        barcodeScanner = scanner
        cameraPreviewProvider = scanner

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
