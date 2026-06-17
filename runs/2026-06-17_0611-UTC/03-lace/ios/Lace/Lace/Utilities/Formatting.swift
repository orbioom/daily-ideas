import Foundation

/// Lightweight formatting helpers used across the app. Division-guarded and
/// locale-aware where it matters.
enum Fmt {

    /// "5:00", "12:30", or "1:02:05" from a non-negative seconds count.
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

    /// Compact minutes label, e.g. "28 min".
    static func minutes(_ seconds: Int) -> String {
        let m = Int((Double(max(0, seconds)) / 60.0).rounded())
        return "\(m) min"
    }

    /// A short, human spoken duration for accessibility, e.g. "45 seconds" / "1 minute 30 seconds".
    static func spokenDuration(_ seconds: Int) -> String {
        let s = max(0, seconds)
        let m = s / 60
        let sec = s % 60
        if m == 0 { return "\(sec) second\(sec == 1 ? "" : "s")" }
        if sec == 0 { return "\(m) minute\(m == 1 ? "" : "s")" }
        return "\(m) minute\(m == 1 ? "" : "s") \(sec) second\(sec == 1 ? "" : "s")"
    }

    /// Percentage from a 0...1 fraction (clamped, division already done upstream).
    static func percent(_ fraction: Double) -> String {
        let clamped = min(1.0, max(0.0, fraction))
        return "\(Int((clamped * 100).rounded()))%"
    }

    /// A date formatted as e.g. "Jun 17".
    static func mediumDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }

    /// A date formatted as e.g. "Jun 17, 2026".
    static func longDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }

    /// Weekday short label, e.g. "Tue".
    static func weekday(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f.string(from: date)
    }
}

/// Distance display unit preference.
enum DistanceUnit: String, CaseIterable, Identifiable, Codable {
    case km, mi
    var id: String { rawValue }
    var label: String { self == .km ? "km" : "mi" }

    /// Convert meters to the unit's value.
    func fromMeters(_ meters: Double) -> Double {
        self == .km ? meters / 1000.0 : meters / 1609.344
    }

    /// Convert a value in this unit to meters.
    func toMeters(_ value: Double) -> Double {
        self == .km ? value * 1000.0 : value * 1609.344
    }

    /// Formatted distance, e.g. "5.0 km".
    func format(_ meters: Double) -> String {
        String(format: "%.2f %@", fromMeters(meters), label)
    }
}
