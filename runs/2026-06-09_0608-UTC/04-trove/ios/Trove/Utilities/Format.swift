import Foundation

/// Small, dependency-free formatting helpers shared across views. Currency
/// formatting is locale-aware and never crashes on an unknown code.
enum Format {

    /// Formats an amount as currency for the given ISO code (e.g. "USD").
    /// Falls back gracefully so it can never crash on a malformed code.
    static func currency(_ amount: Double, code: String) -> String {
        let value = amount.isFinite ? amount : 0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.maximumFractionDigits = hasCents(value) ? 2 : 0
        formatter.minimumFractionDigits = 0
        if let s = formatter.string(from: NSNumber(value: value)) {
            return s
        }
        // Fallback: symbol + plain number.
        return "\(symbol(for: code))\(String(format: "%.0f", value))"
    }

    private static func hasCents(_ value: Double) -> Bool {
        abs(value.rounded() - value) > 0.005
    }

    /// A best-effort currency symbol for the supported codes.
    static func symbol(for code: String) -> String {
        switch code {
        case "USD", "CAD", "AUD": return "$"
        case "EUR": return "€"
        case "GBP": return "£"
        case "JPY": return "¥"
        default:    return "$"
        }
    }

    static let shortDay: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    static let fullDay: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f
    }()

    static let monthDayYear: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f
    }()

    /// A friendly countdown phrase from a day delta.
    static func countdown(daysAway: Int) -> String {
        switch daysAway {
        case ..<0:  return "Passed"
        case 0:     return "Today"
        case 1:     return "Tomorrow"
        case 2...6: return "In \(daysAway) days"
        default:
            let weeks = Int((Double(daysAway) / 7).rounded())
            if daysAway < 60 { return "In \(weeks) week\(weeks == 1 ? "" : "s")" }
            let months = Int((Double(daysAway) / 30).rounded())
            return "In \(months) month\(months == 1 ? "" : "s")"
        }
    }

    static func relativeDay(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        if cal.isDateInTomorrow(date) { return "Tomorrow" }
        return shortDay.string(from: date)
    }
}

/// Supported currencies for the Settings picker.
enum CurrencyOption: String, CaseIterable, Identifiable {
    case usd = "USD"
    case eur = "EUR"
    case gbp = "GBP"
    case jpy = "JPY"
    case cad = "CAD"
    case aud = "AUD"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .usd: return "US Dollar (USD)"
        case .eur: return "Euro (EUR)"
        case .gbp: return "British Pound (GBP)"
        case .jpy: return "Japanese Yen (JPY)"
        case .cad: return "Canadian Dollar (CAD)"
        case .aud: return "Australian Dollar (AUD)"
        }
    }
}
