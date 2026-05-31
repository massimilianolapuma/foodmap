import Foundation

/// A purchase the user needs to make for a meal plan, described independently of
/// any UI or persistence so the scheduling logic stays pure and testable.
///
/// `shelfLifeDays` carries the product's conservative shelf life when known.
/// `nil` means the item is shelf-stable (or its perishability is unknown) and
/// can safely be bought early and stockpiled.
public struct PlannedPurchase: Equatable, Sendable {
    public let name: String
    public let quantity: Double
    public let unit: MeasurementUnit
    /// The first day the item is needed for the plan.
    public let neededOn: Date
    /// Conservative shelf life in days, or `nil` for shelf-stable items.
    public let shelfLifeDays: Int?

    public init(
        name: String,
        quantity: Double,
        unit: MeasurementUnit,
        neededOn: Date,
        shelfLifeDays: Int? = nil
    ) {
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.neededOn = neededOn
        self.shelfLifeDays = shelfLifeDays
    }
}

/// A purchase placed onto a concrete shopping trip.
public struct ScheduledPurchase: Equatable, Sendable {
    public let name: String
    public let quantity: Double
    public let unit: MeasurementUnit
    /// The day the item is needed (carried through for display/sorting).
    public let neededOn: Date
    /// `true` when the item is perishable and was scheduled close to when it is
    /// needed; `false` when it is shelf-stable and bought early.
    public let isPerishable: Bool

    public init(
        name: String,
        quantity: Double,
        unit: MeasurementUnit,
        neededOn: Date,
        isPerishable: Bool
    ) {
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.neededOn = neededOn
        self.isPerishable = isPerishable
    }
}

/// A single shopping outing on a given date, with the items to buy then.
public struct ShoppingTrip: Equatable, Sendable, Identifiable {
    public let id: UUID
    public let date: Date
    public let items: [ScheduledPurchase]

    public init(id: UUID = UUID(), date: Date, items: [ScheduledPurchase]) {
        self.id = id
        self.date = date
        self.items = items
    }
}
