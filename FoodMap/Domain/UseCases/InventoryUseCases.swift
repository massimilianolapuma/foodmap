import Foundation

/// Returns products expiring within a window, sorted by urgency (most urgent first).
public struct GetExpiringProductsUseCase: Sendable {
    private let inventory: InventoryRepository
    private let expiryCalculator: CalculateExpiryStatusUseCase

    public init(inventory: InventoryRepository, expiryCalculator: CalculateExpiryStatusUseCase = .init()) {
        self.inventory = inventory
        self.expiryCalculator = expiryCalculator
    }

    public func callAsFunction(within days: Int = 7) async throws -> [Product] {
        let products = try await inventory.expiringProducts(within: days)
        return products.sorted { lhs, rhs in
            expiryCalculator.priorityScore(for: lhs) > expiryCalculator.priorityScore(for: rhs)
        }
    }
}

/// Adds a scanned-and-looked-up product to the pantry, merging with an existing
/// entry that shares the same barcode and storage location when present.
public struct AddScannedProductToInventoryUseCase: Sendable {
    private let repository: ProductRepository
    private let estimateExpiry: EstimateExpiryDateUseCase

    public init(repository: ProductRepository, estimateExpiry: EstimateExpiryDateUseCase = .init()) {
        self.repository = repository
        self.estimateExpiry = estimateExpiry
    }

    public func callAsFunction(
        lookup: ProductLookupResult,
        storageLocation: StorageLocation,
        quantity: Double,
        unit: MeasurementUnit,
        expiryDate: Date?,
        imageData: Data? = nil
    ) async throws {
        var resolvedExpiry = expiryDate
        var expiryIsEstimated = false
        if resolvedExpiry == nil,
           let estimate = estimateExpiry(
               category: lookup.category,
               storageLocation: storageLocation
           ) {
            resolvedExpiry = estimate
            expiryIsEstimated = true
        }

        if let existing = try await repository.fetch(byBarcode: lookup.barcode),
           existing.storageLocation == storageLocation,
           existing.expiryDate == resolvedExpiry {
            existing.quantity += quantity
            if existing.imageData == nil, let imageData {
                existing.imageData = imageData
            }
            try await repository.update(existing)
            return
        }

        let nutrition = lookup.nutrition.map {
            NutritionInfo(
                energyKcal: $0.energyKcal,
                proteinGrams: $0.proteinGrams,
                carbohydrateGrams: $0.carbohydrateGrams,
                fatGrams: $0.fatGrams,
                sugarGrams: $0.sugarGrams,
                saltGrams: $0.saltGrams
            )
        }

        let product = Product(
            barcode: lookup.barcode,
            name: lookup.name,
            brand: lookup.brand,
            category: lookup.category,
            storageLocation: storageLocation,
            quantity: quantity,
            unit: unit,
            imageURLString: lookup.imageURLString,
            imageData: imageData,
            expiryDate: resolvedExpiry,
            expiryIsEstimated: expiryIsEstimated,
            source: lookup.source,
            allergens: lookup.allergens,
            nutrition: nutrition
        )
        try await repository.add(product)
    }
}
