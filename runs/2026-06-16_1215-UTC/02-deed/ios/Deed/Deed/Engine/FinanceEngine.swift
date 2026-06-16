import Foundation

/// Per-property financial metrics. All money math uses `Decimal`.
struct PropertyMetrics {
    let monthlyRentalIncome: Decimal
    let monthlyOperatingExpenses: Decimal
    let monthlyMortgage: Decimal
    let monthlyCashFlow: Decimal

    let annualIncome: Decimal
    let annualOperatingExpenses: Decimal
    let noi: Decimal
    let annualCashFlow: Decimal

    let capRate: Decimal?
    let cashOnCash: Decimal?
    let equity: Decimal
    let grossRentMultiplier: Decimal?
    let expenseRatio: Decimal?
    let occupancy: Decimal
    let occupiedUnits: Int
    let totalUnits: Int
}

/// Portfolio-wide rollups.
struct PortfolioMetrics {
    let totalValue: Decimal
    let totalEquity: Decimal
    let totalMonthlyCashFlow: Decimal
    let totalMonthlyRentRoll: Decimal
    let portfolioCapRate: Decimal?
    let overallOccupancy: Decimal
    let occupiedUnits: Int
    let totalUnits: Int
    let collectedThisMonth: Decimal
    let dueThisMonth: Decimal
    let propertyCount: Int
}

/// Pure finance computations. No persistence, no UI. Guarded against zero divisors.
enum FinanceEngine {

    // MARK: - Safe division

    /// Returns nil when the divisor is zero (no unguarded division anywhere).
    static func ratio(_ numerator: Decimal, _ denominator: Decimal) -> Decimal? {
        guard denominator != 0 else { return nil }
        return numerator / denominator
    }

    // MARK: - Property-level

    /// Estimated *monthly* operating expenses derived from the trailing 12 months of
    /// operating transactions (excludes mortgage interest, capex, deposits).
    static func monthlyOperatingExpenses(for property: Property, asOf today: Date = Date()) -> Decimal {
        let annual = annualOperatingExpenses(for: property, asOf: today)
        return ratio(annual, 12) ?? 0
    }

    static func annualOperatingExpenses(for property: Property, asOf today: Date = Date()) -> Decimal {
        let cutoff = Calendar.deed.date(byAdding: .month, value: -12, to: today) ?? today
        return property.transactions
            .filter { $0.kind == .expense && $0.category.isOperatingExpense && $0.date >= cutoff && $0.date <= today }
            .reduce(Decimal(0)) { $0 + $1.amount }
    }

    /// Monthly rental income = sum of active-lease rents (contracted recurring income).
    static func monthlyRentalIncome(for property: Property) -> Decimal {
        property.units
            .compactMap { $0.activeLease?.monthlyRent }
            .reduce(Decimal(0), +)
    }

    static func equity(for property: Property) -> Decimal {
        property.currentValue - property.mortgageBalance
    }

    static func metrics(for property: Property, settings closingCostPct: Double, asOf today: Date = Date()) -> PropertyMetrics {
        let monthlyIncome = monthlyRentalIncome(for: property)
        let monthlyOpEx = monthlyOperatingExpenses(for: property, asOf: today)
        let mortgage = property.mortgagePayment
        let monthlyCashFlow = monthlyIncome - monthlyOpEx - mortgage

        let annualIncome = monthlyIncome * 12
        let annualOpEx = annualOperatingExpenses(for: property, asOf: today)
        let noi = annualIncome - annualOpEx
        let annualCashFlow = monthlyCashFlow * 12

        let capRate = ratio(noi, property.currentValue)

        // Cash invested = down payment + explicit closing costs, with a % fallback.
        let assumedClosing = property.closingCosts > 0
            ? property.closingCosts
            : property.purchasePrice * Decimal(closingCostPct / 100.0)
        let cashInvested = property.downPayment + assumedClosing
        let cashOnCash = ratio(annualCashFlow, cashInvested)

        let equityValue = equity(for: property)
        let grm = ratio(property.purchasePrice, annualIncome)
        let expenseRatio = ratio(annualOpEx, annualIncome)

        let total = property.units.count
        let occupied = property.units.filter { $0.status == .occupied }.count
        let occupancy = ratio(Decimal(occupied), Decimal(total)) ?? 0

        return PropertyMetrics(
            monthlyRentalIncome: monthlyIncome,
            monthlyOperatingExpenses: monthlyOpEx,
            monthlyMortgage: mortgage,
            monthlyCashFlow: monthlyCashFlow,
            annualIncome: annualIncome,
            annualOperatingExpenses: annualOpEx,
            noi: noi,
            annualCashFlow: annualCashFlow,
            capRate: capRate,
            cashOnCash: cashOnCash,
            equity: equityValue,
            grossRentMultiplier: grm,
            expenseRatio: expenseRatio,
            occupancy: occupancy,
            occupiedUnits: occupied,
            totalUnits: total
        )
    }

    // MARK: - Portfolio-level

    static func portfolioMetrics(for properties: [Property], settings closingCostPct: Double, asOf today: Date = Date()) -> PortfolioMetrics {
        var totalValue: Decimal = 0
        var totalEquity: Decimal = 0
        var totalCashFlow: Decimal = 0
        var totalRentRoll: Decimal = 0
        var totalNOI: Decimal = 0
        var occupied = 0
        var totalUnits = 0

        for property in properties {
            let m = metrics(for: property, settings: closingCostPct, asOf: today)
            totalValue += property.currentValue
            totalEquity += m.equity
            totalCashFlow += m.monthlyCashFlow
            totalRentRoll += m.monthlyRentalIncome
            totalNOI += m.noi
            occupied += m.occupiedUnits
            totalUnits += m.totalUnits
        }

        let portfolioCapRate = ratio(totalNOI, totalValue)
        let occupancy = ratio(Decimal(occupied), Decimal(totalUnits)) ?? 0

        let (collected, due) = RentLedger.collectionThisMonth(for: properties, asOf: today)

        return PortfolioMetrics(
            totalValue: totalValue,
            totalEquity: totalEquity,
            totalMonthlyCashFlow: totalCashFlow,
            totalMonthlyRentRoll: totalRentRoll,
            portfolioCapRate: portfolioCapRate,
            overallOccupancy: occupancy,
            occupiedUnits: occupied,
            totalUnits: totalUnits,
            collectedThisMonth: collected,
            dueThisMonth: due,
            propertyCount: properties.count
        )
    }
}

extension Calendar {
    /// Shared calendar pinned to the current locale's settings for deterministic month math.
    static let deed: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone.current
        return cal
    }()
}
