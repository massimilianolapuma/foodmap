import XCTest
@testable import FoodMap

final class ScheduleShoppingUseCaseTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    /// Fixed reference date: 2026-05-01 (a Friday), normalized to start of day.
    private lazy var reference: Date = {
        var components = DateComponents()
        components.year = 2026
        components.month = 5
        components.day = 1
        return calendar.startOfDay(for: calendar.date(from: components)!)
    }()

    private func day(_ offset: Int) -> Date {
        calendar.date(byAdding: .day, value: offset, to: reference)!
    }

    private func makeUseCase(interval: Int = 7, threshold: Int = 5) -> ScheduleShoppingUseCase {
        ScheduleShoppingUseCase(
            calendar: calendar,
            tripIntervalDays: interval,
            perishableThresholdDays: threshold
        )
    }

    func testEmptyPurchasesYieldsNoTrips() {
        let trips = makeUseCase()(purchases: [], from: reference)
        XCTAssertTrue(trips.isEmpty)
    }

    func testShelfStableItemsBoughtOnFirstTrip() {
        // Pasta needed on day 7 but shelf-stable -> bought immediately (day 0).
        let pasta = PlannedPurchase(name: "Pasta", quantity: 2, unit: .pack, neededOn: day(7), shelfLifeDays: nil)
        let trips = makeUseCase()(purchases: [pasta], from: reference)

        XCTAssertEqual(trips.count, 1)
        XCTAssertEqual(trips.first?.date, reference)
        XCTAssertEqual(trips.first?.items.first?.name, "Pasta")
        XCTAssertEqual(trips.first?.items.first?.isPerishable, false)
    }

    func testPerishableItemScheduledOnLatestTripInFreshnessWindow() {
        // Fresh fish (2-day shelf life) needed on day 7. With weekly trips at
        // day 0 and day 7, only the day-7 trip falls in the freshness window
        // [day 5, day 7], so it is bought then rather than on day 0.
        let fish = PlannedPurchase(name: "Fish", quantity: 1, unit: .piece, neededOn: day(7), shelfLifeDays: 2)
        let trips = makeUseCase()(purchases: [fish], from: reference)

        XCTAssertEqual(trips.map(\.date), [day(7)])
        XCTAssertEqual(trips.first?.items.first?.isPerishable, true)
    }

    func testPerishableAndShelfStableSplitAcrossTrips() {
        let pasta = PlannedPurchase(name: "Pasta", quantity: 1, unit: .pack, neededOn: day(7), shelfLifeDays: nil)
        let fish = PlannedPurchase(name: "Fish", quantity: 1, unit: .piece, neededOn: day(7), shelfLifeDays: 2)
        let trips = makeUseCase()(purchases: [pasta, fish], from: reference)

        XCTAssertEqual(trips.count, 2)
        XCTAssertEqual(trips.map(\.date), [reference, day(7)])
        XCTAssertEqual(trips.first?.items.map(\.name), ["Pasta"])
        XCTAssertEqual(trips.last?.items.map(\.name), ["Fish"])
    }

    func testItemNeededBeforeScheduleStartsGoesToFirstTrip() {
        // Needed in the past relative to the reference date -> earliest trip.
        let milk = PlannedPurchase(name: "Milk", quantity: 1, unit: .liter, neededOn: day(-3), shelfLifeDays: 2)
        let trips = makeUseCase()(purchases: [milk], from: reference)

        XCTAssertEqual(trips.map(\.date), [reference])
    }

    func testPerishableNeededVerySoonFallsBackToFeasibleTrip() {
        // Fish (2-day shelf life) needed on day 1. No trip falls in the window
        // [day -1, day 1] except day 0, which is feasible (<= needed day).
        let fish = PlannedPurchase(name: "Fish", quantity: 1, unit: .piece, neededOn: day(1), shelfLifeDays: 2)
        let trips = makeUseCase()(purchases: [fish], from: reference)

        XCTAssertEqual(trips.map(\.date), [reference])
        XCTAssertEqual(trips.first?.items.first?.isPerishable, true)
    }

    func testItemsWithinSameTripAreSortedByName() {
        let banana = PlannedPurchase(name: "Banana", quantity: 1, unit: .piece, neededOn: day(7), shelfLifeDays: nil)
        let apple = PlannedPurchase(name: "Apple", quantity: 1, unit: .piece, neededOn: day(7), shelfLifeDays: nil)
        let trips = makeUseCase()(purchases: [banana, apple], from: reference)

        XCTAssertEqual(trips.first?.items.map(\.name), ["Apple", "Banana"])
    }

    func testThresholdControlsPerishabilityClassification() {
        // A 5-day shelf life is perishable when the threshold is 7, but
        // shelf-stable when the threshold is 5 (shelfLife < threshold is the rule).
        let item = PlannedPurchase(name: "Yogurt", quantity: 1, unit: .piece, neededOn: day(7), shelfLifeDays: 5)

        let strict = makeUseCase(threshold: 7)(purchases: [item], from: reference)
        XCTAssertEqual(strict.first?.items.first?.isPerishable, true)

        let lenient = makeUseCase(threshold: 5)(purchases: [item], from: reference)
        XCTAssertEqual(lenient.first?.items.first?.isPerishable, false)
        XCTAssertEqual(lenient.first?.date, reference)
    }
}

