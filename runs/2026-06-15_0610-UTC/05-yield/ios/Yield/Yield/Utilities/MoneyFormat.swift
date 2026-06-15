import Foundation

/// Centralized money/number formatting. Currency code is user-selectable (Settings).
enum MoneyFormat {

    /// Format a Decimal as currency for the given ISO code, e.g. "$1,240.50".
    static func currency(_ value: Decimal, code: String = "USD", fractionDigits: Int = 2) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = code
        f.minimumFractionDigits = fractionDigits
        f.maximumFractionDigits = fractionDigits
        let number = NSDecimalNumber(decimal: value)
        return f.string(from: number) ?? fallback(value, fractionDigits: fractionDigits)
    }

    /// Compact currency for headers: whole dollars when large, cents when small.
    static func currencyCompact(_ value: Decimal, code: String = "USD") -> String {
        let abs = value.magnitude
        let digits = abs >= 1000 ? 0 : 2
        return currency(value, code: code, fractionDigits: digits)
    }

    /// Per-share style with up to 4 decimals (dividends are often fractional).
    static func perShare(_ value: Decimal, code: String = "USD") -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = code
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 4
        let number = NSDecimalNumber(decimal: value)
        return f.string(from: number) ?? fallback(value, fractionDigits: 4)
    }

    /// Percentage from a *ratio* (0.042 → "4.20%").
    static func percent(_ ratio: Double, fractionDigits: Int = 2) -> String {
        guard ratio.isFinite else { return "—" }
        let f = NumberFormatter()
        f.numberStyle = .percent
        f.minimumFractionDigits = fractionDigits
        f.maximumFractionDigits = fractionDigits
        return f.string(from: NSNumber(value: ratio)) ?? String(format: "%.\(fractionDigits)f%%", ratio * 100)
    }

    /// Plain share count, trimming trailing zeros (e.g. "12.5", "100").
    static func shares(_ value: Decimal) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 4
        let number = NSDecimalNumber(decimal: value)
        return f.string(from: number) ?? "\(value)"
    }

    private static func fallback(_ value: Decimal, fractionDigits: Int) -> String {
        let number = NSDecimalNumber(decimal: value)
        return String(format: "%.\(fractionDigits)f", number.doubleValue)
    }
}

extension Decimal {
    /// Safe Double conversion for chart plotting only (never for money math).
    var doubleValue: Double { NSDecimalNumber(decimal: self).doubleValue }
}
