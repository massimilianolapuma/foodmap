import XCTest
@testable import FoodMap

final class MealPlanningUseCasesTests: XCTestCase {
    func testVeganDietRejectsMeatMeal() {
        let filter = FilterMealsByDietRestrictionsUseCase()
        let profile = UserProfile(dietType: .vegana)
        let meal = Meal(name: "Beef stew", ingredients: [MealIngredient(name: "beef")])
        let result = filter(meals: [meal], profile: profile, productsByID: [:])
        XCTAssertTrue(result.isEmpty)
    }

    func testAllergenMealIsFilteredOut() {
        let filter = FilterMealsByDietRestrictionsUseCase()
        let profile = UserProfile(dietType: .standard, allergens: [.gluten])
        let product = Product(name: "Pasta", allergens: [.gluten])
        let ingredient = MealIngredient(name: "Pasta", linkedProductID: product.id)
        let meal = Meal(name: "Pasta dish", ingredients: [ingredient])
        let result = filter(meals: [meal], profile: profile, productsByID: [product.id: product])
        XCTAssertTrue(result.isEmpty)
    }

    func testCombinedDietsRequireAllConstraints() {
        let filter = FilterMealsByDietRestrictionsUseCase()
        let profile = UserProfile(dietTypes: [.vegana, .glutenFree])

        // Meat fails the vegan constraint even though it is gluten free.
        let meatMeal = Meal(name: "Beef bowl", ingredients: [MealIngredient(name: "beef")])
        // Pasta carrying gluten fails the gluten-free constraint.
        let glutenProduct = Product(name: "Pasta", allergens: [.gluten])
        let pastaMeal = Meal(
            name: "Veggie pasta",
            ingredients: [MealIngredient(name: "Pasta", linkedProductID: glutenProduct.id)]
        )
        // A vegan, gluten-free meal passes both constraints.
        let saladMeal = Meal(name: "Garden salad", ingredients: [MealIngredient(name: "lettuce")])

        let result = filter(
            meals: [meatMeal, pastaMeal, saladMeal],
            profile: profile,
            productsByID: [glutenProduct.id: glutenProduct]
        )
        XCTAssertEqual(result.map(\.name), ["Garden salad"])
    }

    func testMultiDietBackfillsLegacySingleDiet() {
        // A profile created with the legacy single-diet API still reports it
        // through the new multi-diet accessor.
        let profile = UserProfile(dietType: .vegetariana)
        XCTAssertEqual(profile.dietTypes, [.vegetariana])
    }

    func testEmptyDietSelectionFallsBackToStandard() {
        let profile = UserProfile(dietTypes: [])
        XCTAssertEqual(profile.dietTypes, [.standard])
    }

    func testShoppingListAggregatesMissingIngredients() {
        let useCase = GenerateShoppingListFromMealPlanUseCase()
        let meal1 = Meal(name: "M1", ingredients: [
            MealIngredient(name: "Tomato", quantity: 2, unit: .piece, isAvailableInPantry: false)
        ])
        let meal2 = Meal(name: "M2", ingredients: [
            MealIngredient(name: "Tomato", quantity: 3, unit: .piece, isAvailableInPantry: false),
            MealIngredient(name: "Onion", quantity: 1, unit: .piece, isAvailableInPantry: true)
        ])
        let plan = MealPlan(title: "Plan", meals: [meal1, meal2])
        let items = useCase(plan: plan)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.name, "Tomato")
        XCTAssertEqual(items.first?.quantity, 5)
    }

    func testShoppingListAggregatesAcrossMealsCaseInsensitively() {
        let useCase = GenerateShoppingListFromMealPlanUseCase()
        let meal1 = Meal(name: "M1", ingredients: [
            MealIngredient(name: "Pasta", quantity: 1, unit: .piece, isAvailableInPantry: false)
        ])
        let meal2 = Meal(name: "M2", ingredients: [
            MealIngredient(name: "pasta", quantity: 1, unit: .piece, isAvailableInPantry: false)
        ])
        let plan = MealPlan(title: "Plan", meals: [meal1, meal2])
        let items = useCase(plan: plan)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.quantity, 2)
    }

    func testShoppingListKeepsDifferentUnitsSeparate() {
        let useCase = GenerateShoppingListFromMealPlanUseCase()
        let meal = Meal(name: "M1", ingredients: [
            MealIngredient(name: "Flour", quantity: 200, unit: .gram, isAvailableInPantry: false),
            MealIngredient(name: "Flour", quantity: 1, unit: .pack, isAvailableInPantry: false)
        ])
        let plan = MealPlan(title: "Plan", meals: [meal])
        let items = useCase(plan: plan)
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(Set(items.map(\.unit)), [.gram, .pack])
    }

    func testSingleMealShoppingListAggregatesMissingIngredients() {
        let useCase = GenerateShoppingListFromMealUseCase()
        let meal = Meal(name: "M1", ingredients: [
            MealIngredient(name: "Tomato", quantity: 2, unit: .piece, isAvailableInPantry: false),
            MealIngredient(name: "tomato", quantity: 3, unit: .piece, isAvailableInPantry: false),
            MealIngredient(name: "Salt", quantity: 1, unit: .piece, isAvailableInPantry: true)
        ])
        let items = useCase(meal: meal)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.name, "Tomato")
        XCTAssertEqual(items.first?.quantity, 5)
    }

    func testSingleMealShoppingListSetsSourceMealPlanID() {
        let useCase = GenerateShoppingListFromMealUseCase()
        let planID = UUID()
        let meal = Meal(name: "M1", ingredients: [
            MealIngredient(name: "Onion", quantity: 1, unit: .piece, isAvailableInPantry: false)
        ])
        let items = useCase(meal: meal, sourceMealPlanID: planID)
        XCTAssertEqual(items.first?.sourceMealPlanID, planID)
    }

    func testSingleMealShoppingListEmptyWhenAllInPantry() {
        let useCase = GenerateShoppingListFromMealUseCase()
        let meal = Meal(name: "M1", ingredients: [
            MealIngredient(name: "Salt", quantity: 1, unit: .piece, isAvailableInPantry: true)
        ])
        XCTAssertTrue(useCase(meal: meal).isEmpty)
    }
}
