import Foundation

/// Safe parsing of user text into `Decimal`. Never force-unwraps `Decimal(string:)`
/// and never crashes. Strips currency symbols, grouping separators, percent signs.
enum Parse {

    /// Parses a non-negative decimal from free text. Returns nil on empty / invalid /
    /// negative input. Locale-stable (treats "." as the decimal separator).
    static func decimal(_ text: String) -> Decimal? {
        let cleaned = text
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: "%", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return nil }
        // Decimal(string:) returns an Optional — never force-unwrap it.
        guard let value = Decimal(string: cleaned, locale: Locale(identifier: "en_US_POSIX")) else {
            return nil
        }
        guard value >= 0, !value.isNaN else { return nil }
        return value
    }

    /// Parses but defaults to 0 when invalid (used where blank means zero).
    static func decimalOrZero(_ text: String) -> Decimal {
        decimal(text) ?? 0
    }

    /// Parses a positive integer (e.g. a term in years), returns nil when invalid.
    static func intPositive(_ text: String) -> Int? {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let v = Int(cleaned), v > 0 else { return nil }
        return v
    }
}
