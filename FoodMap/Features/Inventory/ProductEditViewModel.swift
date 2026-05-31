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

    init(product: Product, update: UpdateProductUseCase, repository: ProductRepository) {
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
    }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && quantity >= 0
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
