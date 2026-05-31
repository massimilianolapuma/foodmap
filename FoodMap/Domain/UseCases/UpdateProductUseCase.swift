import Foundation

/// The editable fields of a pantry product. Pure value type used to carry
/// validated edits from the Presentation layer into the Domain.
public struct ProductEdits: Sendable, Equatable {
    public var name: String
    public var brand: String?
    public var category: ProductCategory
    public var storageLocation: StorageLocation
    public var quantity: Double
    public var unit: MeasurementUnit
    public var expiryDate: Date?
    /// User-captured product photo (JPEG) or `nil` to leave unset / remove. On-device only.
    public var imageData: Data?

    public init(
        name: String,
        brand: String? = nil,
        category: ProductCategory,
        storageLocation: StorageLocation,
        quantity: Double,
        unit: MeasurementUnit,
        expiryDate: Date? = nil,
        imageData: Data? = nil
    ) {
        self.name = name
        self.brand = brand
        self.category = category
        self.storageLocation = storageLocation
        self.quantity = quantity
        self.unit = unit
        self.expiryDate = expiryDate
        self.imageData = imageData
    }
}

/// Applies edits to an existing product — rename, move (change storage location),
/// adjust quantity/unit, change category, and set/clear the expiry date.
/// Validates input at the boundary before persisting.
public struct UpdateProductUseCase: Sendable {
    private let repository: ProductRepository

    public init(repository: ProductRepository) {
        self.repository = repository
    }

    public func callAsFunction(id: UUID, edits: ProductEdits) async throws {
        let trimmedName = edits.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw FoodMapError.invalidInput(reason: "Name can't be empty.")
        }
        guard edits.quantity >= 0 else {
            throw FoodMapError.invalidInput(reason: "Quantity can't be negative.")
        }
        guard let product = try await repository.fetch(id: id) else {
            throw FoodMapError.persistence(reason: "This product no longer exists.")
        }

        let trimmedBrand = edits.brand?.trimmingCharacters(in: .whitespacesAndNewlines)
        product.name = trimmedName
        product.brand = (trimmedBrand?.isEmpty == false) ? trimmedBrand : nil
        product.category = edits.category
        product.storageLocation = edits.storageLocation
        product.quantity = edits.quantity
        product.unit = edits.unit
        product.expiryDate = edits.expiryDate
        product.imageData = edits.imageData

        try await repository.update(product)
    }
}
