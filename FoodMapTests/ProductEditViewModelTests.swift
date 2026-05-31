import XCTest
@testable import FoodMap

@MainActor
final class ProductEditViewModelTests: XCTestCase {
    private func makeModel(
        product: Product,
        repository: InMemoryProductRepository
    ) -> ProductEditViewModel {
        ProductEditViewModel(
            product: product,
            update: UpdateProductUseCase(repository: repository),
            repository: repository
        )
    }

    func testInitPopulatesFieldsFromProduct() {
        let expiry = Date.make(year: 2026, month: 6, day: 1)
        let product = Product(
            name: "Yogurt",
            brand: "Acme",
            category: .dairy,
            storageLocation: .fridge,
            quantity: 3,
            unit: .piece,
            expiryDate: expiry
        )
        let model = makeModel(product: product, repository: InMemoryProductRepository())

        XCTAssertEqual(model.name, "Yogurt")
        XCTAssertEqual(model.brand, "Acme")
        XCTAssertEqual(model.category, .dairy)
        XCTAssertEqual(model.storageLocation, .fridge)
        XCTAssertEqual(model.quantity, 3)
        XCTAssertTrue(model.hasExpiry)
        XCTAssertEqual(model.expiryDate, expiry)
    }

    func testSavePersistsChangesThroughRepository() async throws {
        let product = Product(name: "Bread", storageLocation: .pantry, quantity: 1)
        let repository = InMemoryProductRepository()
        try await repository.add(product)
        let model = makeModel(product: product, repository: repository)

        model.name = "Sourdough"
        model.storageLocation = .freezer
        model.quantity = 2
        await model.save()

        XCTAssertEqual(model.outcome, .saved)
        let stored = try await repository.fetch(id: product.id)
        XCTAssertEqual(stored?.name, "Sourdough")
        XCTAssertEqual(stored?.storageLocation, .freezer)
        XCTAssertEqual(stored?.quantity, 2)
    }

    func testQuantityAdjustmentHelpersClampAtZero() {
        let product = Product(name: "Apples", quantity: 1)
        let model = makeModel(product: product, repository: InMemoryProductRepository())

        model.incrementQuantity()
        XCTAssertEqual(model.quantity, 2)
        model.decrementQuantity()
        model.decrementQuantity()
        model.decrementQuantity()
        XCTAssertEqual(model.quantity, 0)
    }

    func testCanSaveIsFalseForEmptyName() {
        let product = Product(name: "Apples")
        let model = makeModel(product: product, repository: InMemoryProductRepository())

        model.name = "   "
        XCTAssertFalse(model.canSave)
        model.name = "Apples"
        XCTAssertTrue(model.canSave)
    }

    func testDeleteRemovesProduct() async throws {
        let product = Product(name: "Carrots")
        let repository = InMemoryProductRepository()
        try await repository.add(product)
        let model = makeModel(product: product, repository: repository)

        await model.delete()

        XCTAssertEqual(model.outcome, .deleted)
        let stored = try await repository.fetch(id: product.id)
        XCTAssertNil(stored)
    }

    func testFreezerSuggestionOfferedWhenMovingPerishableToFreezer() {
        let product = Product(
            name: "Chicken",
            category: .meatFish,
            storageLocation: .fridge,
            quantity: 1,
            expiryDate: Date.make(year: 2026, month: 6, day: 1)
        )
        let model = makeModel(product: product, repository: InMemoryProductRepository())
        XCTAssertNil(model.freezerSuggestion)

        model.storageLocation = .freezer
        let suggestion = model.freezerSuggestion
        XCTAssertNotNil(suggestion)
        XCTAssertGreaterThan(suggestion?.suggestedExpiry ?? .distantPast, model.expiryDate)
    }

    func testApplyingFreezerSuggestionSetsEstimatedExpiry() {
        let product = Product(
            name: "Spinach",
            category: .fruitsVegetables,
            storageLocation: .freezer,
            quantity: 1
        )
        let model = makeModel(product: product, repository: InMemoryProductRepository())
        guard let suggestion = model.freezerSuggestion else {
            return XCTFail("Expected a freezer suggestion")
        }

        model.applyFreezerSuggestion()
        XCTAssertTrue(model.hasExpiry)
        XCTAssertEqual(model.expiryDate, suggestion.suggestedExpiry)
    }

    func testNoFreezerSuggestionForShelfStableCategory() {
        let product = Product(
            name: "Pasta",
            category: .pantryStaples,
            storageLocation: .freezer,
            quantity: 1
        )
        let model = makeModel(product: product, repository: InMemoryProductRepository())
        XCTAssertNil(model.freezerSuggestion)
    }

    func testSaveWithInvalidNameSurfacesFailure() async throws {
        let product = Product(name: "Carrots")
        let repository = InMemoryProductRepository()
        try await repository.add(product)
        let model = makeModel(product: product, repository: repository)

        model.name = "   "
        await model.save()

        guard case .failed = model.outcome else {
            return XCTFail("Expected failed outcome")
        }
        model.clearFailure()
        XCTAssertEqual(model.outcome, .none)
    }
}
