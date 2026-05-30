import XCTest
@testable import FoodMap

@MainActor
final class ShoppingListViewModelTests: XCTestCase {
    func testAddManualItemValidatesEmptyName() async {
        let repo = InMemoryShoppingListRepository()
        let model = ShoppingListViewModel(repository: repo)
        model.newName = "   "
        model.newQuantity = 2

        let added = await model.addManualItem()

        XCTAssertFalse(added)
        XCTAssertEqual(repo.addCount, 0)
        XCTAssertNotNil(model.errorMessage)
    }

    func testAddManualItemValidatesNonPositiveQuantity() async {
        let repo = InMemoryShoppingListRepository()
        let model = ShoppingListViewModel(repository: repo)
        model.newName = "Apples"
        model.newQuantity = 0

        let added = await model.addManualItem()

        XCTAssertFalse(added)
        XCTAssertEqual(repo.addCount, 0)
        XCTAssertNotNil(model.errorMessage)
    }

    func testAddManualItemPersistsAndResetsForm() async {
        let repo = InMemoryShoppingListRepository()
        let model = ShoppingListViewModel(repository: repo)
        model.newName = "  Bananas  "
        model.newQuantity = 3
        model.newUnit = .piece
        model.newCategory = .produce

        let added = await model.addManualItem()

        XCTAssertTrue(added)
        XCTAssertEqual(repo.addCount, 1)
        XCTAssertEqual(repo.items.count, 1)
        XCTAssertEqual(repo.items.first?.name, "Bananas")
        XCTAssertEqual(repo.items.first?.category, .produce)
        XCTAssertEqual(model.items.count, 1)
        XCTAssertEqual(model.newName, "")
        XCTAssertEqual(model.newQuantity, 1)
    }

    func testToggleCheckedUpdatesItemAndRepository() async {
        let item = ShoppingListItem(name: "Milk", category: .dairy)
        let repo = InMemoryShoppingListRepository(items: [item])
        let model = ShoppingListViewModel(repository: repo)
        await model.load()

        await model.toggleChecked(item)

        XCTAssertTrue(item.isChecked)
        XCTAssertEqual(repo.updateCount, 1)
    }

    func testDeleteRemovesViaRepository() async {
        let item = ShoppingListItem(name: "Eggs", category: .dairy)
        let repo = InMemoryShoppingListRepository(items: [item])
        let model = ShoppingListViewModel(repository: repo)
        await model.load()

        await model.delete(item)

        XCTAssertEqual(repo.deletedIDs, [item.id])
        XCTAssertTrue(model.items.isEmpty)
    }

    func testClearPurchasedCallsRepository() async {
        let checked = ShoppingListItem(name: "Bread", isChecked: true)
        let unchecked = ShoppingListItem(name: "Butter", isChecked: false)
        let repo = InMemoryShoppingListRepository(items: [checked, unchecked])
        let model = ShoppingListViewModel(repository: repo)
        await model.load()

        await model.clearPurchased()

        XCTAssertEqual(repo.clearCheckedCount, 1)
        XCTAssertEqual(model.items.count, 1)
        XCTAssertEqual(model.items.first?.name, "Butter")
    }

    func testClearAllDeletesEveryItem() async {
        let items = [
            ShoppingListItem(name: "A"),
            ShoppingListItem(name: "B")
        ]
        let repo = InMemoryShoppingListRepository(items: items)
        let model = ShoppingListViewModel(repository: repo)
        await model.load()

        await model.clearAll()

        XCTAssertEqual(repo.deletedIDs.count, 2)
        XCTAssertTrue(model.items.isEmpty)
    }

    func testSectionsGroupByCategoryAndSinkCheckedItems() async {
        let produce = ShoppingListItem(name: "Carrot", category: .produce)
        let dairyChecked = ShoppingListItem(name: "Cheese", category: .dairy, isChecked: true)
        let dairyUnchecked = ShoppingListItem(name: "Yogurt", category: .dairy, isChecked: false)
        let repo = InMemoryShoppingListRepository(items: [produce, dairyChecked, dairyUnchecked])
        let model = ShoppingListViewModel(repository: repo)
        await model.load()

        let sections = model.sections
        XCTAssertEqual(sections.map(\.category), [.produce, .dairy])
        let dairy = sections.first { $0.category == .dairy }?.items
        XCTAssertEqual(dairy?.map(\.name), ["Yogurt", "Cheese"])
    }
}
