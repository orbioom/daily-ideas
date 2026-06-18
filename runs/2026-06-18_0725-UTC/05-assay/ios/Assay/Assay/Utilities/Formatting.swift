import Foundation

/// Number / date formatting helpers used across the app.
enum Fmt {
    /// Formats a measurement value with sensible precision for its magnitude.
    static func value(_ v: Double) -> String {
        guard v.isFinite else { return "—" }
        let abs = Swift.abs(v)
        let digits: Int
        if abs >= 100 { digits = 0 }
        else if abs >= 10 { digits = 1 }
        else { digits = 2 }
        return number(v, digits: digits)
    }

    static func number(_ v: Double, digits: Int) -> String {
        guard v.isFinite else { return "—" }
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = max(0, digits)
        return f.string(from: NSNumber(value: v)) ?? String(format: "%.\(max(0, digits))f", v)
    }

    /// Signed percentage, e.g. "+12%" / "-4%".
    static func signedPercent(_ p: Double) -> String {
        guard p.isFinite else { return "—" }
        let rounded = (p * 10).rounded() / 10
        let sign = rounded > 0 ? "+" : ""
        return "\(sign)\(number(rounded, digits: 1))%"
    }

    static func signedValue(_ v: Double) -> String {
        guard v.isFinite else { return "—" }
        let sign = v > 0 ? "+" : ""
        return "\(sign)\(value(v))"
    }

    static let mediumDate: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    static let shortDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f
    }()

    static func date(_ d: Date) -> String { mediumDate.string(from: d) }
    static func shortDateString(_ d: Date) -> String { shortDate.string(from: d) }

    static func monthYear(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM yyyy"
        return f.string(from: d)
    }
}
