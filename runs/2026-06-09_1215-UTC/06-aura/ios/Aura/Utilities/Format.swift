import Foundation

/// Small, dependency-free formatting helpers shared across views.
enum Format {
    /// Live clock for an ongoing attack: "h:mm:ss" or "mm:ss".
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

    /// Human duration from minutes, like "45 min" or "3 h 20 min".
    static func duration(minutes: Int) -> String {
        let mins = max(0, minutes)
        if mins < 60 { return "\(mins) min" }
        let h = mins / 60
        let m = mins % 60
        return m == 0 ? "\(h) h" : "\(h) h \(m) min"
    }

    /// Human duration from hours (Double), rounded sensibly.
    static func hours(_ hours: Double) -> String {
        duration(minutes: Int((hours * 60).rounded()))
    }

    /// A dose like "400 mg" — drops the decimal when whole.
    static func dose(_ mg: Double) -> String {
        if mg <= 0 { return "—" }
        if mg.rounded() == mg { return "\(Int(mg)) mg" }
        return String(format: "%.1f mg", mg)
    }

    static let shortDay: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    static let monthYear: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    static let dayTime: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, h:mm a"
        return f
    }()

    static func relativeDay(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        return shortDay.string(from: date)
    }
}
