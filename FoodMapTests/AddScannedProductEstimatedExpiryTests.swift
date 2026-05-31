import XCTest
@testable import FoodMap

final class AddScannedProductEstimatedExpiryTests: XCTestCase {
    private func makeLookup(category: ProductCategory) -> ProductLookupResult {
        ProductLookupResult(
            barcode: "1234567890123",
            name: "Fresh Item",
            category: category,
            source: .openFoodFacts
        )
    }

    func testPerishableWithoutExpiryGetsEstimate() async throws {
        let repository = InMemoryProductRepository()
        let useCase = AddScannedProductToInventoryUseCase(repository: repository)

        try await useCase(
            lookup: makeLookup(category: .meatFish),
            storageLocation: .fridge,
            quantity: 1,
            unit: .piece,
            expiryDate: nil
        )

        let stored = try await repository.fetchAll()
        let product = try XCTUnwrap(stored.first)
        XCTAssertTrue(product.expiryIsEstimated)
        XCTAssertNotNil(product.expiryDate)
    }

    func testExplicitExpiryIsNotEstimated() async throws {
        let repository = InMemoryProductRepository()
        let useCase = AddScannedProductToInventoryUseCase(repository: repository)
        let explicit = Date(timeIntervalSince1970: 2_000_000_000)

        try await useCase(
            lookup: makeLookup(category: .meatFish),
            storageLocation: .fridge,
            quantity: 1,
            unit: .piece,
            expiryDate: explicit
        )

        let stored = try await repository.fetchAll()
        let product = try XCTUnwrap(stored.first)
        XCTAssertFalse(product.expiryIsEstimated)
        XCTAssertEqual(product.expiryDate, explicit)
    }

    func testShelfStableWithoutExpiryStaysNil() async throws {
        let repository = InMemoryProductRepository()
        let useCase = AddScannedProductToInventoryUseCase(repository: repository)

        try await useCase(
            lookup: makeLookup(category: .pantryStaples),
            storageLocation: .pantry,
            quantity: 1,
            unit: .piece,
            expiryDate: nil
        )

        let stored = try await repository.fetchAll()
        let product = try XCTUnwrap(stored.first)
        XCTAssertFalse(product.expiryIsEstimated)
        XCTAssertNil(product.expiryDate)
    }
}
