import Foundation

/// Pure financial-independence math. Compound growth, Coast FI, projections.
/// No UI, no I/O. All returns are real (inflation-adjusted) by convention.
enum FIEngine {

    // MARK: Core numbers

    /// Years until the portfolio (with contributions) reaches the FI number.
    /// Uses annual compounding with end-of-year contributions. Nil if unreachable
    /// within 100 years.
    static func yearsToFI(profile: Profile) -> Double? {
        yearsToReach(target: profile.fiNumber,
                     current: profile.currentInvested,
                     contribution: profile.annualContribution,
                     rate: profile.realReturn)
    }

    /// Generic: years for `current` growing at `rate` + annual `contribution` to hit `target`.
    static func yearsToReach(target: Double, current: Double,
                             contribution: Double, rate: Double) -> Double? {
        if current >= target { return 0 }
        var balance = current
        var years = 0.0
        while years < 100 {
            balance = balance * (1 + rate) + contribution
            years += 1
            if balance >= target {
                // Linear-interpolate within the final year for a smoother number.
                let prev = (balance - contribution) / (1 + rate)
                let gained = balance - prev
                if gained > 0 {
                    let fraction = (target - prev) / gained
                    return years - 1 + min(max(fraction, 0), 1)
                }
                return years
            }
        }
        return nil
    }

    /// "Coast FI" amount at the current age: the portfolio that, with NO further
    /// contributions, grows to the FI number by `traditionalRetirementAge`.
    /// If you have this much, you can stop investing and still retire on time.
    static func coastFINumber(profile: Profile, retirementAge: Double = 65) -> Double {
        let yearsToRetirement = max(retirementAge - profile.currentAge, 0)
        guard yearsToRetirement > 0 else { return profile.fiNumber }
        let growth = pow(1 + profile.realReturn, yearsToRetirement)
        guard growth > 0 else { return profile.fiNumber }
        return profile.fiNumber / growth
    }

    /// Progress (0...1) toward full FI.
    static func progress(profile: Profile) -> Double {
        guard profile.fiNumber > 0 else { return 0 }
        return min(profile.currentInvested / profile.fiNumber, 1)
    }

    /// Have you hit Coast FI already?
    static func hasReachedCoastFI(profile: Profile, retirementAge: Double = 65) -> Bool {
        profile.currentInvested >= coastFINumber(profile: profile, retirementAge: retirementAge)
    }

    /// Savings rate: contribution ÷ (contribution + expenses). The single biggest
    /// lever in FI math.
    static func savingsRate(profile: Profile) -> Double {
        let gross = profile.annualContribution + profile.annualExpenses
        guard gross > 0 else { return 0 }
        return profile.annualContribution / gross
    }

    /// Monthly income the portfolio could throw off today at the withdrawal rate.
    static func currentPassiveMonthly(profile: Profile) -> Double {
        profile.currentInvested * profile.withdrawalRate / 12
    }

    // MARK: Projection series

    struct ProjectionPoint: Identifiable {
        let id: Int
        let age: Double
        let withContributions: Double
        let coastOnly: Double
    }

    /// Year-by-year portfolio projection from now to FI (or 40 years), showing
    /// both "keep contributing" and "coast (stop contributing now)" paths.
    static func projection(profile: Profile, maxYears: Int = 45) -> [ProjectionPoint] {
        let fiYears = yearsToFI(profile: profile)
        let horizon = min(maxYears, Int((fiYears ?? Double(maxYears)).rounded(.up)) + 3)
        var points: [ProjectionPoint] = []
        var contrib = profile.currentInvested
        var coast = profile.currentInvested
        points.append(ProjectionPoint(id: 0, age: profile.currentAge,
                                      withContributions: contrib, coastOnly: coast))
        for year in 1...max(horizon, 1) {
            contrib = contrib * (1 + profile.realReturn) + profile.annualContribution
            coast = coast * (1 + profile.realReturn)
            points.append(ProjectionPoint(id: year, age: profile.currentAge + Double(year),
                                          withContributions: contrib, coastOnly: coast))
        }
        return points
    }

