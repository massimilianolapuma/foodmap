import Foundation

/// Parses expiry dates from free-form OCR text in common European/Italian formats.
/// Pure, deterministic, and locale-stable — fully unit-testable.
public struct ExpiryDateParser: Sendable {
    private let referenceCalendar: Calendar

    public init(calendar: Calendar = Calendar(identifier: .gregorian)) {
        referenceCalendar = calendar
    }

    /// Italian and English month abbreviations → month number.
    private static let monthNames: [String: Int] = [
        "gen": 1, "jan": 1,
        "feb": 2,
        "mar": 3,
        "apr": 4,
        "mag": 5, "may": 5,
        "giu": 6, "jun": 6,
        "lug": 7, "jul": 7,
        "ago": 8, "aug": 8,
        "set": 9, "sep": 9,
        "ott": 10, "oct": 10,
        "nov": 11,
        "dic": 12, "dec": 12
    ]

    /// Extracts candidate dates from text, most-plausible first.
    public func parseDates(from text: String) -> [Date] {
        let normalized = text.lowercased()
        var results: [Date] = []

        // ISO-like: 2026-06-12 or 2026/06/12
        scan(normalized, pattern: #"(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})"#) { groups in
            guard let year = Int(groups[0]), let month = Int(groups[1]), let day = Int(groups[2]) else { return nil }
            return makeDate(day: day, month: month, year: year)
        }.forEach { results.append($0) }

        // D/M/Y or D-M-Y with 2- or 4-digit year: 12/06/26, 12-06-2026
        scan(normalized, pattern: #"(\d{1,2})[-/.](\d{1,2})[-/.](\d{2,4})"#) { groups in
            guard let day = Int(groups[0]), let month = Int(groups[1]), var year = Int(groups[2]) else { return nil }
            if year < 100 { year += 2000 }
            return makeDate(day: day, month: month, year: year)
        }.forEach { results.append($0) }

        // D MON YYYY: "12 giu 2026", "12 jun 26"
        scan(normalized, pattern: #"(\d{1,2})\s*([a-z]{3})[a-z]*\.?\s*(\d{2,4})"#) { groups in
            guard let day = Int(groups[0]), let month = Self.monthNames[groups[1]], var year = Int(groups[2]) else { return nil }
            if year < 100 { year += 2000 }
            return makeDate(day: day, month: month, year: year)
        }.forEach { results.append($0) }

        // Deduplicate while preserving order.
        var seen = Set<Date>()
        return results.filter { seen.insert($0).inserted }
    }

    private func makeDate(day: Int, month: Int, year: Int) -> Date? {
        guard (1...12).contains(month), (1...31).contains(day) else { return nil }
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        var calendar = referenceCalendar
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        guard let date = calendar.date(from: components),
              let parsedDay = calendar.dateComponents([.day], from: date).day,
              parsedDay == day else { return nil }
        return date
    }

    private func scan(_ text: String, pattern: String, transform: ([String]) -> Date?) -> [Date] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        var dates: [Date] = []
        regex.enumerateMatches(in: text, range: range) { match, _, _ in
            guard let match else { return }
            var groups: [String] = []
            for index in 1..<match.numberOfRanges {
                guard let groupRange = Range(match.range(at: index), in: text) else { return }
                groups.append(String(text[groupRange]))
            }
            if let date = transform(groups) {
                dates.append(date)
            }
        }
        return dates
    }
}
