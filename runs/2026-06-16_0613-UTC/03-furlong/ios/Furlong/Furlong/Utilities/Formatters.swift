import Foundation

/// Shared currency formatting that honors the user's currency-code setting.
enum CurrencyFormatter {
    private static var cache: [String: NumberFormatter] = [:]

    private static func formatter(for code: String) -> NumberFormatter {
        if let f = cache[code] { return f }
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = code
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 2
        cache[code] = f
        return f
    }

    /// Format a Decimal as currency. Falls back to a plain rendering if the
    /// formatter rejects the value (never crashes).
    static func string(_ amount: Decimal, code: String) -> String {
        let f = formatter(for: code)
        if let s = f.string(from: amount as NSDecimalNumber) { return s }
        return "\(code) \(NSDecimalNumber(decimal: amount).doubleValue)"
    }

    /// A compact representation used in dense charts/labels.
    static func compact(_ amount: Decimal, code: String) -> String {
        let value = NSDecimalNumber(decimal: amount).doubleValue
        let symbol = formatter(for: code).currencySymbol ?? ""
        if abs(value) >= 1000 {
            return "\(symbol)\(String(format: "%.1fk", value / 1000))"
        }
        return "\(symbol)\(String(format: "%.0f", value))"
    }
}

enum NumberFormatting {
    private static let miles: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 1
        f.minimumFractionDigits = 0
        return f
    }()

    static func distance(_ value: Double) -> String {
        miles.string(from: NSNumber(value: value)) ?? String(format: "%.1f", value)
    }

    static func percent(_ fraction: Double) -> String {
        "\(Int((fraction * 100).rounded()))%"
    }

    static func odometer(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: value)) ?? String(format: "%.0f", value)
    }
}

enum DateFormatting {
    static let medium: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    static let monthYear: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "LLLL yyyy"
        return f
    }()

    static let monthShort: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "LLL"
        return f
    }()

    static let iso: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
}
