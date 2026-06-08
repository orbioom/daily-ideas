import Foundation

/// Formatting helpers used throughout Nocturne.
enum Format {

    // MARK: - Duration

    /// "7h 24m" style from decimal hours.
    static func duration(_ hours: Double) -> String {
        guard hours > 0 else { return "0h 0m" }
        let total  = Int((hours * 60).rounded())
        let h      = total / 60
        let m      = total % 60
        return "\(h)h \(m)m"
    }

    /// "7.4h" style.
    static func hoursDecimal(_ hours: Double) -> String {
        String(format: "%.1fh", hours)
    }

    // MARK: - Clock

    /// Clock string respecting the user's 12/24 preference.
    static func clock(_ date: Date, use24h: Bool) -> String {
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateFormat = use24h ? "HH:mm" : "h:mm a"
        return f.string(from: date)
    }

    /// Clock string from minutes-of-day (0…1439).
    static func clockFromMinutes(_ minutes: Int, use24h: Bool) -> String {
        let h = (minutes / 60) % 24
        let m = minutes % 60
        var components = DateComponents()
        components.hour   = h
        components.minute = m
        let date = Calendar.current.date(from: components) ?? Date()
        return clock(date, use24h: use24h)
    }

    // MARK: - Date display

    static func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: date)
    }

    static func monthYear(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: date)
    }

    static func weekdayShort(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f.string(from: date)
    }

    // MARK: - Quality label

    static func qualityLabel(_ quality: Int) -> String {
        switch quality {
        case 1: return "Poor"
        case 2: return "Fair"
        case 3: return "Okay"
        case 4: return "Good"
        case 5: return "Great"
        default: return "Unknown"
        }
    }

    // MARK: - Debt label with sign

    static func debtSigned(_ hours: Double) -> String {
        if hours < 0 {
            return "+\(hoursDecimal(-hours))"
        }
        return "-\(hoursDecimal(hours))"
    }
}
