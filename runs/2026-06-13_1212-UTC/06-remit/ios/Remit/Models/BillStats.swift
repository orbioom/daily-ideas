import Foundation

/// Spend for one category in the current month.
struct CategorySpend: Identifiable {
    let category: Category
    let amount: Decimal
    var id: String { category.rawValue }
}

/// One month's paid-vs-due figures for the trend chart.
struct MonthTotal: Identifiable {
    let monthStart: Date
    let total: Decimal
    var id: Date { monthStart }
    var label: String { monthStart.formatted(.dateTime.month(.abbreviated)) }
}

/// Aggregates over bills + payment history. Pure and crash-proof.
struct BillStats {
    let totalMonthlyObligations: Decimal
    let dueThisMonth: Decimal
    let remainingThisMonth: Decimal
    let paidThisMonth: Decimal
    let countOverdue: Int
    let countDueSoon: Int
    let countUpcoming: Int
    let countPaid: Int
    let onTimeRate: Double          // 0...1, from settled payment history
    let onTimeCount: Int
    let lateCount: Int
    let autopayCount: Int
    let manualCount: Int
    let spendByCategory: [CategorySpend]
    let monthlyTrend: [MonthTotal]

    static func from(_ bills: [Bill], payments: [Payment], today: Date = .now) -> BillStats {
        let cal = Calendar.current

        // True recurring monthly obligation.
        let monthly = bills.reduce(Decimal(0)) { $0 + BillEngine.monthlyEquivalent($1) }

        // Status counts.
        var overdue = 0, soon = 0, upcoming = 0, paid = 0
        for b in bills {
            switch BillEngine.status(b, today: today) {
            case .overdue:        overdue += 1
            case .dueSoon:        soon += 1
            case .upcoming:       upcoming += 1
            case .paidThisPeriod: paid += 1
            }
        }

        // Autopay split.
        let auto = bills.filter { $0.autopay }.count
        let manual = bills.count - auto

        // This-month occurrences (due + remaining + by category).
        let monthInterval = cal.dateInterval(of: .month, for: today)
        var dueThisMonth = Decimal(0)
        var remaining = Decimal(0)
        var catTotals: [Category: Decimal] = [:]
        let occ = BillEngine.occurrences(in: today, bills: bills)
        for o in occ {
            dueThisMonth += o.amount
            catTotals[o.bill.category, default: 0] += o.amount
            // Remaining if the occurrence is today or later and not yet paid for that period.
            if o.date >= cal.startOfDay(for: today),
               !BillEngine.isPaidThisPeriod(o.bill, today: today) {
                remaining += o.amount
            }
        }

        // Paid this month (from payment history).
        var paidThisMonth = Decimal(0)
        if let monthInterval {
            for p in payments where p.date >= monthInterval.start && p.date < monthInterval.end {
                paidThisMonth += p.amount
            }
        }

        // On-time rate over all settled payments.
        let onTime = payments.filter { $0.wasOnTime }.count
        let late = payments.count - onTime
        let rate: Double = payments.isEmpty ? 0 : Double(onTime) / Double(payments.count)

        // Category spend, ordered by Category declaration, non-zero first.
        let spend: [CategorySpend] = Category.allCases.compactMap { cat in
            let amt = catTotals[cat] ?? 0
            return amt > 0 ? CategorySpend(category: cat, amount: amt) : nil
        }

        // Monthly trend: paid totals for the last 6 months.
        var trend: [MonthTotal] = []
        let startOfThisMonth = cal.dateInterval(of: .month, for: today)?.start ?? today
        for offset in stride(from: 5, through: 0, by: -1) {
            guard let mStart = cal.date(byAdding: .month, value: -offset, to: startOfThisMonth),
                  let mInterval = cal.dateInterval(of: .month, for: mStart) else { continue }
            let total = payments
                .filter { $0.date >= mInterval.start && $0.date < mInterval.end }
                .reduce(Decimal(0)) { $0 + $1.amount }
            trend.append(MonthTotal(monthStart: mInterval.start, total: total))
        }

        return BillStats(
            totalMonthlyObligations: monthly,
            dueThisMonth: dueThisMonth,
            remainingThisMonth: remaining,
            paidThisMonth: paidThisMonth,
            countOverdue: overdue,
            countDueSoon: soon,
            countUpcoming: upcoming,
            countPaid: paid,
            onTimeRate: rate,
            onTimeCount: onTime,
            lateCount: late,
            autopayCount: auto,
            manualCount: manual,
            spendByCategory: spend,
            monthlyTrend: trend)
    }
}
