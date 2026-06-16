import Foundation

/// Centralized formatting for money, percentages and dates.
/// All money math uses `Decimal`; formatting converts only at the boundary.
enum Money {
    /// Rounds a Decimal to `scale` fractional digits using banker's-safe plain rounding.
    static func round(_ value: Decimal, scale: Int = 2) -> Decimal {
        var input = value
        var result = Decimal()
        NSDecimalRound(&result, &input, scale, .plain)
        return result
    }

    static func format(_ value: Decimal, currencyCode: String, fractionDigits: Int = 0) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.maximumFractionDigits = fractionDigits
        formatter.minimumFractionDigits = fractionDigits
        let rounded = round(value, scale: fractionDigits)
        if let string = formatter.string(from: rounded as NSDecimalNumber) {
            return string
        }
        return "\(symbol(for: currencyCode))\(rounded)"
    }

    /// Signed currency, e.g. "+$1,200" / "-$340".
    static func formatSigned(_ value: Decimal, currencyCode: String, fractionDigits: Int = 0) -> String {
        let base = format(abs(value), currencyCode: currencyCode, fractionDigits: fractionDigits)
        if value < 0 { return "-\(base)" }
        if value > 0 { return "+\(base)" }
        return base
    }

    static func symbol(for currencyCode: String) -> String {
        let locale = Locale(identifier: "en_US")
        if let symbol = locale.localizedCurrencySymbol(forCurrencyCode: currencyCode) {
            return symbol
        }
        return currencyCode
    }
}

extension Locale {
    func localizedCurrencySymbol(forCurrencyCode code: String) -> String? {
        switch code {
        case "USD": return "$"
        case "EUR": return "€"
        case "GBP": return "£"
        case "CAD": return "CA$"
        case "AUD": return "A$"
        default:
            return self.currencySymbol
        }
    }
}

enum Percent {
    /// Formats a fractional ratio (0.085) as "8.5%".
    static func format(_ ratio: Decimal, fractionDigits: Int = 1) -> String {
        let scaled = ratio * 100
        let rounded = Money.round(scaled, scale: fractionDigits)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = fractionDigits
        formatter.minimumFractionDigits = fractionDigits
        if let string = formatter.string(from: rounded as NSDecimalNumber) {
            return "\(string)%"
        }
        return "\(rounded)%"
    }
}

enum DateText {
    static let monthDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    static let monthYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter
    }()

    static let medium: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    static func monthLabel(_ date: Date) -> String { monthYear.string(from: date) }
    static func short(_ date: Date) -> String { monthDay.string(from: date) }
    static func full(_ date: Date) -> String { medium.string(from: date) }
}
