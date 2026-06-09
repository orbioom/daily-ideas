import Foundation

/// Small formatting helpers shared across views.
enum Format {
    /// "Jun 9" style short date.
    static func shortDate(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day())
    }

    /// "Jun 9, 2026" style medium date.
    static func mediumDate(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }

    /// "Mon" weekday + short date for detail headers.
    static func longDate(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }

    /// A signed rating delta, e.g. "+0.04" / "-0.02" / "0.00".
    static func signedRating(_ delta: Double) -> String {
        let sign = delta > 0 ? "+" : (delta < 0 ? "" : "")
        return sign + String(format: "%.2f", delta)
    }

    /// Two-decimal rating, e.g. "3.42".
    static func rating(_ value: Double) -> String {
        String(format: "%.2f", value)
    }
}
