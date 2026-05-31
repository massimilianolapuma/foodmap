import XCTest
@testable import FoodMap

final class SuggestProductsUseCaseTests: XCTestCase {
    private let useCase = SuggestProductsUseCase()

    private func product(_ name: String, category: ProductCategory = .other) -> Product {
        Product(name: name, category: category)
    }

    /// No staples by default so tests focus on the rule under test.
    private func suggest(
        history: [Product] = [],
        pantry: [Product] = [],
        plan: MealPlan? = nil,
        productsByID: [UUID: Product] = [:],
        staples: [StapleProduct] = [],
        maxResults: Int = 10
    ) -> [ProductSuggestion] {
        useCase(
            history: history,
            pantry: pantry,
            plan: plan,
            productsByID: productsByID,
            staples: staples,
            maxResults: maxResults
        )
    }

    func testNoInputsYieldNoSuggestions() {
        XCTAssertTrue(suggest().isEmpty)
    }

    func testRecurringRequiresAtLeastTwoPurchasesAndAbsenceFromPantry() {
        let history = [product("Milk"), product("Milk"), product("Eggs")]
        let result = suggest(history: history)

        // Milk bought twice -> recurring. Eggs once -> not recurring.
        XCTAssertEqual(result.map(\.name), ["Milk"])
        XCTAssertEqual(result.first?.reason, .recurring)
    }

    func testRecurringExcludesItemsAlreadyInPantry() {
        let history = [product("Milk"), product("Milk")]
        let result = suggest(history: history, pantry: [product("Milk")])

        XCTAssertTrue(result.isEmpty)
    }

    func testMissingMealPlanIngredientsAreSuggested() {
        let inPantry = MealIngredient(name: "Salt", isAvailableInPantry: true)
        let missing = MealIngredient(name: "Basil", isAvailableInPantry: false)
        let meal = Meal(name: "Pesto", ingredients: [inPantry, missing])
        let plan = MealPlan(title: "Plan", meals: [meal])

        let result = suggest(plan: plan)

        XCTAssertEqual(result.map(\.name), ["Basil"])
        XCTAssertEqual(result.first?.reason, .missingForMealPlan)
    }

    func testMealPlanIngredientAlreadyInPantryByNameIsNotSuggested() {
        let missing = MealIngredient(name: "Tomato", isAvailableInPantry: false)
        let meal = Meal(name: "Sauce", ingredients: [missing])
        let plan = MealPlan(title: "Plan", meals: [meal])

        let result = suggest(pantry: [product("tomato")], plan: plan)

        XCTAssertTrue(result.isEmpty)
    }

    func testMealPlanCategoryDerivedFromLinkedProduct() {
        let linked = Product(name: "Salmon", category: .meatFish)
        let ingredient = MealIngredient(name: "Salmon", isAvailableInPantry: false, linkedProductID: linked.id)
        let meal = Meal(name: "Fish", ingredients: [ingredient])
        let plan = MealPlan(title: "Plan", meals: [meal])

        let result = suggest(plan: plan, productsByID: [linked.id: linked])

        XCTAssertEqual(result.first?.category, .meatFish)
    }

    func testMealPlanSuggestionsRankAboveRecurring() {
        let missing = MealIngredient(name: "Basil", isAvailableInPantry: false)
        let meal = Meal(name: "Pesto", ingredients: [missing])
        let plan = MealPlan(title: "Plan", meals: [meal])
        let history = [product("Milk"), product("Milk")]

        let result = suggest(history: history, plan: plan)

        XCTAssertEqual(result.map(\.reason).first, .missingForMealPlan)
        XCTAssertEqual(result.map(\.name), ["Basil", "Milk"])
    }

    func testLowCategorySuggestsRepresentativeFromEmptyCategory() {
        // Dairy bought before but the pantry has no dairy at all. Each item was
        // bought once (so none qualifies as recurring), and the representative is
        // chosen alphabetically on the frequency tie.
        let history = [
            product("Milk", category: .dairy),
            product("Yogurt", category: .dairy)
        ]
        let pantry = [product("Apple", category: .fruitsVegetables)]

        let result = suggest(history: history, pantry: pantry).filter { $0.reason == .lowCategory }

        XCTAssertEqual(result.map(\.name), ["Milk"])
        XCTAssertEqual(result.first?.category, .dairy)
    }

    func testLowCategorySkippedWhenCategoryStocked() {
        let history = [product("Milk", category: .dairy), product("Milk", category: .dairy)]
        let pantry = [product("Cheese", category: .dairy)]

        let result = suggest(history: history, pantry: pantry).filter { $0.reason == .lowCategory }

        XCTAssertTrue(result.isEmpty)
    }

    func testStaplesSuggestedWhenMissingFromPantry() {
        let staples = [StapleProduct(name: "Salt", category: .condiments)]
        let result = suggest(staples: staples)

        XCTAssertEqual(result.map(\.name), ["Salt"])
        XCTAssertEqual(result.first?.reason, .staple)
    }

    func testStaplesExcludedWhenPresentInPantry() {
        let staples = [StapleProduct(name: "Salt", category: .condiments)]
        let result = suggest(pantry: [product("salt")], staples: staples)

        XCTAssertTrue(result.isEmpty)
    }

    func testStrongerReasonWinsWhenSameProductQualifiesMultipleTimes() {
        // Milk is both a recurring purchase and a configured staple -> recurring wins.
        let history = [product("Milk", category: .dairy), product("Milk", category: .dairy)]
        let staples = [StapleProduct(name: "Milk", category: .dairy)]

        let result = suggest(history: history, staples: staples)

        XCTAssertEqual(result.map(\.name), ["Milk"])
        XCTAssertEqual(result.first?.reason, .recurring)
    }

    func testMaxResultsCapsOutput() {
        let staples = [
            StapleProduct(name: "Salt"),
            StapleProduct(name: "Sugar"),
            StapleProduct(name: "Flour")
        ]
        let result = suggest(staples: staples, maxResults: 2)

        XCTAssertEqual(result.count, 2)
    }

    func testReasonPriorityOrdering() {
        XCTAssertLessThan(SuggestionReason.missingForMealPlan.priority, SuggestionReason.recurring.priority)
        XCTAssertLessThan(SuggestionReason.recurring.priority, SuggestionReason.lowCategory.priority)
        XCTAssertLessThan(SuggestionReason.lowCategory.priority, SuggestionReason.staple.priority)
    }
}
