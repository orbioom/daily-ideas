import Foundation

/// Shared, cached formatters. Currency & percent figures are the hero of the UI,
/// so they are formatted consistently everywhere.
enum Format {

    static let currency: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale.current
        f.maximumFractionDigits = 0
        f.minimumFractionDigits = 0
        return f
    }()

    static let currencyCents: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale.current
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 2
        return f
    }()

    static let percent: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 1
        f.minimumFractionDigits = 0
        return f
    }()

    /// Money as whole dollars, e.g. "$12,480".
    static func money(_ value: Double) -> String {
        currency.string(from: NSNumber(value: value)) ?? "$0"
    }

    /// Money with cents, e.g. "$12,480.55".
    static func moneyCents(_ value: Double) -> String {
        currencyCents.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    /// Money from Decimal (engine output).
    static func money(_ value: Decimal) -> String {
        currency.string(from: NSDecimalNumber(decimal: value)) ?? "$0"
    }

    static func moneyCents(_ value: Decimal) -> String {
        currencyCents.string(from: NSDecimalNumber(decimal: value)) ?? "$0.00"
    }

    /// Percent string from a fraction (0.221 -> "22.1%").
    static func percentFromFraction(_ fraction: Double) -> String {
        let pct = fraction * 100
        let num = percent.string(from: NSNumber(value: pct)) ?? "0"
        return "\(num)%"
    }

    /// Percent string from a fraction expressed as Decimal.
    static func percentFromFraction(_ fraction: Decimal) -> String {
        percentFromFraction(NSDecimalNumber(decimal: fraction).doubleValue)
    }

    /// Percent from a whole-number rate (22.0 -> "22%").
    static func percentRate(_ rate: Double) -> String {
        let num = percent.string(from: NSNumber(value: rate)) ?? "0"
        return "\(num)%"
    }

    static let mediumDate: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    static let shortDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    static let monthYear: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    static func date(_ date: Date) -> String { mediumDate.string(from: date) }
    static func shortDate(_ date: Date) -> String { shortDate.string(from: date) }
    static func monthYear(_ date: Date) -> String { monthYear.string(from: date) }
}

extension Decimal {
    /// Safe rounding to a given scale (banker's-free, plain).
    func rounded(_ scale: Int, _ mode: NSDecimalNumber.RoundingMode = .plain) -> Decimal {
        var result = Decimal()
        var copy = self
        NSDecimalRound(&result, &copy, scale, mode)
        return result
    }

    var doubleValue: Double { NSDecimalNumber(decimal: self).doubleValue }
}
