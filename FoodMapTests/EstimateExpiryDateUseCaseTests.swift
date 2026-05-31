import XCTest
@testable import FoodMap

final class EstimateExpiryDateUseCaseTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)
    private lazy var reference: Date = {
        var components = DateComponents()
        components.year = 2026
        components.month = 5
        components.day = 1
        return calendar.date(from: components)!
    }()

    private func makeUseCase() -> EstimateExpiryDateUseCase {
        EstimateExpiryDateUseCase(calendar: calendar)
    }

    private func days(from start: Date, to end: Date) -> Int {
        calendar.dateComponents([.day], from: start, to: end).day ?? -1
    }

    func testFreshMeatInFridgeGetsShortEstimate() throws {
        let estimate = makeUseCase()(
            category: .meatFish,
            storageLocation: .fridge,
            from: reference
        )
        let unwrapped = try XCTUnwrap(estimate)
        XCTAssertEqual(days(from: reference, to: unwrapped), 2)
    }

    func testFruitInFreezerGetsLongEstimate() throws {
        let estimate = makeUseCase()(
            category: .fruitsVegetables,
            storageLocation: .freezer,
            from: reference
        )
        let unwrapped = try XCTUnwrap(estimate)
        XCTAssertEqual(days(from: reference, to: unwrapped), 240)
    }

    func testStorageLocationChangesEstimate() throws {
        let useCase = makeUseCase()
        let fridge = useCase(category: .fruitsVegetables, storageLocation: .fridge, from: reference)
        let pantry = useCase(category: .fruitsVegetables, storageLocation: .pantry, from: reference)
        XCTAssertEqual(try days(from: reference, to: XCTUnwrap(fridge)), 7)
        XCTAssertEqual(try days(from: reference, to: XCTUnwrap(pantry)), 5)
    }

    func testShelfStableCategoriesReturnNil() {
        let useCase = makeUseCase()
        for category in [ProductCategory.pantryStaples, .beverages, .snacks, .condiments, .frozen, .other] {
            XCTAssertNil(
                useCase(category: category, storageLocation: .pantry, from: reference),
                "\(category) should not be estimated"
            )
        }
    }
}
