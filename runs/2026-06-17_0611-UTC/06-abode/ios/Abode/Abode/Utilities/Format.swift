import Foundation

/// Currency, percent, and date formatting. Currency respects the user's chosen
/// currency code/symbol and the "show cents" preference, configured at launch.
enum Format {

    /// Mutable display preferences, set once from AppSettings (see configure()).
    private static var currencyCode: String = "USD"
    private static var showCents: Bool = false

    /// Called from RootView once settings are available so formatters match prefs.
    static func configure(currencyCode: String, showCents: Bool) {
        Self.currencyCode = currencyCode
        Self.showCents = showCents
    }

    private static func makeFormatter(fractionDigits: Int) -> NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = currencyCode
        f.maximumFractionDigits = fractionDigits
        f.minimumFractionDigits = fractionDigits
        return f
    }

    /// Formats a Decimal as currency. Honors the "show cents" preference unless
    /// `forceCents` / `forceWhole` override it (e.g. a monthly payment always shows cents).
    static func money(_ value: Decimal, forceCents: Bool = false, forceWhole: Bool = false) -> String {
        let digits: Int
        if forceWhole { digits = 0 }
        else if forceCents { digits = 2 }
        else { digits = showCents ? 2 : 0 }
        let formatter = makeFormatter(fractionDigits: digits)
        let number = NSDecimalNumber(decimal: value)
        return formatter.string(from: number) ?? fallback(value, digits: digits)
    }

    private static func fallback(_ value: Decimal, digits: Int) -> String {
        let rounded = value.rounded(digits)
        return "\(currencySymbol)\(rounded)"
    }

    /// The symbol for the chosen currency (e.g. "$"), derived once.
    static var currencySymbol: String {
        let f = makeFormatter(fractionDigits: 0)
        return f.currencySymbol ?? "$"
    }

    /// Formats a fractional rate (0...1) as a percent, e.g. 0.065 → "6.5%".
    static func percentFraction(_ fraction: Decimal, fractionDigits: Int = 2) -> String {
        percentValue(fraction * 100, fractionDigits: fractionDigits)
    }

    /// Formats an already-percentage value (e.g. 6.5 → "6.5%").
    static func percentValue(_ value: Decimal, fractionDigits: Int = 2) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = fractionDigits
        f.minimumFractionDigits = 0
        let n = NSDecimalNumber(decimal: value)
        return "\(f.string(from: n) ?? "0")%"
    }

    /// A plain decimal with grouping separators (e.g. "1,234.5").
    static func number(_ value: Decimal, fractionDigits: Int = 0) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = fractionDigits
        f.minimumFractionDigits = 0
        let n = NSDecimalNumber(decimal: value)
        return f.string(from: n) ?? "0"
    }

    /// "Jun 2026" style month-year used for payoff dates.
    static func monthYear(_ date: Date) -> String {
        monthYearFormatter.string(from: date)
    }

    /// A duration in months expressed as "X yr Y mo".
    static func termFromMonths(_ months: Int) -> String {
        guard months > 0 else { return "0 mo" }
        let years = months / 12
        let rem = months % 12
        if years == 0 { return "\(rem) mo" }
        if rem == 0 { return "\(years) yr" }
        return "\(years) yr \(rem) mo"
    }

    private static let monthYearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("MMMyyyy")
        return f
    }()
}
