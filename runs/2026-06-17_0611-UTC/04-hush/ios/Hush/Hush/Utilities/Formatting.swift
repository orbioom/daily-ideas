import Foundation

/// Small, allocation-light formatting helpers used across screens.
enum Formatting {

    /// Formats a duration in seconds as `H:MM:SS` or `MM:SS`.
    static func clock(_ seconds: Int) -> String {
        let s = max(0, seconds)
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, sec)
        }
        return String(format: "%02d:%02d", m, sec)
    }

    /// A friendly minutes label, e.g. "45 min" or "1 hr 30 min".
    static func minutesLabel(_ minutes: Int) -> String {
        let m = max(0, minutes)
        if m < 60 { return "\(m) min" }
        let h = m / 60
        let rem = m % 60
        if rem == 0 { return h == 1 ? "1 hr" : "\(h) hr" }
        return "\(h) hr \(rem) min"
    }

    /// A compact total-hours label from seconds, e.g. "12.4 h".
    static func hoursLabel(fromSeconds seconds: Int) -> String {
        let hours = Double(max(0, seconds)) / 3600.0
        return String(format: "%.1f h", hours)
    }

    /// Volume as an integer percentage 0…100.
    static func percent(_ value: Double) -> String {
        "\(Int((min(1, max(0, value)) * 100).rounded()))%"
    }

    static let dayMonth: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE d MMM"
        return f
    }()

    static let shortDay: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "E"
        return f
    }()
}
