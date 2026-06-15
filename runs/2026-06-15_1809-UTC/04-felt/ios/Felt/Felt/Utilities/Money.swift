import Foundation

/// Centralized, guarded money formatting. All money is `Decimal`.
enum Money {
    /// Format a Decimal as currency with a leading symbol, e.g. "$1,250" or "-$80".
    /// Whole amounts drop decimals; fractional amounts show two places.
    static func string(_ value: Decimal, symbol: String, signed: Bool = false) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.minimumFractionDigits = 0
        // Show cents only when the amount isn't whole.
        formatter.maximumFractionDigits = isWhole(value) ? 0 : 2

        let magnitude = abs(value)
        let number = NSDecimalNumber(decimal: magnitude)
        let core = formatter.string(from: number) ?? "0"

        let sign: String
        if value < 0 {
            sign = "-"
        } else if signed && value > 0 {
            sign = "+"
        } else {
            sign = ""
        }
        return "\(sign)\(symbol)\(core)"
    }

    /// Plain non-currency decimal string (e.g. for ROI inputs), guarded.
    static func plain(_ value: Decimal, fractionDigits: Int = 0) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = max(0, fractionDigits)
        return formatter.string(from: NSDecimalNumber(decimal: value)) ?? "0"
    }

    /// Whether a decimal has no fractional component.
    static func isWhole(_ value: Decimal) -> Bool {
        var v = value
        var rounded = Decimal()
        NSDecimalRound(&rounded, &v, 0, .plain)
        return rounded == value
    }

    /// Parse user text into a Decimal, returning nil on empty/invalid input.
    static func parse(_ text: String) -> Decimal? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        // Strip common currency symbols, grouping separators, and whitespace.
        let cleaned = trimmed
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: "£", with: "")
            .replacingOccurrences(of: "€", with: "")
            .trimmingCharacters(in: .whitespaces)
        guard !cleaned.isEmpty else { return nil }
        return Decimal(string: cleaned)
    }

    /// Format a percentage value (0–100) as e.g. "54%".
    static func percent(_ value: Double, fractionDigits: Int = 0) -> String {
        let clamped = value.isFinite ? value : 0
        return String(format: "%.\(max(0, fractionDigits))f%%", clamped)
    }
}

/// Helpers for showing a session duration like "3h 20m".
enum DurationFormat {
    static func string(minutes: Int) -> String {
        let m = max(0, minutes)
        let h = m / 60
        let rem = m % 60
        if h == 0 { return "\(rem)m" }
        if rem == 0 { return "\(h)h" }
        return "\(h)h \(rem)m"
    }

    /// Compact hours with one decimal, guarded.
    static func hoursString(minutes: Int) -> String {
        let hrs = Double(max(0, minutes)) / 60.0
        return String(format: "%.1fh", hrs)
    }
}
