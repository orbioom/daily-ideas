import Foundation

/// The substantive core of Yield: derives projected income, yields, the 12-month payout
/// calendar, sector/concentration analytics, and a DRIP compounding projection — all from
/// user-entered shares + dividend-per-share. No live data. All money math uses `Decimal`
/// and every division is guarded against divide-by-zero.
enum IncomeEngine {

    // MARK: Per-holding primitives

    /// Projected annual income for one holding = shares × annual dividend-per-share.
    static func annualIncome(for h: Holding) -> Decimal {
        max(h.shares, 0) * max(h.annualDividendPerShare, 0)
    }

    /// Yield-on-cost = annual DPS / average cost per share. Guarded; nil if cost ≤ 0.
    static func yieldOnCost(for h: Holding) -> Double? {
        let cost = h.avgCostPerShare
        guard cost > 0 else { return nil }
        return ratio(h.annualDividendPerShare, cost)
    }

    /// Current yield = annual DPS / current price. nil if price missing or ≤ 0.
    static func currentYield(for h: Holding) -> Double? {
        guard let price = h.currentPrice, price > 0 else { return nil }
        return ratio(h.annualDividendPerShare, price)
    }

    /// Total cost basis for one holding (shares × avg cost).
    static func costBasis(for h: Holding) -> Decimal {
        max(h.shares, 0) * max(h.avgCostPerShare, 0)
    }

    /// Market value (shares × current price) if a price is set, else nil.
    static func marketValue(for h: Holding) -> Decimal? {
        guard let price = h.currentPrice, price > 0 else { return nil }
        return max(h.shares, 0) * price
    }

    /// Income contribution per single payment (annual income / payments per year).
    static func perPaymentIncome(for h: Holding) -> Decimal {
        let n = h.frequency.paymentsPerYear
        guard n > 0 else { return 0 }
        return annualIncome(for: h) / Decimal(n)
    }

    // MARK: Portfolio aggregates

    /// Σ projected annual income across holdings.
    static func totalAnnualIncome(_ holdings: [Holding]) -> Decimal {
        holdings.reduce(Decimal(0)) { $0 + annualIncome(for: $1) }
    }

    /// Average monthly income = annual / 12.
    static func averageMonthlyIncome(_ holdings: [Holding]) -> Decimal {
        totalAnnualIncome(holdings) / 12
    }

    /// Σ cost basis across holdings.
    static func totalCostBasis(_ holdings: [Holding]) -> Decimal {
        holdings.reduce(Decimal(0)) { $0 + costBasis(for: $1) }
    }

    /// Portfolio yield-on-cost = total annual income / total cost basis. nil if cost ≤ 0.
    static func portfolioYieldOnCost(_ holdings: [Holding]) -> Double? {
        let basis = totalCostBasis(holdings)
        guard basis > 0 else { return nil }
        return ratio(totalAnnualIncome(holdings), basis)
    }

    /// Portfolio current yield using only holdings that have a current price set.
    static func portfolioCurrentYield(_ holdings: [Holding]) -> Double? {
        var income = Decimal(0)
        var value = Decimal(0)
        for h in holdings {
            if let mv = marketValue(for: h) {
                value += mv
                income += annualIncome(for: h)
            }
        }
        guard value > 0 else { return nil }
        return ratio(income, value)
    }

    // MARK: 12-month forward income calendar

    /// A forward 12-month projected-income array, starting at the given anchor month.
    /// Each holding distributes its annual income across the months it pays in, derived
    /// from frequency + pay cycle. `startMonth`/`startYear` define index 0.
    static func forwardMonthlyIncome(_ holdings: [Holding],
                                     startMonth: Int,
                                     startYear: Int) -> [MonthIncome] {
        var totals = [Decimal](repeating: 0, count: 12)
        for h in holdings {
            let per = perPaymentIncome(for: h)
            guard per > 0 else { continue }
            for month in payMonths(for: h) {
                // Find the offset (0..<12) from start month to this 1-based calendar month.
                let offset = ((month - startMonth) % 12 + 12) % 12
                totals[offset] += per
            }
        }
        return (0..<12).map { i in
            let (m, y) = advance(month: startMonth, year: startYear, by: i)
            return MonthIncome(monthIndex: i, calendarMonth: m, year: y, amount: totals[i])
        }
    }

    /// The set of 1-based calendar months a holding pays in, for one year.
    static func payMonths(for h: Holding) -> [Int] {
        let anchor = h.payCycle.anchorMonth
        let step = h.frequency.monthStep
        guard step > 0 else { return [anchor] }
        var months: [Int] = []
        var m = anchor
        let count = h.frequency.paymentsPerYear
        for _ in 0..<count {
            months.append(((m - 1) % 12) + 1)
            m += step
        }
        return months
    }

    /// The next pay date (≥ reference) for a holding, from its pay months + pay day.
    static func nextPayDate(for h: Holding, after reference: Date = Date(),
                            calendar: Calendar = .current) -> Date? {
        let day = min(max(h.payDayOfMonth, 1), 28)
        var candidates: [Date] = []
        for monthOffset in 0...12 {
            guard let monthDate = calendar.date(byAdding: .month, value: monthOffset, to: reference) else { continue }
            let comps = calendar.dateComponents([.year, .month], from: monthDate)
            guard let year = comps.year, let month = comps.month else { continue }
            guard payMonths(for: h).contains(month) else { continue }
            var dc = DateComponents()
            dc.year = year; dc.month = month; dc.day = day
            if let d = calendar.date(from: dc), d >= calendar.startOfDay(for: reference) {
                candidates.append(d)
            }
        }
        return candidates.sorted().first
    }

