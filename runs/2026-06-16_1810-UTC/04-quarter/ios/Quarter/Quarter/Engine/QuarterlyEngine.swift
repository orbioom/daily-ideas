import Foundation

/// A computed quarterly estimated-payment period (before being persisted).
struct QuarterlyPeriod: Identifiable {
    let id = UUID()
    let quarter: Int
    let dueDate: Date
    let onOrAround: Bool        // true when the statutory date fell on a weekend
    let amountDue: Decimal
    let label: String
}

/// Produces the four estimated-payment periods and safe-harbor guidance.
enum QuarterlyEngine {

    /// Standard federal estimated-payment due dates for a tax year:
    /// Apr 15, Jun 15, Sep 15 of the year, and Jan 15 of the next year.
    /// Rolls forward over weekends (simple Sat→Mon, Sun→Mon).
    static func dueDates(for year: Int) -> [(quarter: Int, date: Date, around: Bool)] {
        let raw: [(Int, DateComponents)] = [
            (1, DateComponents(year: year, month: 4, day: 15)),
            (2, DateComponents(year: year, month: 6, day: 15)),
            (3, DateComponents(year: year, month: 9, day: 15)),
            (4, DateComponents(year: year + 1, month: 1, day: 15))
        ]
        let cal = Calendar(identifier: .gregorian)
        return raw.map { quarter, comps in
            let base = cal.date(from: comps) ?? Date()
            let (rolled, didRoll) = rollForwardOverWeekend(base, calendar: cal)
            return (quarter, rolled, didRoll)
        }
    }

    private static func rollForwardOverWeekend(_ date: Date, calendar: Calendar) -> (Date, Bool) {
        var d = date
        var rolled = false
        var guardCount = 0
        while guardCount < 4 {
            let weekday = calendar.component(.weekday, from: d) // 1 = Sun, 7 = Sat
            if weekday == 1 {            // Sunday -> +1
                d = calendar.date(byAdding: .day, value: 1, to: d) ?? d
                rolled = true
            } else if weekday == 7 {     // Saturday -> +2
                d = calendar.date(byAdding: .day, value: 2, to: d) ?? d
                rolled = true
            } else {
                break
            }
            guardCount += 1
        }
        return (d, rolled)
    }

    /// Build the four periods for an estimate. Each quarter pays a quarter of the
    /// remaining liability after withholding (never negative).
    static func periods(year: Int, totalTax: Decimal, withholding: Decimal) -> [QuarterlyPeriod] {
        let remaining = max(0, totalTax - withholding)
        let perQuarter = remaining / 4   // 4 is a non-zero literal — safe
        return dueDates(for: year).map { quarter, date, around in
            QuarterlyPeriod(
                quarter: quarter,
                dueDate: date,
                onOrAround: around,
                amountDue: perQuarter,
                label: "Q\(quarter) \(year)"
            )
        }
    }

    /// Safe-harbor target: the LESSER of
    ///   - 90% of current-year tax, or
    ///   - 100% of prior-year tax (110% if prior-year AGI > 150,000).
    /// Returns nil when prior-year data isn't supplied (then 90% of current applies).
    static func safeHarborTarget(currentYearTax: Decimal,
                                 priorYearTax: Decimal?,
                                 priorYearAGI: Decimal?) -> Decimal {
        let ninetyCurrent = currentYearTax * 0.90
        guard let priorTax = priorYearTax else { return ninetyCurrent }
        let highIncome = (priorYearAGI ?? 0) > 150_000
        let priorMultiplier: Decimal = highIncome ? 1.10 : 1.00
        let priorTarget = priorTax * priorMultiplier
        return min(ninetyCurrent, priorTarget)
    }

    /// Days until the next upcoming due date (>= today). Returns the period and day count.
    static func nextDue(periods: [QuarterlyPeriod], from now: Date = .now) -> (period: QuarterlyPeriod, days: Int)? {
        let cal = Calendar(identifier: .gregorian)
        let today = cal.startOfDay(for: now)
        let upcoming = periods
            .filter { cal.startOfDay(for: $0.dueDate) >= today }
            .sorted { $0.dueDate < $1.dueDate }
        guard let next = upcoming.first else { return nil }
        let days = cal.dateComponents([.day], from: today, to: cal.startOfDay(for: next.dueDate)).day ?? 0
        return (next, max(0, days))
    }
}
