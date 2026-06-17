import Foundation

/// Currency & percent formatting plus safe numeric parsing.
enum Format {

    private static let currency: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 2
        return f
    }()

    private static let currencyWhole: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.maximumFractionDigits = 0
        f.minimumFractionDigits = 0
        return f
    }()

    /// Formats a Decimal as USD. `whole` rounds to whole dollars.
    static func currency(_ value: Decimal, whole: Bool = false) -> String {
        let formatter = whole ? currencyWhole : currency
        let number = NSDecimalNumber(decimal: value)
        return formatter.string(from: number) ?? "$0"
    }

    /// Formats a 0...1 fraction as a percent string, e.g. 0.225 → "22.5%".
    static func percent(_ fraction: Decimal, fractionDigits: Int = 1) -> String {
        let pct = fraction * 100
        let number = NSDecimalNumber(decimal: pct)
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = fractionDigits
        f.minimumFractionDigits = 0
        let s = f.string(from: number) ?? "0"
        return "\(s)%"
    }

    /// Spoken currency for accessibility, e.g. "$1,234.56" → "1234 dollars and 56 cents".
    static func currencySpoken(_ value: Decimal, whole: Bool = false) -> String {
        currency(value, whole: whole)
    }
}

/// Safe parsing of user text into Decimal. Never force-unwraps and never crashes.
enum Parse {
    /// Parses a decimal from free text, stripping currency symbols, commas, and spaces.
    /// Returns nil on empty / invalid input. Negative results return nil (rejected).
    static func decimal(_ text: String) -> Decimal? {
        let cleaned = text
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "%", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return nil }
        // Decimal(string:) can return nil — never force-unwrap it.
        guard let value = Decimal(string: cleaned, locale: Locale(identifier: "en_US_POSIX")) else {
            return nil
        }
        guard value >= 0, !value.isNaN else { return nil }
        return value
    }

    /// Parses but defaults to 0 when invalid (used where 0 is a sensible blank value).
    static func decimalOrZero(_ text: String) -> Decimal {
        decimal(text) ?? 0
    }
}
