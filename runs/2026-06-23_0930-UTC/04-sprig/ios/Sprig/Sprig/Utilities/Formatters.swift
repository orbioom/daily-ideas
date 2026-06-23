import Foundation

/// Shared, allocation-light formatting helpers used across the app.
enum Fmt {

    /// "3h 12m" / "12m" / "45s" style compact duration.
    static func duration(_ seconds: TimeInterval) -> String {
        let s = max(0, Int(seconds.rounded()))
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        if h > 0 { return "\(h)h \(m)m" }
        if m > 0 { return "\(m)m" }
        return "\(sec)s"
    }

    /// "00:00" / "1:02:33" stopwatch style for live timers.
    static func clock(_ seconds: TimeInterval) -> String {
        let s = max(0, Int(seconds.rounded()))
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, sec)
        }
        return String(format: "%02d:%02d", m, sec)
    }

    /// "2h ago" / "just now" relative phrasing for last-event tiles.
    static func ago(_ date: Date, now: Date = Date()) -> String {
        let delta = max(0, now.timeIntervalSince(date))
        if delta < 60 { return "just now" }
        let m = Int(delta / 60)
        if m < 60 { return "\(m)m ago" }
        let h = m / 60
        let rem = m % 60
        if h < 24 { return rem == 0 ? "\(h)h ago" : "\(h)h \(rem)m ago" }
        let d = h / 24
        return "\(d)d ago"
    }

    private static let timeF: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }()

    private static let dayF: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f
    }()

    private static let shortDayF: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    static func time(_ date: Date) -> String { timeF.string(from: date) }
    static func day(_ date: Date) -> String { dayF.string(from: date) }
    static func shortDay(_ date: Date) -> String { shortDayF.string(from: date) }

    /// Friendly baby age, e.g. "3 mo 4 d" or "12 d".
    static func age(birth: Date, now: Date = Date()) -> String {
        let comps = Calendar.current.dateComponents([.month, .day], from: birth, to: now)
        let months = max(0, comps.month ?? 0)
        let days = max(0, comps.day ?? 0)
        if months <= 0 { return "\(days) day\(days == 1 ? "" : "s")" }
        return "\(months) mo \(days) d"
    }

    /// Trims a number to at most one decimal, dropping a trailing ".0".
    static func num(_ value: Double, decimals: Int = 1) -> String {
        let rounded = (value * pow(10, Double(decimals))).rounded() / pow(10, Double(decimals))
        if rounded == rounded.rounded() {
            return String(Int(rounded))
        }
        return String(format: "%.\(decimals)f", rounded)
    }
}
