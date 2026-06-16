import Foundation

extension Array {
    /// Safe indexing: returns nil instead of trapping on an out-of-range index.
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

/// Safe Decimal → display string for ticket prices and totals.
/// Uses NSDecimalNumber-friendly formatting and a cached, currency-code-keyed formatter.
enum CurrencyFormatter {
    private static var cache: [String: NumberFormatter] = [:]

    private static func formatter(for code: String) -> NumberFormatter {
        if let existing = cache[code] { return existing }
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = code
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 0
        cache[code] = f
        return f
    }

    /// Format a Decimal amount in the given ISO currency code (e.g. "USD").
    static func string(_ amount: Decimal, code: String) -> String {
        let number = NSDecimalNumber(decimal: amount)
        // NSDecimalNumber.notANumber guards against any malformed value.
        if number == NSDecimalNumber.notANumber {
            return formatter(for: code).string(from: 0) ?? "0"
        }
        if let s = formatter(for: code).string(from: number) {
            return s
        }
        // Fallback: a plain two-decimal rendering with the code appended.
        return "\(code) \(number.doubleValue)"
    }
}
