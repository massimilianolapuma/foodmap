import Foundation

/// Distributes the purchases a meal plan requires across one or more shopping
/// trips, so the user does not buy perishables too far ahead of when they are
/// needed while still consolidating shelf-stable staples into early trips.
///
/// Pure, deterministic logic: inject a fixed `Calendar` and reference date in
/// tests. No persistence, networking, or UI dependencies.
///
/// Strategy:
/// - Trips occur on a fixed cadence (`tripIntervalDays`, default weekly) starting
///   from `from`.
/// - A purchase may only be assigned to a trip on or before the day it is needed.
/// - **Shelf-stable** items (no `shelfLifeDays`, or a shelf life at/above
///   `perishableThresholdDays`) are bought on the earliest trip to consolidate.
/// - **Perishable** items are bought as late as possible — the latest trip that
///   still falls inside their freshness window `[neededOn - shelfLife, neededOn]`.
///   When no trip falls in that window (the item is needed very soon), they are
///   placed on the latest feasible trip on or before `neededOn`, or the first
///   trip when they are needed before the schedule begins.
public struct ScheduleShoppingUseCase: Sendable {
    private let calendar: Calendar
    private let tripIntervalDays: Int
    private let perishableThresholdDays: Int

    public init(
        calendar: Calendar = .current,
        tripIntervalDays: Int = 7,
        perishableThresholdDays: Int = 5
    ) {
        self.calendar = calendar
        self.tripIntervalDays = max(1, tripIntervalDays)
        self.perishableThresholdDays = max(1, perishableThresholdDays)
    }

    public func callAsFunction(
        purchases: [PlannedPurchase],
        from referenceDate: Date = .now
    ) -> [ShoppingTrip] {
        guard !purchases.isEmpty else { return [] }

        let start = calendar.startOfDay(for: referenceDate)
        let tripDates = makeTripDates(from: start, covering: purchases)
        guard let firstTrip = tripDates.first else { return [] }

        // Bucket each purchase onto its chosen trip date.
        var buckets: [Date: [ScheduledPurchase]] = [:]
        for purchase in purchases {
            let neededDay = calendar.startOfDay(for: purchase.neededOn)
            let perishable = isPerishable(purchase)
            let tripDate = chooseTrip(
                for: purchase,
                neededDay: neededDay,
                perishable: perishable,
                tripDates: tripDates,
                firstTrip: firstTrip
            )
            buckets[tripDate, default: []].append(
                ScheduledPurchase(
                    name: purchase.name,
                    quantity: purchase.quantity,
                    unit: purchase.unit,
                    neededOn: neededDay,
                    isPerishable: perishable
                )
            )
        }

        return buckets
            .map { date, items in
                ShoppingTrip(
                    date: date,
                    items: items.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                )
            }
            .sorted { $0.date < $1.date }
    }

    /// A purchase is perishable when it has a known shelf life shorter than the
    /// threshold; everything else is treated as shelf-stable.
    private func isPerishable(_ purchase: PlannedPurchase) -> Bool {
        guard let shelfLife = purchase.shelfLifeDays else { return false }
        return shelfLife < perishableThresholdDays
    }

    /// Trip dates from `start` at the configured cadence, up to and including a
    /// trip on or after the latest needed day.
    private func makeTripDates(from start: Date, covering purchases: [PlannedPurchase]) -> [Date] {
        let latestNeeded = purchases
            .map { calendar.startOfDay(for: $0.neededOn) }
            .max() ?? start
        var dates: [Date] = []
        var current = start
        while current <= latestNeeded || dates.isEmpty {
            dates.append(current)
            guard let next = calendar.date(byAdding: .day, value: tripIntervalDays, to: current) else { break }
            current = next
        }
        return dates
    }

    private func chooseTrip(
        for purchase: PlannedPurchase,
        neededDay: Date,
        perishable: Bool,
        tripDates: [Date],
        firstTrip: Date
    ) -> Date {
        // Item needed before the schedule starts: buy on the first trip.
        guard neededDay >= firstTrip else { return firstTrip }

        let feasible = tripDates.filter { $0 <= neededDay }
        guard let lastFeasible = feasible.last else { return firstTrip }

        guard perishable, let shelfLife = purchase.shelfLifeDays else {
            // Shelf-stable: consolidate onto the earliest trip.
            return firstTrip
        }

        // Perishable: prefer the latest trip inside the freshness window.
        let earliestFresh = calendar.date(byAdding: .day, value: -shelfLife, to: neededDay) ?? firstTrip
        let inWindow = feasible.filter { $0 >= earliestFresh }
        return inWindow.last ?? lastFeasible
    }
}

/// Maps a meal plan into planned purchases and schedules them into shopping
/// trips. Bridges the persisted `MealPlan` to the pure `ScheduleShoppingUseCase`.
///
/// Only ingredients not already available in the pantry are included. An
/// ingredient's perishability is derived from its linked product's category and
/// the chosen storage location; unlinked ingredients are treated as shelf-stable.
public struct ScheduleShoppingFromMealPlanUseCase: Sendable {
    private let calendar: Calendar
    private let scheduler: ScheduleShoppingUseCase

    public init(
        calendar: Calendar = .current,
        scheduler: ScheduleShoppingUseCase? = nil
    ) {
        self.calendar = calendar
        self.scheduler = scheduler ?? ScheduleShoppingUseCase(calendar: calendar)
    }

    public func callAsFunction(
        plan: MealPlan,
        productsByID: [UUID: Product] = [:],
        storageLocation: StorageLocation = .fridge,
        from referenceDate: Date = .now
    ) -> [ShoppingTrip] {
        let planStart = calendar.startOfDay(for: plan.startDate)

        // Aggregate missing ingredients by name+unit, keeping the earliest needed day.
        var aggregated: [String: PlannedPurchase] = [:]
        for meal in plan.meals {
            let neededOn = calendar.date(byAdding: .day, value: max(0, meal.dayIndex), to: planStart) ?? planStart
            for ingredient in meal.ingredients where !ingredient.isAvailableInPantry {
                let key = ingredient.name.lowercased() + "|" + ingredient.unit.rawValue
                let shelfLife = shelfLifeDays(for: ingredient, productsByID: productsByID, storageLocation: storageLocation)
                if let existing = aggregated[key] {
                    aggregated[key] = PlannedPurchase(
                        name: existing.name,
                        quantity: existing.quantity + ingredient.quantity,
                        unit: existing.unit,
                        neededOn: min(existing.neededOn, neededOn),
                        shelfLifeDays: existing.shelfLifeDays ?? shelfLife
                    )
                } else {
                    aggregated[key] = PlannedPurchase(
                        name: ingredient.name,
                        quantity: ingredient.quantity,
                        unit: ingredient.unit,
                        neededOn: neededOn,
                        shelfLifeDays: shelfLife
                    )
                }
            }
        }

        return scheduler(purchases: Array(aggregated.values), from: referenceDate)
    }

    private func shelfLifeDays(
        for ingredient: MealIngredient,
        productsByID: [UUID: Product],
        storageLocation: StorageLocation
    ) -> Int? {
        guard let id = ingredient.linkedProductID, let product = productsByID[id] else { return nil }
        return EstimateExpiryDateUseCase.shelfLifeDays(
            category: product.category,
            storageLocation: storageLocation
        )
    }
}