    // MARK: Net-worth history analysis

    /// Average monthly change across logged entries (least-squares slope on
    /// fractional months), or nil with fewer than 2 entries.
    static func monthlyGrowthRate(entries: [NetWorthEntry]) -> Double? {
        let sorted = entries.sorted { $0.date < $1.date }
        guard sorted.count >= 2, let first = sorted.first else { return nil }
        let xs = sorted.map { $0.date.timeIntervalSince(first.date) / (86_400 * 30.44) }
        let ys = sorted.map(\.amount)
        let n = Double(xs.count)
        let sumX = xs.reduce(0, +), sumY = ys.reduce(0, +)
        let sumXY = zip(xs, ys).reduce(0) { $0 + $1.0 * $1.1 }
        let sumXX = xs.reduce(0) { $0 + $1 * $1 }
        let denom = n * sumXX - sumX * sumX
        guard abs(denom) > 0.0001 else { return nil }
        return (n * sumXY - sumX * sumY) / denom
    }

    /// Projected FI date using the REAL logged pace instead of assumptions.
    static func fiDateFromHistory(entries: [NetWorthEntry], fiNumber: Double,
                                  now: Date = Date()) -> Date? {
        guard let rate = monthlyGrowthRate(entries: entries), rate > 0,
              let latest = entries.max(by: { $0.date < $1.date }) else { return nil }
        if latest.amount >= fiNumber { return now }
        let monthsNeeded = (fiNumber - latest.amount) / rate
        guard monthsNeeded.isFinite, monthsNeeded < 1200 else { return nil }
        return Calendar.current.date(byAdding: .day,
                                     value: Int(monthsNeeded * 30.44), to: now)
    }

    // MARK: Milestones

    /// The standard auto milestones for a given FI number.
    static func autoMilestones(fiNumber: Double, coastNumber: Double) -> [(title: String, amount: Double, emoji: String)] {
        [
            ("First $10k invested", 10_000, "🌱"),
            ("Coast FI", coastNumber, "⛵️"),
            ("Quarter to FI", fiNumber * 0.25, "🌗"),
            ("Halfway to FI", fiNumber * 0.5, "🌓"),
            ("Lean FI (¾)", fiNumber * 0.75, "🌖"),
            ("Financial Independence", fiNumber, "🏝️"),
        ]
        .filter { $0.amount > 0 }
        .sorted { $0.amount < $1.amount }
    }

    // MARK: Formatting

    static func money(_ value: Double, code: String = "USD", compact: Bool = false) -> String {
        if compact {
            let abs = Swift.abs(value)
            let sign = value < 0 ? "-" : ""
            let symbol = currencySymbol(code)
            if abs >= 1_000_000 { return "\(sign)\(symbol)\(trim(abs / 1_000_000))M" }
            if abs >= 1_000 { return "\(sign)\(symbol)\(trim(abs / 1_000))k" }
            return "\(sign)\(symbol)\(Int(abs))"
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }

    private static func trim(_ value: Double) -> String {
        value >= 10 ? String(Int(value.rounded())) : String(format: "%.1f", value)
    }

    static func currencySymbol(_ code: String) -> String {
        switch code {
        case "EUR": return "€"
        case "GBP": return "£"
        case "CAD", "AUD", "USD": return "$"
        default: return "$"
        }
    }

    /// "8 years, 4 months" style.
    static func yearsLabel(_ years: Double) -> String {
        guard years.isFinite else { return "Not reachable" }
        if years <= 0 { return "Reached!" }
        let whole = Int(years)
        let months = Int((years - Double(whole)) * 12)
        if whole == 0 { return "\(months) month\(months == 1 ? "" : "s")" }
        if months == 0 { return "\(whole) year\(whole == 1 ? "" : "s")" }
        return "\(whole) yr \(months) mo"
    }
}
