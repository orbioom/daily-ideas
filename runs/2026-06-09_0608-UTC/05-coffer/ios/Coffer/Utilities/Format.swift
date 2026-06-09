import Foundation

/// Small, dependency-free formatting helpers shared across views.
enum Format {

    /// Currency formatting via the user's chosen ISO code. Uses the modern
    /// `FormatStyle` API which is non-throwing and cannot crash.
    static func currency(_ value: Double, code: String) -> String {
        max(0, value).formatted(.currency(code: code))
    }

    /// A compact currency form for tight rows (e.g. "$1.2K", "$3.4M").
    static func compactCurrency(_ value: Double, code: String) -> String {
        let v = max(0, value)
        let symbol = currencySymbol(for: code)
        switch v {
        case 1_000_000...:
            return "\(symbol)\(trim(v / 1_000_000))M"
        case 10_000...:
            return "\(symbol)\(trim(v / 1_000))K"
        default:
            return currency(v, code: code)
        }
    }

    private static func trim(_ value: Double) -> String {
        if value >= 100 { return String(Int(value.rounded())) }
        return String(format: "%.1f", value)
    }

    static func currencySymbol(for code: String) -> String {
        let locale = Locale(identifier: "en_US")
        return locale.localizedCurrencySymbol(forCurrencyCode: code) ?? "$"
    }

    static let mediumDate: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    static let shortDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f
    }()

    static func date(_ date: Date?) -> String {
        guard let date else { return "—" }
        return mediumDate.string(from: date)
    }

    /// "in 12 days", "today", "5 days ago" style label for a count of days.
    static func daysPhrase(_ days: Int) -> String {
        if days == 0 { return "today" }
        if days == 1 { return "tomorrow" }
        if days == -1 { return "yesterday" }
        if days > 0 { return "in \(days) days" }
        return "\(-days) days ago"
    }
}

private extension Locale {
    func localizedCurrencySymbol(forCurrencyCode code: String) -> String? {
        // Best-effort symbol lookup that works on iOS 17 without crashing.
        let candidates: [String] = ["USD", "EUR", "GBP", "JPY", "CAD", "AUD", "INR", "CHF"]
        let symbols: [String: String] = [
            "USD": "$", "EUR": "€", "GBP": "£", "JPY": "¥",
            "CAD": "$", "AUD": "$", "INR": "₹", "CHF": "Fr"
        ]
        if candidates.contains(code) { return symbols[code] }
        return code
    }
}
