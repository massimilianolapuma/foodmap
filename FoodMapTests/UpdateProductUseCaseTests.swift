import XCTest
@testable import FoodMap

final class UpdateProductUseCaseTests: XCTestCase {
    private func makeRepository(seed product: Product) async throws -> InMemoryProductRepository {
        let repository = InMemoryProductRepository()
        try await repository.add(product)
        return repository
    }

    func testUpdatePersistsRenamedFields() async throws {
        let product = Product(name: "Milk", brand: "Acme", quantity: 1, unit: .liter)
        let repository = try await makeRepository(seed: product)
        let useCase = UpdateProductUseCase(repository: repository)

        let edits = ProductEdits(
            name: "Whole Milk",
            brand: "Dairy Co",
            category: .dairy,
            storageLocation: .fridge,
            quantity: 2,
            unit: .liter,
            expiryDate: nil
        )
        try await useCase(id: product.id, edits: edits)

        let stored = try await repository.fetch(id: product.id)
        XCTAssertEqual(stored?.name, "Whole Milk")
        XCTAssertEqual(stored?.brand, "Dairy Co")
        XCTAssertEqual(stored?.category, .dairy)
        XCTAssertEqual(stored?.quantity, 2)
    }

    func testMoveUpdatesStorageLocation() async throws {
        let product = Product(name: "Peas", storageLocation: .pantry)
        let repository = try await makeRepository(seed: product)
        let useCase = UpdateProductUseCase(repository: repository)

        let edits = ProductEdits(
            name: "Peas",
            brand: nil,
            category: .frozen,
            storageLocation: .freezer,
            quantity: 1,
            unit: .pack,
            expiryDate: nil
        )
        try await useCase(id: product.id, edits: edits)

        let stored = try await repository.fetch(id: product.id)
        XCTAssertEqual(stored?.storageLocation, .freezer)
    }

    func testEmptyNameThrowsInvalidInput() async throws {
        let product = Product(name: "Eggs")
        let repository = try await makeRepository(seed: product)
        let useCase = UpdateProductUseCase(repository: repository)

        let edits = ProductEdits(
            name: "   ",
            brand: nil,
            category: .other,
            storageLocation: .fridge,
            quantity: 1,
            unit: .piece
        )

        await assertThrowsInvalidInput {
            try await useCase(id: product.id, edits: edits)
        }
    }

    func testNegativeQuantityThrowsInvalidInput() async throws {
        let product = Product(name: "Eggs")
        let repository = try await makeRepository(seed: product)
        let useCase = UpdateProductUseCase(repository: repository)

        let edits = ProductEdits(
            name: "Eggs",
            brand: nil,
            category: .other,
            storageLocation: .fridge,
            quantity: -1,
            unit: .piece
        )

        await assertThrowsInvalidInput {
            try await useCase(id: product.id, edits: edits)
        }
    }

    func testImageDataIsPersisted() async throws {
        let product = Product(name: "Eggs")
        let repository = try await makeRepository(seed: product)
        let useCase = UpdateProductUseCase(repository: repository)

        let photo = Data([0x01, 0x02, 0x03])
        let edits = ProductEdits(
            name: "Eggs",
            brand: nil,
            category: .other,
            storageLocation: .fridge,
            quantity: 1,
            unit: .piece,
            imageData: photo
        )
        try await useCase(id: product.id, edits: edits)

        let stored = try await repository.fetch(id: product.id)
        XCTAssertEqual(stored?.imageData, photo)
    }

    func testImageDataIsClearedWhenNil() async throws {
        let product = Product(name: "Eggs", imageData: Data([0xAA, 0xBB]))
        let repository = try await makeRepository(seed: product)
        let useCase = UpdateProductUseCase(repository: repository)

        let edits = ProductEdits(
            name: "Eggs",
            brand: nil,
            category: .other,
            storageLocation: .fridge,
            quantity: 1,
            unit: .piece,
            imageData: nil
        )
        try await useCase(id: product.id, edits: edits)

        let stored = try await repository.fetch(id: product.id)
        XCTAssertNil(stored?.imageData)
    }

    func testBlankBrandIsClearedToNil() async throws {
        let product = Product(name: "Eggs", brand: "Acme")
        let repository = try await makeRepository(seed: product)
        let useCase = UpdateProductUseCase(repository: repository)

        let edits = ProductEdits(
            name: "Eggs",
            brand: "   ",
            category: .other,
            storageLocation: .fridge,
            quantity: 1,
            unit: .piece
        )
        try await useCase(id: product.id, edits: edits)

        let stored = try await repository.fetch(id: product.id)
        XCTAssertNil(stored?.brand)
    }

    func testChangingExpiryDateClearsEstimatedFlag() async throws {
        let estimated = Date(timeIntervalSince1970: 1_700_000_000)
        let product = Product(name: "Beef", expiryDate: estimated, expiryIsEstimated: true)
        let repository = try await makeRepository(seed: product)
        let useCase = UpdateProductUseCase(repository: repository)

        let edits = ProductEdits(
            name: "Beef",
            brand: nil,
            category: .meatFish,
            storageLocation: .fridge,
            quantity: 1,
            unit: .piece,
            expiryDate: Date(timeIntervalSince1970: 1_700_500_000)
        )
        try await useCase(id: product.id, edits: edits)

        let stored = try await repository.fetch(id: product.id)
        XCTAssertFalse(stored?.expiryIsEstimated ?? true)
    }

    func testUnchangedExpiryDateKeepsEstimatedFlag() async throws {
        let estimated = Date(timeIntervalSince1970: 1_700_000_000)
        let product = Product(name: "Beef", expiryDate: estimated, expiryIsEstimated: true)
        let repository = try await makeRepository(seed: product)
        let useCase = UpdateProductUseCase(repository: repository)

        let edits = ProductEdits(
            name: "Beef Steak",
            brand: nil,
            category: .meatFish,
            storageLocation: .fridge,
            quantity: 2,
            unit: .piece,
            expiryDate: estimated
        )
        try await useCase(id: product.id, edits: edits)

        let stored = try await repository.fetch(id: product.id)
        XCTAssertTrue(stored?.expiryIsEstimated ?? false)
    }

    private func assertThrowsInvalidInput(
        _ body: () async throws -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            try await body()
            XCTFail("Expected invalidInput error", file: file, line: line)
        } catch let FoodMapError.invalidInput(reason) {
            XCTAssertFalse(reason.isEmpty, file: file, line: line)
        } catch {
            XCTFail("Expected invalidInput, got \(error)", file: file, line: line)
        }
    }
}
