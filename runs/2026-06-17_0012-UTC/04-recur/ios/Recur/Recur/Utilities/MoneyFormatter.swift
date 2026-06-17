import Foundation

/// Currency + number formatting used across the app. Decimal-first; never crashes.
enum MoneyFormatter {

    /// A short list of common currencies offered in Settings.
    static let currencyOptions: [(code: String, symbol: String)] = [
        ("USD", "$"), ("EUR", "€"), ("GBP", "£"), ("JPY", "¥"),
        ("CAD", "$"), ("AUD", "$"), ("INR", "₹"), ("BRL", "R$"),
        ("CHF", "Fr"), ("SEK", "kr"), ("MXN", "$"), ("ZAR", "R")
    ]

    static func symbol(for code: String) -> String {
        currencyOptions.first { $0.code == code }?.symbol ?? "$"
    }

    /// Formats a Decimal as currency, e.g. "$9.99". Uses the symbol for the code.
    static func string(_ value: Decimal, code: String = "USD", fractionDigits: Int = 2) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        formatter.usesGroupingSeparator = true
        let number = NSDecimalNumber(decimal: CostEngine.rounded2(value))
        let digits = formatter.string(from: number) ?? "0.00"
        return symbol(for: code) + digits
    }

    /// Formats a Decimal with no fractional digits for compact hero displays
    /// when the value is whole; otherwise shows two digits.
    static func compact(_ value: Decimal, code: String = "USD") -> String {
        let rounded = CostEngine.rounded2(value)
        let asDouble = NSDecimalNumber(decimal: rounded).doubleValue
        if asDouble == asDouble.rounded() {
            return string(value, code: code, fractionDigits: 0)
        }
        return string(value, code: code, fractionDigits: 2)
    }

    /// A masked stand-in shown when "hide amounts" privacy mode is on.
    static func masked(code: String = "USD") -> String {
        symbol(for: code) + "•••"
    }
}

/// Date formatting helpers (medium date, relative day phrases).
enum DateText {

    static func medium(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: date)
    }

    static func short(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }

    /// "Today", "Tomorrow", "in 5 days", "3 days ago".
    static func relativeDays(_ days: Int) -> String {
        switch days {
        case 0:             return "Today"
        case 1:             return "Tomorrow"
        case let d where d > 1:  return "in \(d) days"
        case -1:            return "Yesterday"
        default:            return "\(abs(days)) days ago"
        }
    }
}

extension Array {
    /// Safe subscript — returns nil instead of trapping on an out-of-range index.
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
