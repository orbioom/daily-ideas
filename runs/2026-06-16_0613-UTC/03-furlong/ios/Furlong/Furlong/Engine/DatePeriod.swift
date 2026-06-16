import Foundation

/// Period filters used across Dashboard & Reports.
enum DatePeriod: String, CaseIterable, Identifiable {
    case week = "Week"
    case month = "Month"
    case quarter = "Quarter"
    case year = "Year"
    case custom = "Custom"

    var id: String { rawValue }
}

enum PeriodMath {
    /// Returns the [start, end) interval for a period anchored at `reference`.
    /// For `.custom`, callers supply their own range; this returns a year fallback.
    static func interval(for period: DatePeriod,
                         reference: Date = .now,
                         calendar: Calendar = .current) -> DateInterval {
        switch period {
        case .week:
            return calendar.dateInterval(of: .weekOfYear, for: reference)
                ?? fallbackYear(reference, calendar)
        case .month:
            return calendar.dateInterval(of: .month, for: reference)
                ?? fallbackYear(reference, calendar)
        case .quarter:
            return quarterInterval(reference, calendar)
        case .year, .custom:
            return fallbackYear(reference, calendar)
        }
    }

    /// The full calendar year interval for an integer year.
    static func yearInterval(_ year: Int, calendar: Calendar = .current) -> DateInterval {
        var comps = DateComponents()
        comps.year = year
        comps.month = 1
        comps.day = 1
        let start = calendar.date(from: comps) ?? Date(timeIntervalSince1970: 0)
        let end = calendar.date(byAdding: .year, value: 1, to: start) ?? start
        return DateInterval(start: start, end: end)
    }

    private static func fallbackYear(_ reference: Date, _ calendar: Calendar) -> DateInterval {
        calendar.dateInterval(of: .year, for: reference)
            ?? DateInterval(start: reference, duration: 60 * 60 * 24 * 365)
    }

    private static func quarterInterval(_ reference: Date, _ calendar: Calendar) -> DateInterval {
        let month = calendar.component(.month, from: reference)
        let year = calendar.component(.year, from: reference)
        let quarterStartMonth = ((month - 1) / 3) * 3 + 1
        var comps = DateComponents()
        comps.year = year
        comps.month = quarterStartMonth
        comps.day = 1
        let start = calendar.date(from: comps) ?? reference
        let end = calendar.date(byAdding: .month, value: 3, to: start) ?? start
        return DateInterval(start: start, end: end)
    }

    static func contains(_ date: Date, in interval: DateInterval) -> Bool {
        date >= interval.start && date < interval.end
    }
}
