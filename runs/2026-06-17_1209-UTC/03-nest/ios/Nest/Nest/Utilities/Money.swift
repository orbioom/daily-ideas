import Foundation

/// Currency formatting helpers. All money math is done in `Decimal`; values are stored as `Double`.
enum Money {
    /// Format a Double amount using the provided currency code & symbol.
    static func string(_ value: Double,
                       code: String,
                       symbol: String,
                       fractionDigits: Int = 2) -> String {
        format(Decimal(value), code: code, symbol: symbol, fractionDigits: fractionDigits)
    }

    /// Format a Decimal amount.
    static func format(_ value: Decimal,
                       code: String,
                       symbol: String,
                       fractionDigits: Int = 2) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.currencySymbol = symbol
        formatter.maximumFractionDigits = fractionDigits
        formatter.minimumFractionDigits = fractionDigits
        let number = NSDecimalNumber(decimal: value)
        if let s = formatter.string(from: number) {
            return s
        }
        // Calm fallback that never crashes.
        let plain = (value as NSDecimalNumber).doubleValue
        return symbol + String(format: "%.\(fractionDigits)f", plain)
    }

    /// Compact form for charts/axes, e.g. "$1.2k".
    static func compact(_ value: Double, symbol: String) -> String {
        let v = value
        let absV = abs(v)
        let sign = v < 0 ? "-" : ""
        if absV >= 1_000_000 {
            return "\(sign)\(symbol)\(trim(absV / 1_000_000))M"
        } else if absV >= 1_000 {
            return "\(sign)\(symbol)\(trim(absV / 1_000))k"
        } else {
            return "\(sign)\(symbol)\(Int(absV.rounded()))"
        }
    }

    private static func trim(_ value: Double) -> String {
        let rounded = (value * 10).rounded() / 10
        if rounded == rounded.rounded() {
            return String(Int(rounded))
        }
        return String(format: "%.1f", rounded)
    }

    /// Round a Decimal to a given scale using bankers-safe plain rounding.
    static func round(_ value: Decimal, scale: Int = 2) -> Decimal {
        var input = value
        var result = Decimal()
        NSDecimalRound(&result, &input, scale, .plain)
        return result
    }
}
