import Foundation

/// Month-by-month debt payoff simulation. Pure value types, no SwiftData
/// dependency, so it is fully testable and never blocks the main thread.
enum PayoffEngine {

    /// A single debt as a plain value for simulation.
    struct DebtInput: Identifiable {
        let id: UUID
        let name: String
        var balance: Double
        let apr: Double
        let minPayment: Double
    }

    /// One month of the plan.
    struct MonthRow: Identifiable {
        let id = UUID()
        let index: Int          // 1-based month number
        let date: Date
        let startingBalance: Double
        let interest: Double
        let payment: Double
        let endingBalance: Double
    }

    struct Result {
        var months: [MonthRow] = []
        var totalInterest: Double = 0
        var totalPaid: Double = 0
        var monthsToPayoff: Int = 0
        var payoffDate: Date?
        var perDebtPayoffMonth: [UUID: Int] = [:]
        /// True when minimum payments can't keep up with interest (never pays off).
        var stuck = false
    }

    private static let maxMonths = 600   // 50-year safety cap

    /// Simulate paying off `debts`.
    /// - rollover: when true, freed-up minimums and `extra` are funnelled to the
    ///   next target debt (snowball/avalanche). When false, each debt only ever
    ///   receives its own minimum (the "minimum payments only" baseline).
    static func simulate(debts: [DebtInput], extra: Double, strategy: Strategy,
                         rollover: Bool, startDate: Date = Date()) -> Result {
        var result = Result()
        var working = debts.filter { $0.balance > 0 }
        guard !working.isEmpty else { return result }

        let baselineBudget = working.reduce(0) { $0 + $1.minPayment }
        let cal = Calendar.current
        var month = 0

        while working.contains(where: { $0.balance > 0.005 }) {
            month += 1
            if month > maxMonths { result.stuck = true; break }

            let startTotal = working.reduce(0) { $0 + $1.balance }

            // 1) accrue interest
            var interestThisMonth = 0.0
            for i in working.indices {
                let interest = working[i].balance * working[i].apr / 100.0 / 12.0
                working[i].balance += interest
                interestThisMonth += interest
            }

            // 2) determine available budget
            var available = rollover ? (baselineBudget + max(0, extra)) : baselineBudget
            var paidThisMonth = 0.0

            // 3) pay minimums first (capped at balance)
            for i in working.indices where working[i].balance > 0 {
                let pay = min(working[i].minPayment, working[i].balance)
                let capped = min(pay, available)
                working[i].balance -= capped
                available -= capped
                paidThisMonth += capped
            }

            // 4) funnel remaining budget to the strategy target(s)
            if rollover && available > 0.005 {
                for idx in targetOrder(working, strategy: strategy) {
                    guard available > 0.005 else { break }
                    guard working[idx].balance > 0.005 else { continue }
                    let pay = min(available, working[idx].balance)
                    working[idx].balance -= pay
                    available -= pay
                    paidThisMonth += pay
                }
            }

            let endTotal = working.reduce(0) { $0 + max(0, $1.balance) }

            // record payoff months
            for d in working where d.balance <= 0.005 && result.perDebtPayoffMonth[d.id] == nil {
                result.perDebtPayoffMonth[d.id] = month
            }

            result.months.append(MonthRow(
                index: month,
                date: cal.date(byAdding: .month, value: month, to: startDate) ?? startDate,
                startingBalance: startTotal,
                interest: interestThisMonth,
                payment: paidThisMonth,
                endingBalance: endTotal))
            result.totalInterest += interestThisMonth
            result.totalPaid += paidThisMonth

            // stuck detection: balance not falling and budget fully spent
            if endTotal >= startTotal - 0.005 {
                result.stuck = true
                break
            }
        }

        result.monthsToPayoff = result.stuck ? 0 : month
        if !result.stuck {
            result.payoffDate = cal.date(byAdding: .month, value: month, to: startDate)
        }
        return result
    }

    /// Indices of `debts` in the order the strategy targets them.
    private static func targetOrder(_ debts: [DebtInput], strategy: Strategy) -> [Int] {
        let indices = Array(debts.indices).filter { debts[$0].balance > 0.005 }
        switch strategy {
        case .avalanche:
            return indices.sorted { debts[$0].apr > debts[$1].apr }
        case .snowball:
            return indices.sorted { debts[$0].balance < debts[$1].balance }
        }
    }
}
