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
}
