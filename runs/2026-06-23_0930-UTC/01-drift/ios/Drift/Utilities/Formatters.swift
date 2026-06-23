import Foundation

/// Shared display formatting helpers.
enum Format {

    static func clock(_ date: Date, use24h: Bool) -> String {
        let f = DateFormatter()
        f.locale = Locale.current
        f.setLocalizedDateFormatFromTemplate(use24h ? "Hmm" : "hmma")
        return f.string(from: date)
    }

    /// Hours as e.g. "7h 45m".
    static func duration(_ hours: Double) -> String {
        let safe = max(0, hours)
        let totalMinutes = Int((safe * 60).rounded())
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        if h == 0 { return "\(m)m" }
        if m == 0 { return "\(h)h" }
        return "\(h)h \(m)m"
    }

    /// Signed debt, e.g. "+3h 20m" or "On track".
    static func debt(_ hours: Double) -> String {
        if hours < 0.1 { return "On track" }
        return "+\(duration(hours))"
    }

    static func dayShort(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale.current
        f.setLocalizedDateFormatFromTemplate("EEE")
        return f.string(from: date)
    }

    static func dateMedium(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateStyle = .medium
        return f.string(from: date)
    }

    static func relativeNight(_ date: Date, calendar: Calendar = .current) -> String {
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        let f = DateFormatter()
        f.locale = Locale.current
        f.setLocalizedDateFormatFromTemplate("EEEMMMd")
        return f.string(from: date)
    }
}