final class ScheduleShoppingFromMealPlanUseCaseTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    private lazy var reference: Date = {
        var components = DateComponents()
        components.year = 2026
        components.month = 5
        components.day = 1
        return calendar.startOfDay(for: calendar.date(from: components)!)
    }()

    private func day(_ offset: Int) -> Date {
        calendar.date(byAdding: .day, value: offset, to: reference)!
    }

    func testOnlyMissingIngredientsAreScheduled() {
        let inPantry = MealIngredient(name: "Salt", quantity: 1, unit: .pack, isAvailableInPantry: true)
        let missing = MealIngredient(name: "Pasta", quantity: 1, unit: .pack, isAvailableInPantry: false)
        let meal = Meal(name: "Dinner", dayIndex: 0, ingredients: [inPantry, missing])
        let plan = MealPlan(title: "Plan", startDate: reference, meals: [meal])

        let trips = ScheduleShoppingFromMealPlanUseCase(calendar: calendar)(plan: plan, from: reference)

        let names = trips.flatMap { $0.items.map(\.name) }
        XCTAssertEqual(names, ["Pasta"])
    }

    func testIngredientPerishabilityDerivedFromLinkedProduct() {
        // Fish ingredient linked to a meat/fish product (2-day fridge shelf life)
        // needed on day 7 -> scheduled on the day-7 trip, not bought early.
        let product = Product(name: "Salmon", category: .meatFish)
        let fish = MealIngredient(name: "Salmon", quantity: 1, unit: .piece, linkedProductID: product.id)
        let meal = Meal(name: "Fish dinner", dayIndex: 7, ingredients: [fish])
        let plan = MealPlan(title: "Plan", startDate: reference, meals: [meal])

        let trips = ScheduleShoppingFromMealPlanUseCase(calendar: calendar)(
            plan: plan,
            productsByID: [product.id: product],
            storageLocation: .fridge,
            from: reference
        )

        XCTAssertEqual(trips.map(\.date), [day(7)])
        XCTAssertEqual(trips.first?.items.first?.isPerishable, true)
    }

    func testUnlinkedIngredientsAreShelfStable() {
        let ingredient = MealIngredient(name: "Flour", quantity: 1, unit: .kilogram)
        let meal = Meal(name: "Bread", dayIndex: 7, ingredients: [ingredient])
        let plan = MealPlan(title: "Plan", startDate: reference, meals: [meal])

        let trips = ScheduleShoppingFromMealPlanUseCase(calendar: calendar)(plan: plan, from: reference)

        XCTAssertEqual(trips.map(\.date), [reference])
        XCTAssertEqual(trips.first?.items.first?.isPerishable, false)
    }

    func testDuplicateIngredientsAcrossMealsAreAggregated() {
        let early = MealIngredient(name: "Pasta", quantity: 1, unit: .pack)
        let late = MealIngredient(name: "Pasta", quantity: 2, unit: .pack)
        let mealEarly = Meal(name: "Day1", dayIndex: 1, ingredients: [early])
        let mealLate = Meal(name: "Day5", dayIndex: 5, ingredients: [late])
        let plan = MealPlan(title: "Plan", startDate: reference, meals: [mealLate, mealEarly])

        let trips = ScheduleShoppingFromMealPlanUseCase(calendar: calendar)(plan: plan, from: reference)

        let items = trips.flatMap(\.items)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.name, "Pasta")
        XCTAssertEqual(items.first?.quantity, 3)
        // Earliest needed day is preserved (day 1).
        XCTAssertEqual(items.first?.neededOn, day(1))
    }

    func testEmptyPlanYieldsNoTrips() {
        let plan = MealPlan(title: "Empty", startDate: reference, meals: [])
        let trips = ScheduleShoppingFromMealPlanUseCase(calendar: calendar)(plan: plan, from: reference)
        XCTAssertTrue(trips.isEmpty)
    }
}
