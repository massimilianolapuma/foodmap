import XCTest
@testable import FoodMap

/// Tests for the deterministic rule-based planner (issue #13): expiring-first
/// prioritization, diet filtering, and day-count correctness.
final class RuleBasedMealPlannerTests: XCTestCase {
    private let profileStandard = UserProfile(dietType: .standard)

    /// Planner pinned to a fixed clock + UTC calendar so expiry math is deterministic.
    private func makePlanner(today: Date) -> RuleBasedMealPlanner {
        RuleBasedMealPlanner(
            expiryCalculator: CalculateExpiryStatusUseCase(
                clock: FixedClock(fixed: today),
                calendar: .utcGregorian
            )
        )
    }

    func testMostExpiringProductIsUsedAsPrimaryFirst() async throws {
        let today = Date.make(year: 2026, month: 6, day: 1)
        let expiringSoon = Product(name: "Spinach", expiryDate: .make(year: 2026, month: 6, day: 1))
        let fresh = Product(name: "Canned beans", expiryDate: .make(year: 2026, month: 12, day: 1))
        let planner = makePlanner(today: today)

        let plan = try await planner.generatePlan(
            from: [fresh, expiringSoon],
            profile: profileStandard,
            planType: .singleDay
        )

        let firstPrimary = try XCTUnwrap(plan.meals.first?.ingredients.first?.name)
        XCTAssertEqual(firstPrimary, "Spinach", "The most-expiring product must drive the first meal")
        XCTAssertTrue(plan.meals.first?.name.contains("Spinach") ?? false)
    }

    func testDayCountMatchesPlanType() async throws {
        let today = Date.make(year: 2026, month: 6, day: 1)
        let products = [
            Product(name: "Tomato", expiryDate: .make(year: 2026, month: 6, day: 2)),
            Product(name: "Rice", expiryDate: .make(year: 2026, month: 6, day: 20))
        ]
        let planner = makePlanner(today: today)

        let cases: [(MealPlanType, Int)] = [(.singleDay, 2), (.threeDays, 6), (.week, 14), (.month, 60)]
        for (planType, expected) in cases {
            let plan = try await planner.generatePlan(from: products, profile: profileStandard, planType: planType)
            XCTAssertEqual(plan.meals.count, expected, "\(planType) should yield \(expected) meals (days × 2)")
        }
    }

    func testDietRestrictionsFilterOutMeatMeals() async throws {
        let today = Date.make(year: 2026, month: 6, day: 1)
        // Veg items expire soonest; the meat item is freshest so it is never a companion
        // of the top-priority items — only its own primary meal should be rejected.
        let tomato = Product(name: "Tomato", expiryDate: .make(year: 2026, month: 6, day: 1))
        let rice = Product(name: "Rice", expiryDate: .make(year: 2026, month: 6, day: 3))
        let beans = Product(name: "Beans", expiryDate: .make(year: 2026, month: 6, day: 6))
        let chicken = Product(name: "Chicken breast", expiryDate: .make(year: 2026, month: 6, day: 20))
        let planner = makePlanner(today: today)
        let vegan = UserProfile(dietType: .vegana)

        let plan = try await planner.generatePlan(
            from: [rice, chicken, tomato, beans],
            profile: vegan,
            planType: .threeDays
        )

        // 6 meals total; the single chicken-primary meal is filtered out → 5 remain.
        XCTAssertEqual(plan.meals.count, 5)
        for meal in plan.meals {
            XCTAssertFalse(
                meal.name.lowercased().contains("chicken"),
                "Vegan plan must not surface chicken meals"
            )
        }
    }

    func testGeneratedMealsAreCompleteRecipes() async throws {
        let today = Date.make(year: 2026, month: 6, day: 1)
        let spinach = Product(name: "Spinach", expiryDate: .make(year: 2026, month: 6, day: 1))
        let rice = Product(name: "Rice", expiryDate: .make(year: 2026, month: 6, day: 10))
        let planner = makePlanner(today: today)

        let plan = try await planner.generatePlan(
            from: [spinach, rice],
            profile: profileStandard,
            planType: .singleDay
        )

        for meal in plan.meals {
            XCTAssertFalse(meal.steps.isEmpty, "Each meal must include preparation steps")
            XCTAssertFalse(meal.ingredients.isEmpty, "Each meal must list its ingredients")
            let total = try XCTUnwrap(meal.totalMinutes, "Each meal must expose prep/cook time")
            XCTAssertGreaterThan(total, 0)
            XCTAssertEqual(meal.totalMinutes, (meal.prepMinutes ?? 0) + (meal.cookMinutes ?? 0))
        }
    }

