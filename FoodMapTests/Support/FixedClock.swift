import Foundation
@testable import FoodMap

/// Deterministic clock returning a fixed date for tests.
struct FixedClock: Clock {
    let fixed: Date
    func now() -> Date {
        fixed
    }

    static func make(year: Int, month: Int, day: Int) -> FixedClock {
        FixedClock(fixed: .make(year: year, month: month, day: day))
    }
}

extension Calendar {
    /// Gregorian calendar pinned to UTC, matching `ExpiryDateParser`'s date construction.
    static let utcGregorian: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()
}

extension Date {
    /// Builds a UTC-midnight date for the given day, matching `ExpiryDateParser` output.
    static func make(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.utcGregorian.date(from: components)!
    }
}
