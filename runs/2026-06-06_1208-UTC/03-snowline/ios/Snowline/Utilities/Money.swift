import Foundation

/// Currency formatting driven by a stored currency code.
enum Money {
    static func string(_ value: Double, code: String, fraction: Bool = false) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = code
        f.maximumFractionDigits = fraction ? 2 : 0
        f.minimumFractionDigits = fraction ? 2 : 0
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }
    /// Currency symbol for a code (e.g. "$", "£"), falling back to the code.
    static func symbol(for code: String) -> String {
        let locale = Locale(identifier: "en_US")
        if let s = (NSLocale(localeIdentifier: "en_US@currency=\(code)") as Locale).currencySymbol,
           s != code { return s }
        _ = locale
        return code + " "
    }
    /// Compact form for large totals (e.g. $12.4k).
    static func compact(_ value: Double, code: String) -> String {
        let sym = symbol(for: code)
        if abs(value) >= 10_000 {
            return sym + String(format: "%.1fk", value / 1000)
        }
        return string(value, code: code)
    }
}