    // MARK: Sector & concentration analytics (of INCOME, not value)

    /// Income grouped by sector, sorted descending by amount. Skips zero-income sectors.
    static func incomeBySector(_ holdings: [Holding]) -> [SectorIncome] {
        var map: [Sector: Decimal] = [:]
        for h in holdings {
            let inc = annualIncome(for: h)
            guard inc > 0 else { continue }
            map[h.sector, default: 0] += inc
        }
        let total = map.values.reduce(Decimal(0), +)
        return map.map { sector, amount in
            SectorIncome(sector: sector, amount: amount, fraction: ratio(amount, total) ?? 0)
        }
        .sorted { $0.amount > $1.amount }
    }

    /// Top payers by annual income (descending). Limited to `limit`.
    static func topPayers(_ holdings: [Holding], limit: Int = 5) -> [PayerIncome] {
        let total = totalAnnualIncome(holdings)
        return holdings
            .map { PayerIncome(id: $0.id, ticker: $0.ticker, name: $0.name,
                               amount: annualIncome(for: $0),
                               fraction: ratio(annualIncome(for: $0), total) ?? 0) }
            .filter { $0.amount > 0 }
            .sorted { $0.amount > $1.amount }
            .prefix(limit)
            .map { $0 }
    }

    /// Concentration = share of total income from the single largest payer (0...1).
    static func topPayerConcentration(_ holdings: [Holding]) -> Double {
        topPayers(holdings, limit: 1).first?.fraction ?? 0
    }

    // MARK: DRIP compounding projection

    /// Compound forward `years` of dividend income. Each year:
    ///   • dividends are reinvested at the portfolio yield (income buys more income), and
    ///   • dividend-per-share grows at `growthRate` (e.g. 0.06 = 6%/yr).
    /// `baseYield` is the portfolio yield used for reinvestment (guarded ≥ 0).
    /// Returns a yearly series including year 0 (today).
    static func dripProjection(startingAnnualIncome income: Decimal,
                               portfolioYield baseYield: Double,
                               annualGrowthRate growthRate: Double,
                               years: Int) -> [DripYear] {
        let clampedYears = max(0, min(years, 60))
        let y = max(baseYield, 0)
        let g = max(growthRate, -0.99)
        var series: [DripYear] = []
        var current = max(income, 0)
        series.append(DripYear(year: 0, annualIncome: current))
        guard clampedYears > 0 else { return series }

        // Reinvestment multiplier: each year income grows by (1 + yield) from reinvested
        // dividends buying more shares, AND by (1 + growth) from rising DPS.
        let reinvest = Decimal(1 + y)
        let grow = Decimal(1 + g)
        for year in 1...clampedYears {
            current = current * reinvest * grow
            series.append(DripYear(year: year, annualIncome: current))
        }
        return series
    }

    // MARK: Helpers

    /// Guarded Decimal division → Double ratio. nil when denominator ≤ 0 or non-finite.
    static func ratio(_ numerator: Decimal, _ denominator: Decimal) -> Double? {
        guard denominator > 0 else { return nil }
        let r = (numerator / denominator).doubleValue
        return r.isFinite ? r : nil
    }

    /// Advance a 1-based (month, year) by `n` months.
    static func advance(month: Int, year: Int, by n: Int) -> (Int, Int) {
        let zeroBased = (month - 1) + n
        let newMonth = ((zeroBased % 12) + 12) % 12
        let yearDelta = Int(floor(Double((month - 1) + n) / 12.0))
        return (newMonth + 1, year + yearDelta)
    }
}

// MARK: - Value types (plain, Sendable-friendly snapshots for views & charts)

struct MonthIncome: Identifiable, Hashable {
    var id: Int { monthIndex }
    let monthIndex: Int      // 0..<12 forward position
    let calendarMonth: Int   // 1-based calendar month
    let year: Int
    let amount: Decimal

    /// Short month label, e.g. "Jul".
    var shortLabel: String {
        let symbols = Calendar.current.shortMonthSymbols
        let idx = calendarMonth - 1
        guard symbols.indices.contains(idx) else { return "—" }
        return symbols[idx]
    }
}

struct SectorIncome: Identifiable, Hashable {
    var id: String { sector.rawValue }
    let sector: Sector
    let amount: Decimal
    let fraction: Double
}

struct PayerIncome: Identifiable, Hashable {
    let id: UUID
    let ticker: String
    let name: String
    let amount: Decimal
    let fraction: Double
}

struct DripYear: Identifiable, Hashable {
    var id: Int { year }
    let year: Int
    let annualIncome: Decimal
}

/// An upcoming payment row for the calendar feed.
struct UpcomingPayment: Identifiable, Hashable {
    let id: UUID
    let ticker: String
    let name: String
    let date: Date
    let amount: Decimal
}
