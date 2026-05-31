import XCTest
@testable import FoodMap

@MainActor
final class MealPlannerViewModelTests: XCTestCase {
    private final class StubMealPlanner: MealPlannerAIService, @unchecked Sendable {
        let plan: MealPlan
        init(plan: MealPlan) {
            self.plan = plan
        }

        func generatePlan(from _: [Product], profile _: UserProfile, planType _: MealPlanType) async throws -> MealPlan {
            plan
        }
    }

    private final class StubMealPlanRepository: MealPlanRepository, @unchecked Sendable {
        func save(_: MealPlan) async throws {}
        func fetchLatest() async throws -> MealPlan? {
            nil
        }

        func fetchAll() async throws -> [MealPlan] {
            []
        }

        func delete(id _: UUID) async throws {}
    }

    private func makeModel(
        plan: MealPlan,
        shopping: InMemoryShoppingListRepository
    ) -> MealPlannerViewModel {
        MealPlannerViewModel(
            planner: StubMealPlanner(plan: plan),
            generateShoppingList: GenerateShoppingListFromMealPlanUseCase(),
            mealPlanRepository: StubMealPlanRepository(),
            shoppingListRepository: shopping
        )
    }

    private func planWithMissing() -> MealPlan {
        let meal = Meal(name: "M1", ingredients: [
            MealIngredient(name: "Tomato", quantity: 2, unit: .piece, isAvailableInPantry: false),
            MealIngredient(name: "Onion", quantity: 1, unit: .piece, isAvailableInPantry: false)
        ])
        return MealPlan(title: "Plan", meals: [meal])
    }

    func testCreateShoppingListAddsItemsAndConfirms() async {
        let repo = InMemoryShoppingListRepository()
        let model = makeModel(plan: planWithMissing(), shopping: repo)
        await model.generate(products: [], profile: UserProfile())

        await model.createShoppingList()

        XCTAssertEqual(repo.items.count, 2)
        XCTAssertEqual(repo.addCount, 1)
        XCTAssertNotNil(model.shoppingConfirmation)
        XCTAssertEqual(model.shoppingConfirmation, "Added 2 items to your shopping list.")
    }

    func testCreateShoppingListTwiceMergesInsteadOfDuplicating() async {
        let repo = InMemoryShoppingListRepository()
        let model = makeModel(plan: planWithMissing(), shopping: repo)
        await model.generate(products: [], profile: UserProfile())

        await model.createShoppingList()
        await model.createShoppingList()

        // Still two distinct items — quantities merged, no duplicates.
        XCTAssertEqual(repo.items.count, 2)
        let tomato = repo.items.first { $0.name == "Tomato" }
        XCTAssertEqual(tomato?.quantity, 4)
        XCTAssertEqual(model.shoppingConfirmation, "Updated 2 items already on your shopping list.")
    }

    func testCreateShoppingListMergesIntoExistingMatchingItem() async {
        let existing = ShoppingListItem(name: "tomato", quantity: 5, unit: .piece, category: .produce)
        let repo = InMemoryShoppingListRepository(items: [existing])
        let model = makeModel(plan: planWithMissing(), shopping: repo)
        await model.generate(products: [], profile: UserProfile())

        await model.createShoppingList()

        // Tomato merges into the existing row; only Onion is inserted.
        XCTAssertEqual(repo.items.count, 2)
        XCTAssertEqual(existing.quantity, 7)
        XCTAssertEqual(model.shoppingConfirmation, "Added 1 item and updated 1 already on your list.")
    }

    func testCreateShoppingListWithNothingMissingConfirmsPantry() async {
        let meal = Meal(name: "M1", ingredients: [
            MealIngredient(name: "Salt", quantity: 1, unit: .piece, isAvailableInPantry: true)
        ])
        let repo = InMemoryShoppingListRepository()
        let model = makeModel(plan: MealPlan(title: "Plan", meals: [meal]), shopping: repo)
        await model.generate(products: [], profile: UserProfile())

        await model.createShoppingList()

        XCTAssertTrue(repo.items.isEmpty)
        XCTAssertEqual(repo.addCount, 0)
        XCTAssertEqual(model.shoppingConfirmation, "All ingredients are already in your pantry.")
    }
}
