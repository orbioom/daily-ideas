import Foundation

/// Shared, locale-aware formatting helpers.
enum Fmt {
    /// Time of day in the given time zone, e.g. "21:43".
    static func time(_ date: Date?, timeZone: TimeZone) -> String {
        guard let date else { return "—" }
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        f.timeZone = timeZone
        return f.string(from: date)
    }

    /// Date + time, e.g. "16 Jun, 21:43".
    static func dateTime(_ date: Date?, timeZone: TimeZone) -> String {
        guard let date else { return "—" }
        let f = DateFormatter()
        f.dateFormat = "d MMM, HH:mm"
        f.timeZone = timeZone
        return f.string(from: date)
    }

    /// Medium date, e.g. "16 Jun 2026".
    static func date(_ date: Date, timeZone: TimeZone = .current) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        f.timeZone = timeZone
        return f.string(from: date)
    }

    static func dateShort(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE d MMM"
        return f.string(from: date)
    }

    /// Degrees with a degree sign, e.g. "42°".
    static func deg(_ value: Double) -> String { "\(Int(value.rounded()))°" }

    /// Magnitude with one decimal, e.g. "mag 1.2".
    static func mag(_ value: Double) -> String { String(format: "mag %.1f", value) }

    /// A signed altitude with sign and degree, e.g. "+42°" or "−12°".
    static func altitude(_ value: Double) -> String {
        let v = Int(value.rounded())
        if v >= 0 { return "+\(v)°" }
        return "−\(abs(v))°"
    }

    /// Latitude/longitude pretty string.
    static func coord(lat: Double, lon: Double) -> String {
        let ns = lat >= 0 ? "N" : "S"
        let ew = lon >= 0 ? "E" : "W"
        return String(format: "%.2f°%@, %.2f°%@", abs(lat), ns, abs(lon), ew)
    }
}
