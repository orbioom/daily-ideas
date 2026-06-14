import Foundation

/// Money / number / date formatting helpers. Currency symbol is driven by the
/// user's setting; we keep full precision in the engine and only round here.
enum Fmt {

    private static func currencyFormatter(symbol: String, fractionDigits: Int) -> NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencySymbol = symbol
        f.minimumFractionDigits = fractionDigits
        f.maximumFractionDigits = fractionDigits
        f.usesGroupingSeparator = true
        return f
    }

    /// Money with cents, e.g. "$1,234.56".
    static func money(_ value: Double, symbol: String) -> String {
        let v = value.isFinite ? value : 0
        return currencyFormatter(symbol: symbol, fractionDigits: 2)
            .string(from: NSNumber(value: v)) ?? "\(symbol)0.00"
    }

    /// Money rounded to whole units, e.g. "$1,235".
    static func moneyWhole(_ value: Double, symbol: String) -> String {
        let v = value.isFinite ? value : 0
        return currencyFormatter(symbol: symbol, fractionDigits: 0)
            .string(from: NSNumber(value: v.rounded())) ?? "\(symbol)0"
    }

    /// Percent with up to 2 decimals, e.g. "5.25%".
    static func percent(_ value: Double) -> String {
        let v = value.isFinite ? value : 0
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
        let s = f.string(from: NSNumber(value: v)) ?? "0"
        return "\(s)%"
    }

    /// "Mar 2031"
    static func monthYear(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM yyyy"
        return f.string(from: date)
    }

    /// "Mar 2031" but full month for accessibility.
    static func monthYearLong(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: date)
    }

    /// Convert a month count into a friendly "24 yr 6 mo" / "18 mo" string.
    static func termDescription(months: Int) -> String {
        let m = max(0, months)
        let years = m / 12
        let rem = m % 12
        if years == 0 { return "\(rem) mo" }
        if rem == 0 { return "\(years) yr" }
        return "\(years) yr \(rem) mo"
    }

    /// A precise integer count, e.g. "5 payments".
    static func payments(_ count: Int) -> String {
        count == 1 ? "1 payment" : "\(count) payments"
    }
}
