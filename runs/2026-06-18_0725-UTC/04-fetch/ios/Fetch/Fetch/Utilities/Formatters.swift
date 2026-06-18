import Foundation

/// Centralized, allocation-light formatting helpers used across screens.
enum Format {
    /// "5:30" or "1:05:30" style elapsed duration from seconds.
    static func clock(_ seconds: Int) -> String {
        let s = max(0, seconds)
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, sec)
        }
        return String(format: "%d:%02d", m, sec)
    }

    /// Compact minutes label, e.g. "12 min".
    static func minutes(fromSeconds seconds: Int) -> String {
        let m = max(0, seconds) / 60
        return "\(m) min"
    }

    static func shortDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "MMM d"
        return df.string(from: date)
    }

    static func relativeDay(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: date), to: cal.startOfDay(for: Date())).day ?? 0
        if days > 1 && days < 7 { return "\(days) days ago" }
        return shortDate(date)
    }

    /// Whole-number age in years from a birthdate, never negative.
    static func age(from birthdate: Date?) -> Int? {
        guard let birthdate else { return nil }
        let years = Calendar.current.dateComponents([.year], from: birthdate, to: Date()).year ?? 0
        return max(0, years)
    }

    /// Friendly age string handling puppies under a year.
    static func ageString(from birthdate: Date?) -> String? {
        guard let birthdate else { return nil }
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: birthdate, to: Date())
        let years = max(0, comps.year ?? 0)
        let months = max(0, comps.month ?? 0)
        if years >= 1 {
            return years == 1 ? "1 yr" : "\(years) yrs"
        }
        if months <= 1 { return "Puppy" }
        return "\(months) mo"
    }
}
