import Foundation

/// Centralized time-of-day formatting that honors the user's 24-hour preference.
enum TimeFormat {

    /// "7:05" / "7:05 AM" style for an hour/minute pair.
    static func clock(hour: Int, minute: Int, use24Hour: Bool) -> String {
        let h = min(23, max(0, hour))
        let m = min(59, max(0, minute))
        if use24Hour {
            return String(format: "%02d:%02d", h, m)
        }
        let isPM = h >= 12
        var h12 = h % 12
        if h12 == 0 { h12 = 12 }
        return String(format: "%d:%02d %@", h12, m, isPM ? "PM" : "AM")
    }

    /// The AM/PM suffix alone (empty when 24-hour), for layouts that style it separately.
    static func meridiem(hour: Int, use24Hour: Bool) -> String {
        guard !use24Hour else { return "" }
        return hour >= 12 ? "PM" : "AM"
    }

    /// "7:05" without meridiem (the big numerals); pair with `meridiem` for the suffix.
    static func clockNumerals(hour: Int, minute: Int, use24Hour: Bool) -> String {
        let h = min(23, max(0, hour))
        let m = min(59, max(0, minute))
        if use24Hour {
            return String(format: "%02d:%02d", h, m)
        }
        var h12 = h % 12
        if h12 == 0 { h12 = 12 }
        return String(format: "%d:%02d", h12, m)
    }

    /// Format a `Date`'s time-of-day with the same rules.
    static func clock(_ date: Date, use24Hour: Bool, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.hour, .minute], from: date)
        return clock(hour: c.hour ?? 0, minute: c.minute ?? 0, use24Hour: use24Hour)
    }
}
