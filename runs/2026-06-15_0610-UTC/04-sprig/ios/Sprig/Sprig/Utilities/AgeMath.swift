import Foundation

/// Leap-safe age arithmetic built on `Calendar`/`DateComponents`. All helpers clamp negative
/// ages (a future birth date) to zero so the UI never shows nonsense.
enum AgeMath {
    private static var cal: Calendar { Calendar.current }

    /// Whole completed months between two dates.
    static func months(from birth: Date, to date: Date) -> Int {
        guard date >= birth else { return 0 }
        let comps = cal.dateComponents([.month], from: birth, to: date)
        return max(0, comps.month ?? 0)
    }

    /// Whole completed days between two dates.
    static func days(from birth: Date, to date: Date) -> Int {
        guard date >= birth else { return 0 }
        let comps = cal.dateComponents([.day], from: birth, to: date)
        return max(0, comps.day ?? 0)
    }

    /// Fractional age in months using the average Gregorian month length (30.4375 days).
    /// Used purely to interpolate LMS parameters between table ages — accuracy here is fine.
    static func exactMonths(from birth: Date, to date: Date) -> Double {
        guard date >= birth else { return 0 }
        let seconds = date.timeIntervalSince(birth)
        let daysCount = seconds / 86_400.0
        return max(0, daysCount / 30.4375)
    }

    /// "1 yr 3 mo", "5 mo", "12 days", "Newborn" — compact and parent-friendly.
    static func description(from birth: Date, to date: Date) -> String {
        guard date >= birth else { return "Due soon" }
        let comps = cal.dateComponents([.year, .month, .day], from: birth, to: date)
        let years = max(0, comps.year ?? 0)
        let months = max(0, comps.month ?? 0)
        let days = max(0, comps.day ?? 0)

        if years == 0 && months == 0 {
            if days == 0 { return "Newborn" }
            return days == 1 ? "1 day" : "\(days) days"
        }
        if years == 0 {
            return months == 1 ? "1 mo" : "\(months) mo"
        }
        var parts = ["\(years) yr"]
        if months > 0 { parts.append("\(months) mo") }
        return parts.joined(separator: " ")
    }

    /// The date a child reaches a given age in months (for vaccine due-date math).
    static func date(byAddingMonths months: Int, to birth: Date) -> Date {
        cal.date(byAdding: .month, value: months, to: birth) ?? birth
    }
}
