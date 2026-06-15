import Foundation

/// Formats `Decimal` money values for display, using the card's currency code.
enum Money {
    static func string(_ amount: Decimal, code: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        let number = NSDecimalNumber(decimal: amount)
        return formatter.string(from: number) ?? "\(code) \(amount)"
    }

    /// Parse user input ("12.50", "$12.50", "12,50") into a non-negative Decimal.
    static func parse(_ input: String) -> Decimal? {
        let cleaned = input
            .replacingOccurrences(of: ",", with: ".")
            .filter { $0.isNumber || $0 == "." }
        guard !cleaned.isEmpty else { return nil }
        guard let value = Decimal(string: cleaned), value >= 0 else { return nil }
        return value
    }
}
