import Foundation

/// Drives the product edit screen: holds editable fields, validates them, and
/// persists changes (edit / move / quantity) or deletes through Domain protocols.
@MainActor
final class ProductEditViewModel: ObservableObject {
    enum Outcome: Equatable {
        case none
        case saved
        case deleted
        case failed(String)
    }

    @Published var name: String
    @Published var brand: String
    @Published var category: ProductCategory
    @Published var storageLocation: StorageLocation
    @Published var quantity: Double
    @Published var unit: MeasurementUnit
    @Published var hasExpiry: Bool
    @Published var expiryDate: Date
    @Published var imageData: Data?
    @Published private(set) var outcome: Outcome = .none
    @Published private(set) var isBusy = false

    private let productID: UUID
    private let update: UpdateProductUseCase
    private let repository: ProductRepository
    private let estimateExpiry: EstimateExpiryDateUseCase

    init(
        product: Product,
        update: UpdateProductUseCase,
        repository: ProductRepository,
        estimateExpiry: EstimateExpiryDateUseCase = .init()
    ) {
        productID = product.id
        name = product.name
        brand = product.brand ?? ""
        category = product.category
        storageLocation = product.storageLocation
        quantity = product.quantity
        unit = product.unit
        hasExpiry = product.expiryDate != nil
        expiryDate = product.expiryDate ?? Date()
        imageData = product.imageData
        self.update = update
        self.repository = repository
        self.estimateExpiry = estimateExpiry
    }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && quantity >= 0
    }

    /// A suggested, longer use-by date offered when an item is moved to the
    /// freezer. Surfaced only when freezing would meaningfully extend the
    /// current expiry, so the user can opt in. Advisory only — no food-safety
    /// guarantees are made.
    struct FreezerSuggestion: Equatable {
        let suggestedExpiry: Date
        let advice: String
    }

    /// Non-nil when the product is stored in the freezer, its category has a
    /// known freezer shelf life, and that estimate is later than the current
    /// expiry (or no expiry is set).
    var freezerSuggestion: FreezerSuggestion? {
        guard storageLocation == .freezer else { return nil }
        guard let estimate = estimateExpiry(category: category, storageLocation: .freezer) else {
            return nil
        }
        if hasExpiry, expiryDate >= estimate { return nil }
        let advice = String(localized: "Freezing pauses spoilage. We've estimated a freezer use-by date for this category.")
            + " "
            + String(localized: "Freeze items while still fresh and label them with today's date.")
        return FreezerSuggestion(suggestedExpiry: estimate, advice: advice)
    }

    /// Applies the freezer suggestion, marking the product as having an
    /// estimated expiry far enough out to reflect frozen storage.
    func applyFreezerSuggestion() {
        guard let suggestion = freezerSuggestion else { return }
        hasExpiry = true
        expiryDate = suggestion.suggestedExpiry
    }

    func incrementQuantity(by step: Double = 1) {
        quantity += step
    }

    func decrementQuantity(by step: Double = 1) {
        quantity = max(0, quantity - step)
    }

    func save() async {
        isBusy = true
        defer { isBusy = false }
        let edits = ProductEdits(
            name: name,
            brand: brand,
            category: category,
            storageLocation: storageLocation,
            quantity: quantity,
            unit: unit,
            expiryDate: hasExpiry ? expiryDate : nil,
            imageData: imageData
        )
        do {
            try await update(id: productID, edits: edits)
            outcome = .saved
        } catch let error as FoodMapError {
            outcome = .failed(error.errorDescription ?? "Couldn't save changes.")
        } catch {
            outcome = .failed(error.localizedDescription)
        }
    }

    func delete() async {
        isBusy = true
        defer { isBusy = false }
        do {
            try await repository.delete(id: productID)
            outcome = .deleted
        } catch let error as FoodMapError {
            outcome = .failed(error.errorDescription ?? "Couldn't delete the product.")
        } catch {
            outcome = .failed(error.localizedDescription)
        }
    }

    func clearFailure() {
        if case .failed = outcome {
            outcome = .none
        }
    }
}
