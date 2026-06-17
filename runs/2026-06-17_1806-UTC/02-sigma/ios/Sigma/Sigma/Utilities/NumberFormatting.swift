import Foundation

/// Decimal-place preference exposed in Settings.
enum DecimalPlaces: String, CaseIterable, Identifiable {
    case two = "2", four = "4", six = "6", auto = "Auto"
    var id: String { rawValue }

    /// Number of fractional digits, or nil for an adaptive ("Auto") presentation.
    var digits: Int? {
        switch self {
        case .two: return 2
        case .four: return 4
        case .six: return 6
        case .auto: return nil
        }
    }
}

/// Pure number formatting helper used across the display, converter and history.
enum NumberFormatting {
    /// Formats a Double for display.
    /// - Parameters:
    ///   - value: the number to format.
    ///   - grouping: whether to insert thousands separators.
    ///   - places: a fixed number of fractional digits, or nil for adaptive trimming.
    ///   - highPrecision: when true, raises the adaptive ceiling (Pro feature).
    static func string(_ value: Double,
                       grouping: Bool,
                       places: Int?,
                       highPrecision: Bool = false) -> String {
        guard value.isFinite else { return "Error" }

        // Normalize negative zero.
        let v = value == 0 ? 0 : value

        let maxFraction = highPrecision ? 12 : 9

        // Very large or very small magnitudes fall back to scientific notation
        // so the display never overflows into meaningless precision.
        let magnitude = abs(v)
        if magnitude != 0 && (magnitude >= 1e15 || magnitude < 1e-9) {
            let sci = NumberFormatter()
            sci.numberStyle = .scientific
            sci.maximumFractionDigits = highPrecision ? 8 : 6
            sci.exponentSymbol = "e"
            return sci.string(from: NSNumber(value: v)) ?? "Error"
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = grouping
        formatter.groupingSeparator = ","
        formatter.decimalSeparator = "."

        if let places {
            formatter.minimumFractionDigits = places
            formatter.maximumFractionDigits = places
        } else {
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = maxFraction
        }

        return formatter.string(from: NSNumber(value: v)) ?? "Error"
    }

    /// Splits a raw string into integer part, fractional part, and whether a dot exists.
    private static func decimalParts(_ s: String) -> (integer: String, fraction: String, hasDot: Bool) {
        if let dotIndex = s.firstIndex(of: ".") {
            let intPart = String(s[s.startIndex..<dotIndex])
            let fracPart = String(s[s.index(after: dotIndex)...])
            return (intPart, fracPart, true)
        }
        return (s, "", false)
    }

    /// Adds grouping separators to the integer part of a raw input string while
    /// the user is still typing (preserves a trailing decimal point and digits).
    static func groupedInput(_ raw: String, grouping: Bool) -> String {
        guard grouping else { return raw }
        let (intPart, fracPart, hasDot) = decimalParts(raw)

        let negative = intPart.hasPrefix("-")
        let digits = negative ? String(intPart.dropFirst()) : intPart
        guard !digits.isEmpty, digits.allSatisfy(\.isNumber) else { return raw }

        var grouped = ""
        var count = 0
        for ch in digits.reversed() {
            if count != 0 && count % 3 == 0 { grouped.append(",") }
            grouped.append(ch)
            count += 1
        }
        var result = String(grouped.reversed())
        if negative { result = "-" + result }
        if hasDot { result += "." + fracPart }
        return result
    }
}