    func testEstimatedCaloriesSumLinkedProductEnergy() async throws {
        let today = Date.make(year: 2026, month: 6, day: 1)
        let spinach = Product(name: "Spinach", expiryDate: .make(year: 2026, month: 6, day: 1))
        spinach.nutrition = NutritionInfo(energyKcal: 120)
        let rice = Product(name: "Rice", expiryDate: .make(year: 2026, month: 6, day: 2))
        rice.nutrition = NutritionInfo(energyKcal: 200)
        let planner = makePlanner(today: today)

        let plan = try await planner.generatePlan(
            from: [spinach, rice],
            profile: profileStandard,
            planType: .singleDay
        )

        let firstMeal = try XCTUnwrap(plan.meals.first)
        XCTAssertEqual(firstMeal.estimatedCalories, 320, "Calories should sum linked pantry products")
    }

    func testAlternativesExcludeCurrentPrimaryAndKeepSlot() async throws {
        let today = Date.make(year: 2026, month: 6, day: 1)
        let spinach = Product(name: "Spinach", expiryDate: .make(year: 2026, month: 6, day: 1))
        let rice = Product(name: "Rice", expiryDate: .make(year: 2026, month: 6, day: 3))
        let beans = Product(name: "Beans", expiryDate: .make(year: 2026, month: 6, day: 6))
        let planner = makePlanner(today: today)

        let plan = try await planner.generatePlan(
            from: [spinach, rice, beans],
            profile: profileStandard,
            planType: .singleDay
        )
        let dinner = try XCTUnwrap(plan.meals.first { $0.mealType == .dinner })
        let currentPrimaryID = dinner.ingredients.first?.linkedProductID

        let alternatives = try await planner.alternatives(
            for: dinner,
            from: [spinach, rice, beans],
            profile: profileStandard,
            count: 3
        )

        XCTAssertFalse(alternatives.isEmpty, "Should offer at least one alternative")
        for alternative in alternatives {
            XCTAssertEqual(alternative.mealType, dinner.mealType, "Alternatives keep the same slot")
            XCTAssertEqual(alternative.dayIndex, dinner.dayIndex, "Alternatives keep the same day")
            XCTAssertNotEqual(
                alternative.ingredients.first?.linkedProductID,
                currentPrimaryID,
                "Alternatives must not reuse the current primary product"
            )
        }
    }

    func testAlternativesKeepExpiringFirstPriority() async throws {
        let today = Date.make(year: 2026, month: 6, day: 1)
        let chicken = Product(name: "Chicken", expiryDate: .make(year: 2026, month: 6, day: 20))
        let spinach = Product(name: "Spinach", expiryDate: .make(year: 2026, month: 6, day: 1))
        let rice = Product(name: "Rice", expiryDate: .make(year: 2026, month: 6, day: 3))
        let planner = makePlanner(today: today)

        // Build a meal whose primary is the freshest item, so the soonest-expiring
        // product is still available as an alternative.
        let meal = Meal(
            name: "Dinner with Chicken",
            mealType: .dinner,
            dayIndex: 0,
            ingredients: [
                MealIngredient(name: "Chicken", quantity: 1, unit: .piece, isAvailableInPantry: true, linkedProductID: chicken.id)
            ]
        )

        let alternatives = try await planner.alternatives(
            for: meal,
            from: [chicken, spinach, rice],
            profile: profileStandard,
            count: 3
        )

        let firstAlternativePrimary = try XCTUnwrap(alternatives.first?.ingredients.first?.name)
        XCTAssertEqual(firstAlternativePrimary, "Spinach", "Most-expiring product drives the top alternative")
    }
}
