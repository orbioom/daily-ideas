import Foundation

/// Formatting helpers for elapsed solve times.
enum TimeFormat {
    /// "m:ss" for under an hour, "h:mm:ss" beyond. Never negative.
    static func clock(_ seconds: Int) -> String {
        let s = max(0, seconds)
        let hrs = s / 3600
        let mins = (s % 3600) / 60
        let secs = s % 60
        if hrs > 0 {
            return String(format: "%d:%02d:%02d", hrs, mins, secs)
        }
        return String(format: "%d:%02d", mins, secs)
    }

    /// Compact label like "1m 42s" or "48s".
    static func compact(_ seconds: Int) -> String {
        let s = max(0, seconds)
        let mins = s / 60
        let secs = s % 60
        if mins > 0 { return "\(mins)m \(secs)s" }
        return "\(secs)s"
    }
}
