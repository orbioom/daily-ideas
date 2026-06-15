import Foundation

/// Shared, cached formatters and small numeric helpers used across screens.
enum Fmt {
    static let mediumDate: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    static let monthYear: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return f
    }()

    static let shortDate: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .none
        return f
    }()

    /// Group an integer with locale-aware thousands separators ("12,480").
    static func grouped(_ n: Int) -> String {
        numberFormatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }

    /// One decimal place ("42.7").
    static func oneDecimal(_ d: Double) -> String {
        decimalFormatter.string(from: NSNumber(value: d)) ?? String(format: "%.1f", d)
    }

    private static let numberFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f
    }()

    private static let decimalFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 1
        f.maximumFractionDigits = 1
        return f
    }()

    /// "3 years, 2 months, 5 days" from DateComponents, dropping zero parts.
    static func ageString(_ comps: DateComponents) -> String {
        var parts: [String] = []
        if let y = comps.year, y > 0 { parts.append("\(y) " + (y == 1 ? "year" : "years")) }
        if let m = comps.month, m > 0 { parts.append("\(m) " + (m == 1 ? "month" : "months")) }
        if let d = comps.day, d > 0 { parts.append("\(d) " + (d == 1 ? "day" : "days")) }
        return parts.isEmpty ? "just born" : parts.joined(separator: ", ")
    }
}
