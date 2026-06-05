import Foundation

/// Decimal-based currency formatting and safe parsing. Never uses Double for money.
enum Money {

    /// Format an amount with the group's symbol and 2 minor digits, e.g. "$1,240.50".
    static func string(_ amount: Decimal, symbol: String) -> String {
        let formatter = sharedFormatter
        let number = NSDecimalNumber(decimal: amount)
        let body = formatter.string(from: number) ?? number.stringValue
        return symbol + body
    }

    /// Signed format with a leading +/- for balances (zero renders without a sign).
    static func signedString(_ amount: Decimal, symbol: String) -> String {
        if amount == 0 { return string(0, symbol: symbol) }
        let magnitude = string(abs(amount), symbol: symbol)
        return (amount > 0 ? "+" : "−") + magnitude
    }

    /// Parse user text into a positive Decimal amount, or nil if invalid/non-positive.
    /// Tolerates thousands separators and stray whitespace; rejects negatives & zero.
    static func parse(_ text: String) -> Decimal? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        // Strip grouping separators and any currency symbols, keep digits + a decimal point.
        let cleaned = trimmed
            .replacingOccurrences(of: ",", with: "")
            .filter { $0.isNumber || $0 == "." }
        guard !cleaned.isEmpty else { return nil }
        guard let value = Decimal(string: cleaned) else { return nil }
        guard value > 0 else { return nil }
        return value
    }

    /// Parse a weight (shares mode): non-negative Decimal, allows zero.
    static func parseWeight(_ text: String) -> Decimal? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let cleaned = trimmed
            .replacingOccurrences(of: ",", with: "")
            .filter { $0.isNumber || $0 == "." }
        guard let value = Decimal(string: cleaned), value >= 0 else { return nil }
        return value
    }

    private static let sharedFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        f.usesGroupingSeparator = true
        return f
    }()
}
