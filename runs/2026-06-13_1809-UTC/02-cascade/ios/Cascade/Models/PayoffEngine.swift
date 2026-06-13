import Foundation

enum PayoffStrategy: String, CaseIterable, Identifiable {
    case snowball, avalanche, custom
    var id: String { rawValue }
    var label: String {
        switch self {
        case .snowball: return "Snowball"
        case .avalanche: return "Avalanche"
        case .custom: return "Custom order"
        }
    }
    var blurb: String {
        switch self {
        case .snowball: return "Smallest balance first — fastest wins, best motivation."
        case .avalanche: return "Highest interest rate first — least interest paid."
        case .custom: return "Pay debts in the order you arrange them."
        }
    }
    var icon: String {
        switch self {
        case .snowball: return "snowflake"
        case .avalanche: return "mountain.2.fill"
        case .custom: return "slider.horizontal.3"
        }
    }
}

/// One debt's lightweight snapshot fed into the simulator.
struct DebtSnapshot: Identifiable {
    let id: UUID
    let name: String
    let balance: Double
    let apr: Double
    let minimum: Double
    let sortIndex: Int
}

/// A single month of the simulated payoff.
struct MonthPoint: Identifiable {
    let id = UUID()
    let monthIndex: Int          // 1-based months from now
    let date: Date
    let totalBalance: Double
    let interestThisMonth: Double
    let clearedDebtIDs: [UUID]
}

/// Per-debt result of a run.
struct DebtResult: Identifiable {
    let id: UUID
    let name: String
    let payoffMonth: Int?        // nil = not paid off within the horizon
    let interestPaid: Double
}

/// The full outcome of one simulation.
struct PayoffPlan {
    var months: [MonthPoint]
    var perDebt: [DebtResult]
    var totalInterest: Double
    var totalPaid: Double
    var payoffMonths: Int?       // nil = does not pay off within horizon
    var feasible: Bool           // budget covers all minimum payments
    var requiredMinimum: Double  // sum of minimum payments

    var payoffDate: Date? {
        guard let payoffMonths else { return nil }
        return Calendar.current.date(byAdding: .month, value: payoffMonths, to: Date())
    }
}

/// Pure debt-payoff simulator. Accrues monthly interest, pays every minimum,
/// then funnels the remaining budget to the focus debt in strategy order —
/// rolling freed minimums forward as debts clear (the "cascade").
enum PayoffEngine {
    private static let horizon = 600   // 50 years

    static func simulate(_ debts: [DebtSnapshot],
                         monthlyBudget: Double,
                         strategy: PayoffStrategy) -> PayoffPlan {
        let active0 = debts.filter { $0.balance > 0.005 }
        let requiredMin = active0.reduce(0) { $0 + $1.minimum }

        guard !active0.isEmpty else {
            return PayoffPlan(months: [], perDebt: [], totalInterest: 0, totalPaid: 0,
                              payoffMonths: 0, feasible: true, requiredMinimum: 0)
        }
        let feasible = monthlyBudget + 0.005 >= requiredMin

        var balances: [UUID: Double] = [:]
        var interestByDebt: [UUID: Double] = [:]
        var payoffMonth: [UUID: Int] = [:]
        for d in active0 { balances[d.id] = d.balance; interestByDebt[d.id] = 0 }

        var points: [MonthPoint] = []
        var totalInterest = 0.0
        var totalPaid = 0.0
        let cal = Calendar.current
        let now = Date()

        var month = 0
        while month < horizon {
            month += 1
            // Active debts this month.
            let active = active0.filter { (balances[$0.id] ?? 0) > 0.005 }
            if active.isEmpty { break }

            // 1) Accrue interest.
            var interestThisMonth = 0.0
            for d in active {
                let bal = balances[d.id] ?? 0
                let interest = bal * d.apr / 1200.0
                balances[d.id] = bal + interest
                interestByDebt[d.id, default: 0] += interest
                totalInterest += interest
                interestThisMonth += interest
            }

            // 2) Pay minimum on every active debt (capped at balance).
            var pool = monthlyBudget
            for d in active {
                let bal = balances[d.id] ?? 0
                let pay = min(d.minimum, bal, max(0, pool))
                balances[d.id] = bal - pay
                pool -= pay
                totalPaid += pay
            }

            // 3) Funnel the remainder to debts in strategy order.
            let order = sorted(active, strategy: strategy, balances: balances)
            for d in order {
                if pool <= 0.005 { break }
                let bal = balances[d.id] ?? 0
                guard bal > 0.005 else { continue }
                let pay = min(bal, pool)
                balances[d.id] = bal - pay
                pool -= pay
                totalPaid += pay
            }

            // 4) Record cleared debts.
            var cleared: [UUID] = []
            for d in active {
                if (balances[d.id] ?? 0) <= 0.005 && payoffMonth[d.id] == nil {
                    payoffMonth[d.id] = month
                    cleared.append(d.id)
                }
            }

            let totalBal = balances.values.reduce(0, +)
            let pt = MonthPoint(monthIndex: month,
                                date: cal.date(byAdding: .month, value: month, to: now) ?? now,
                                totalBalance: max(0, totalBal),
                                interestThisMonth: interestThisMonth,
                                clearedDebtIDs: cleared)
            points.append(pt)

            if totalBal <= 0.005 { break }
        }

        let allCleared = active0.allSatisfy { payoffMonth[$0.id] != nil }
        let payoffMonths: Int? = allCleared ? (payoffMonth.values.max() ?? 0) : nil

        let perDebt = active0.map { d in
            DebtResult(id: d.id, name: d.name,
                       payoffMonth: payoffMonth[d.id],
                       interestPaid: interestByDebt[d.id] ?? 0)
        }

        return PayoffPlan(months: points, perDebt: perDebt,
                          totalInterest: totalInterest, totalPaid: totalPaid,
                          payoffMonths: payoffMonths, feasible: feasible,
                          requiredMinimum: requiredMin)
    }

    private static func sorted(_ debts: [DebtSnapshot],
                               strategy: PayoffStrategy,
                               balances: [UUID: Double]) -> [DebtSnapshot] {
        switch strategy {
        case .snowball:
            return debts.sorted {
                let a = balances[$0.id] ?? $0.balance
                let b = balances[$1.id] ?? $1.balance
                if a == b { return $0.sortIndex < $1.sortIndex }
                return a < b
            }
        case .avalanche:
            return debts.sorted {
                if $0.apr == $1.apr { return $0.sortIndex < $1.sortIndex }
                return $0.apr > $1.apr
            }
        case .custom:
            return debts.sorted { $0.sortIndex < $1.sortIndex }
        }
    }
}
