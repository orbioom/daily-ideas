import Foundation

/// Result of a per-year deduction computation. All money values are `Decimal`.
struct DeductionResult: Equatable {
    var year: Int

    // Mileage method
    var milesByPurpose: [TripPurpose: Double]      // canonical miles, effective
    var mileageDeductionByPurpose: [TripPurpose: Decimal]
    var totalMileageDeduction: Decimal

    // Expenses
    var deductibleExpensesByCategory: [ExpenseCategory: Decimal]
    var totalDeductibleExpenses: Decimal

    // Grand total (standard mileage method + non-vehicle deductible expenses)
    var totalDeduction: Decimal

    // Usage
    var businessMiles: Double
    var totalMiles: Double
    var businessUsePercent: Double                 // 0...1, guarded
    var tripCount: Int
    var expenseCount: Int

    static let empty = DeductionResult(
        year: 0,
        milesByPurpose: [:],
        mileageDeductionByPurpose: [:],
        totalMileageDeduction: 0,
        deductibleExpensesByCategory: [:],
        totalDeductibleExpenses: 0,
        totalDeduction: 0,
        businessMiles: 0,
        totalMiles: 0,
        businessUsePercent: 0,
        tripCount: 0,
        expenseCount: 0)
}

/// Standard-mileage vs. actual-expense comparison for the business portion.
struct MethodComparison: Equatable {
    var standardMileageAmount: Decimal       // business miles × business rate
    var actualExpenseAmount: Decimal         // operating costs × business-use %
    var businessUsePercent: Double

    var recommended: String {
        standardMileageAmount >= actualExpenseAmount ? "Standard mileage" : "Actual expense"
    }
}

/// A single month bucket for charts.
struct MonthlyMiles: Identifiable, Equatable {
    var id: Int { monthIndex }            // 1...12
    var monthIndex: Int
    var label: String
    var businessMiles: Double
    var otherMiles: Double
    var total: Double { businessMiles + otherMiles }
}

/// Pure, deterministic deduction engine. No SwiftData, no UI — fully testable.
enum DeductionEngine {

    /// Round a Decimal to cents (banker-safe) for stable money display.
    static func cents(_ value: Decimal) -> Decimal {
        var v = value
        var result = Decimal()
        NSDecimalRound(&result, &v, 2, .plain)
        return result
    }

    /// Compute the full per-year deduction breakdown.
    /// - Parameters:
    ///   - trips: trips already filtered to `year`.
    ///   - expenses: expenses already filtered to `year`.
    ///   - rate: the MileageRate for `year` (nil → mileage deduction is 0).
    static func compute(year: Int,
                        trips: [Trip],
                        expenses: [Expense],
                        rate: MileageRate?) -> DeductionResult {
        var milesByPurpose: [TripPurpose: Double] = [:]
        for trip in trips {
            milesByPurpose[trip.purpose, default: 0] += trip.effectiveMiles
        }

        var mileageByPurpose: [TripPurpose: Decimal] = [:]
        var totalMileage: Decimal = 0
        for purpose in TripPurpose.allCases where purpose.isDeductible {
            let miles = milesByPurpose[purpose] ?? 0
            let perMile = rate?.rate(for: purpose) ?? 0
            let amount = cents(Decimal(miles) * perMile)
            mileageByPurpose[purpose] = amount
            totalMileage += amount
        }

        var expensesByCategory: [ExpenseCategory: Decimal] = [:]
        var totalDeductibleExpenses: Decimal = 0
        for expense in expenses where expense.deductible {
            expensesByCategory[expense.category, default: 0] += expense.amount
            totalDeductibleExpenses += expense.amount
        }
        totalDeductibleExpenses = cents(totalDeductibleExpenses)

        let businessMiles = milesByPurpose[.business] ?? 0
        let totalMiles = milesByPurpose.values.reduce(0, +)
        let businessUse = totalMiles > 0 ? min(1.0, max(0.0, businessMiles / totalMiles)) : 0

        return DeductionResult(
            year: year,
            milesByPurpose: milesByPurpose,
            mileageDeductionByPurpose: mileageByPurpose,
            totalMileageDeduction: cents(totalMileage),
            deductibleExpensesByCategory: expensesByCategory,
            totalDeductibleExpenses: totalDeductibleExpenses,
            totalDeduction: cents(totalMileage + totalDeductibleExpenses),
            businessMiles: businessMiles,
            totalMiles: totalMiles,
            businessUsePercent: businessUse,
            tripCount: trips.count,
            expenseCount: expenses.count)
    }

    /// Standard-mileage vs. actual-expense comparison for business use.
    /// Actual method = (vehicle operating costs) × business-use %.
    static func compareMethods(year: Int,
                               trips: [Trip],
                               expenses: [Expense],
                               rate: MileageRate?) -> MethodComparison {
        var milesByPurpose: [TripPurpose: Double] = [:]
        for trip in trips {
            milesByPurpose[trip.purpose, default: 0] += trip.effectiveMiles
        }
        let businessMiles = milesByPurpose[.business] ?? 0
        let totalMiles = milesByPurpose.values.reduce(0, +)
        let businessUse = totalMiles > 0 ? min(1.0, max(0.0, businessMiles / totalMiles)) : 0

        let businessRate = rate?.businessRate ?? 0
        let standard = cents(Decimal(businessMiles) * businessRate)

        var operating: Decimal = 0
        for expense in expenses where expense.category.isVehicleOperating {
            operating += expense.amount
        }
        let actual = cents(operating * Decimal(businessUse))

        return MethodComparison(standardMileageAmount: standard,
                                actualExpenseAmount: actual,
                                businessUsePercent: businessUse)
    }

    /// Per-month miles, split business vs. everything else, for a given year.
    static func monthlyMiles(year: Int,
                             trips: [Trip],
                             calendar: Calendar = .current) -> [MonthlyMiles] {
        var business = [Double](repeating: 0, count: 12)
        var other = [Double](repeating: 0, count: 12)
        for trip in trips {
            let m = calendar.component(.month, from: trip.date)
            guard (1...12).contains(m) else { continue }
            if trip.purpose == .business {
                business[m - 1] += trip.effectiveMiles
            } else {
                other[m - 1] += trip.effectiveMiles
            }
        }
        let symbols = calendar.shortMonthSymbols
        return (1...12).map { month in
            let label = (month - 1) < symbols.count ? symbols[month - 1] : "\(month)"
            return MonthlyMiles(monthIndex: month,
                                label: label,
                                businessMiles: business[month - 1],
                                otherMiles: other[month - 1])
        }
    }
}
