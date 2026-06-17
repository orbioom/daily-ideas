import Foundation

/// Normalizes any billing cycle's cost to monthly and annual equivalents.
/// All arithmetic is done in `Decimal` for currency precision; division is guarded.
enum CostEngine {

    /// Average days in a month / year used to normalize day-based cycles.
    /// 365.2425 / 12 keeps weekly and custom-day math stable across leap years.
    static let daysPerYear = Decimal(string: "365.2425") ?? Decimal(365)
    static let monthsPerYear = Decimal(12)
    static var daysPerMonth: Decimal { divide(daysPerYear, by: monthsPerYear) ?? Decimal(30) }

    /// Safe Decimal division — returns nil on a zero divisor.
    static func divide(_ a: Decimal, by b: Decimal) -> Decimal? {
        guard b != 0 else { return nil }
        return a / b
    }

    /// Number of times the given cycle bills per year (as a Decimal).
    static func occurrencesPerYear(_ cycle: BillingCycle) -> Decimal {
        switch cycle {
        case .weekly:               return Decimal(52)
        case .biweekly:             return Decimal(26)
        case .monthly:              return Decimal(12)
        case .quarterly:            return Decimal(4)
        case .semiannual:           return Decimal(2)
        case .annual:               return Decimal(1)
        case .customDays(let d):
            let days = Decimal(max(1, d))
            return divide(daysPerYear, by: days) ?? Decimal(1)
        }
    }

    /// The monthly-equivalent cost of one charge of `amount` on `cycle`.
    static func monthlyEquivalent(amount: Decimal, cycle: BillingCycle) -> Decimal {
        let perYear = occurrencesPerYear(cycle)
        let annual = amount * perYear
        return divide(annual, by: monthsPerYear) ?? annual
    }

    /// The annual-equivalent cost of one charge of `amount` on `cycle`.
    static func annualEquivalent(amount: Decimal, cycle: BillingCycle) -> Decimal {
        amount * occurrencesPerYear(cycle)
    }

    /// Rounds a Decimal to 2 fractional digits (banker-safe for display).
    static func rounded2(_ value: Decimal) -> Decimal {
        var input = value
        var result = Decimal()
        NSDecimalRound(&result, &input, 2, .plain)
        return result
    }
}
