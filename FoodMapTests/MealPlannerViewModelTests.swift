import XCTest
@testable import FoodMap

@MainActor
final class MealPlannerViewModelTests: XCTestCase {
    private final class StubMealPlanner: MealPlannerAIService, @unchecked Sendable {
        let plan: MealPlan
        let alternativesToReturn: [Meal]
        init(plan: MealPlan, alternatives: [Meal] = []) {
            self.plan = plan
            alternativesToReturn = alternatives
        }

        func generatePlan(from _: [Product], profile _: UserProfile, planType _: MealPlanType) async throws -> MealPlan {
            plan
        }

        func alternatives(for _: Meal, from _: [Product], profile _: UserProfile, count _: Int) async throws -> [Meal] {
            alternativesToReturn
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

    private func makeModel(
        plan: MealPlan,
        alternatives: [Meal],
        shopping: InMemoryShoppingListRepository
    ) -> MealPlannerViewModel {
        MealPlannerViewModel(
            planner: StubMealPlanner(plan: plan, alternatives: alternatives),
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

    func testLoadAlternativesExposesPlannerSuggestions() async {
        let original = Meal(name: "Original", mealType: .dinner, dayIndex: 0)
        let altA = Meal(name: "Alt A", mealType: .dinner, dayIndex: 0)
        let altB = Meal(name: "Alt B", mealType: .dinner, dayIndex: 0)
        let repo = InMemoryShoppingListRepository()
        let model = makeModel(
            plan: MealPlan(title: "Plan", meals: [original]),
            alternatives: [altA, altB],
            shopping: repo
        )
        await model.generate(products: [], profile: UserProfile())

        await model.loadAlternatives(for: original)

        XCTAssertEqual(model.alternatives.map(\.name), ["Alt A", "Alt B"])
        XCTAssertFalse(model.isLoadingAlternatives)
    }

    func testReplaceSwapsMealKeepingOthers() async {
        let dinner = Meal(name: "Dinner", mealType: .dinner, dayIndex: 0)
        let lunch = Meal(name: "Lunch", mealType: .lunch, dayIndex: 1)
        let replacement = Meal(name: "New Dinner", mealType: .dinner, dayIndex: 0)
        let repo = InMemoryShoppingListRepository()
        let model = makeModel(
            plan: MealPlan(title: "Plan", meals: [dinner, lunch]),
            shopping: repo
        )
        await model.generate(products: [], profile: UserProfile())

        await model.replace(dinner, with: replacement)

        let names = model.plan?.meals.map(\.name).sorted()
        XCTAssertEqual(names, ["Lunch", "New Dinner"])
        XCTAssertEqual(model.plan?.meals.count, 2)
    }
}
