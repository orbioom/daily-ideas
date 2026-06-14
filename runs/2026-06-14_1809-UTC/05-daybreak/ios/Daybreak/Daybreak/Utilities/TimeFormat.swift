import Foundation

/// Small shared time formatting helpers.
enum TimeFormat {
    /// Whole seconds → "m:ss" (e.g. 90 → "1:30"). Guards negatives.
    static func clock(_ seconds: Int) -> String {
        let s = max(0, seconds)
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    /// Human duration for est. minutes / totals (e.g. 0 → "Untimed", 1 → "1 min").
    static func minutesLabel(_ minutes: Int) -> String {
        if minutes <= 0 { return "Untimed" }
        return "\(minutes) min"
    }

    /// Spoken-friendly remaining time for accessibility (e.g. "1 minute 30 seconds").
    static func spoken(_ seconds: Int) -> String {
        let s = max(0, seconds)
        let m = s / 60
        let r = s % 60
        switch (m, r) {
        case (0, _): return "\(r) seconds"
        case (_, 0): return "\(m) minute\(m == 1 ? "" : "s")"
        default: return "\(m) minute\(m == 1 ? "" : "s") \(r) seconds"
        }
    }
}
