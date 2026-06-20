import Foundation

func formatCurrency(_ amount: Decimal, code: String = "USD") -> String {
    let fmt = NumberFormatter()
    fmt.numberStyle = .currency
    fmt.currencyCode = code
    fmt.locale = Locale.current
    return fmt.string(from: amount as NSDecimalNumber) ?? "\(code) \(amount)"
}

func parseCurrencyInput(_ text: String) -> Decimal? {
    let cleaned = text.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
    guard !cleaned.isEmpty else { return nil }
    return Decimal(string: cleaned)
}

func parseDecimalInput(_ text: String) -> Decimal {
    let cleaned = text.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
    return Decimal(string: cleaned) ?? Decimal(0)
}
