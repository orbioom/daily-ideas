import Foundation

/// Pure budgeting math over transactions, budgets, and recurring rules.
enum MoneyEngine {

    // MARK: - Month filtering

    static func inMonth(_ date: Date, month: Date, calendar: Calendar = .current) -> Bool {
        calendar.isDate(date, equalTo: month, toGranularity: .month)
    }

    static func transactions(_ all: [Transaction], inMonth month: Date,
                             calendar: Calendar = .current) -> [Transaction] {
        all.filter { inMonth($0.date, month: month, calendar: calendar) }
    }

    // MARK: - Month summary

    struct MonthSummary {
        let income: Double
        let expense: Double
        var net: Double { income - expense }
    }

    static func summary(_ txns: [Transaction]) -> MonthSummary {
        let income = txns.filter { $0.isIncome }.reduce(0) { $0 + $1.amount }
        let expense = txns.filter { !$0.isIncome }.reduce(0) { $0 + $1.amount }
        return MonthSummary(income: income, expense: expense)
    }

    // MARK: - Category breakdown (expenses)

    struct CategorySpend: Identifiable {
        var id: String { category.rawValue }
        let category: Category
        let amount: Double
    }

    static func expenseByCategory(_ txns: [Transaction]) -> [CategorySpend] {
        var totals: [Category: Double] = [:]
        for t in txns where !t.isIncome { totals[t.category, default: 0] += t.amount }
        return totals.map { CategorySpend(category: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
    }

    // MARK: - Budget status

    struct BudgetStatus: Identifiable {
        var id: String { category.rawValue }
        let category: Category
        let limit: Double
        let spent: Double
        var remaining: Double { limit - spent }
        var fraction: Double { limit > 0 ? min(spent / limit, 1) : 0 }
        var rawFraction: Double { limit > 0 ? spent / limit : 0 }
        var isOver: Bool { spent > limit && limit > 0 }
    }

    static func budgetStatuses(_ budgets: [BudgetItem], monthTxns: [Transaction]) -> [BudgetStatus] {
        let byCat = expenseByCategory(monthTxns).reduce(into: [Category: Double]()) { $0[$1.category] = $1.amount }
        return budgets.map {
            BudgetStatus(category: $0.category, limit: $0.monthlyLimit, spent: byCat[$0.category] ?? 0)
        }
        .sorted { $0.rawFraction > $1.rawFraction }
    }

    static func totalBudget(_ budgets: [BudgetItem]) -> Double {
        budgets.reduce(0) { $0 + $1.monthlyLimit }
    }

    // MARK: - Daily series

    struct DayPoint: Identifiable {
        let id = UUID()
        let day: Date
        let expense: Double
        var cumulative: Double
    }

    static func dailyExpense(_ monthTxns: [Transaction], month: Date,
                             calendar: Calendar = .current) -> [DayPoint] {
        guard let range = calendar.range(of: .day, in: .month, for: month),
              let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: month))
        else { return [] }
        var byDay: [Int: Double] = [:]
        for t in monthTxns where !t.isIncome {
            let d = calendar.component(.day, from: t.date)
            byDay[d, default: 0] += t.amount
        }
        var cumulative = 0.0
        return range.compactMap { day -> DayPoint? in
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) else { return nil }
            let exp = byDay[day] ?? 0
            cumulative += exp
            return DayPoint(day: date, expense: exp, cumulative: cumulative)
        }
    }

    /// Average daily spend and a simple month-end projection from days elapsed.
    static func projection(monthTxns: [Transaction], month: Date,
                           now: Date = .now, calendar: Calendar = .current) -> (avgPerDay: Double, projected: Double) {
        let expense = summary(monthTxns).expense
        guard let totalDays = calendar.range(of: .day, in: .month, for: month)?.count else {
            return (0, expense)
        }
        let isCurrent = calendar.isDate(now, equalTo: month, toGranularity: .month)
        let elapsed = isCurrent ? calendar.component(.day, from: now) : totalDays
        let avg = elapsed > 0 ? expense / Double(elapsed) : 0
        let projected = isCurrent ? avg * Double(totalDays) : expense
        return (avg, projected)
    }

    // MARK: - Monthly trend

    struct MonthTotal: Identifiable {
        let id = UUID()
        let month: Date
        let income: Double
        let expense: Double
    }

    static func monthlyTrend(_ all: [Transaction], months: Int = 6,
                             now: Date = .now, calendar: Calendar = .current) -> [MonthTotal] {
        let startOfThis = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        return (0..<months).reversed().compactMap { offset in
            guard let m = calendar.date(byAdding: .month, value: -offset, to: startOfThis) else { return nil }
            let txns = transactions(all, inMonth: m, calendar: calendar)
            let s = summary(txns)
            return MonthTotal(month: m, income: s.income, expense: s.expense)
        }
    }

    // MARK: - Recurring posting

    /// Generate transactions that are due from active recurring rules, between
    /// each rule's lastPosted and now. Mutates rule.lastPosted. Returns new txns.
    static func postDue(_ rules: [RecurringRule], now: Date = .now,
                        calendar: Calendar = .current) -> [Transaction] {
        var created: [Transaction] = []
        for rule in rules where rule.isActive {
            // Start from the month after lastPosted, or this month if never posted.
            let startMonth: Date
            if let last = rule.lastPosted {
                startMonth = calendar.date(byAdding: .month, value: 1,
                                           to: calendar.date(from: calendar.dateComponents([.year, .month], from: last)) ?? last) ?? now
            } else {
                startMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
            }
            var cursor = startMonth
            var guardCount = 0
            while cursor <= now && guardCount < 120 {
                guardCount += 1
                var comps = calendar.dateComponents([.year, .month], from: cursor)
                comps.day = rule.dayOfMonth
                if let dueDate = calendar.date(from: comps), dueDate <= now {
                    let t = Transaction(date: dueDate, amount: rule.amount,
                                        category: rule.category, note: rule.title,
                                        isIncome: rule.isIncome)
                    created.append(t)
                    rule.lastPosted = dueDate
                }
                cursor = calendar.date(byAdding: .month, value: 1, to: cursor) ?? now.addingTimeInterval(1)
            }
        }
        return created
    }
}
