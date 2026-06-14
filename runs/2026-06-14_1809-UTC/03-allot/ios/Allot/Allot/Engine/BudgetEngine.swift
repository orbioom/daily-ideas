import Foundation

/// Pure, deterministic zero-based budgeting math. No SwiftData fetches here —
/// callers pass the snapshots in, so everything is testable and side-effect free.
///
/// Money convention: transaction `amount` is positive for inflow (income),
/// negative for outflow (spending). All public figures are returned rounded
/// to cents to avoid floating-point drift in the UI.
enum BudgetEngine {

    // MARK: - Rounding

    /// Round to cents to keep displayed money tidy and comparisons stable.
    static func cents(_ value: Double) -> Double {
        (value * 100).rounded() / 100
    }

    // MARK: - Month keys

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM"
        return f
    }()

    private static let monthTitleFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.dateFormat = "LLLL yyyy"
        return f
    }()

    /// "yyyy-MM" key for the month containing `date`.
    static func monthKey(for date: Date) -> String {
        monthFormatter.string(from: date)
    }

    /// The first day of the month for a key, or nil if malformed.
    static func date(forMonthKey key: String) -> Date? {
        monthFormatter.date(from: key)
    }

    /// Human title like "June 2026" for a month key.
    static func title(forMonthKey key: String) -> String {
        guard let d = date(forMonthKey: key) else { return key }
        return monthTitleFormatter.string(from: d)
    }

    /// Step a month key by `offset` months (negative goes back). Guards Calendar math.
    static func month(_ key: String, offsetBy offset: Int) -> String {
        guard let base = date(forMonthKey: key),
              let shifted = Calendar(identifier: .gregorian).date(byAdding: .month, value: offset, to: base)
        else { return key }
        return monthKey(for: shifted)
    }

    /// Current month key.
    static var currentMonthKey: String { monthKey(for: .now) }

    /// True when month key `a` is on or before `b` (string compare is valid for yyyy-MM).
    static func monthKey(_ a: String, isOnOrBefore b: String) -> Bool {
        a <= b
    }

    // MARK: - Account balances

    /// Derived balance = starting balance + sum of all of this account's transactions.
    static func accountBalance(_ account: Account, txns: [Transaction]) -> Double {
        let sum = txns
            .filter { $0.accountRef?.id == account.id }
            .reduce(0.0) { $0 + $1.amount }
        return cents(account.startingBalance + sum)
    }

    /// Net worth = every account balance, including off-budget accounts.
    static func netWorth(_ accounts: [Account], txns: [Transaction]) -> Double {
        cents(accounts.reduce(0.0) { $0 + accountBalance($1, txns: txns) })
    }

    /// Sum of on-budget account balances — the pool of money that must be assigned.
    static func onBudgetTotal(_ accounts: [Account], txns: [Transaction]) -> Double {
        cents(accounts.filter { $0.onBudget }.reduce(0.0) { $0 + accountBalance($1, txns: txns) })
    }

    // MARK: - Per-category, per-month figures

    /// Amount assigned to a category in a given month (0 when nothing assigned).
    static func allocated(_ category: Category, monthKey key: String) -> Double {
        let total = category.allocations
            .filter { $0.monthKey == key }
            .reduce(0.0) { $0 + $1.amount }
        return cents(total)
    }

    /// Sum of allocations to a category across all months up to and including `key`.
    static func allocatedThrough(_ category: Category, monthKey key: String) -> Double {
        let total = category.allocations
            .filter { monthKey($0.monthKey, isOnOrBefore: key) }
            .reduce(0.0) { $0 + $1.amount }
        return cents(total)
    }

    /// Spending in a category for a month, returned as a POSITIVE number
    /// (the absolute value of the outflows). Inflows are ignored.
    static func spent(_ category: Category, monthKey key: String, txns: [Transaction]) -> Double {
        let outflow = txns
            .filter { $0.categoryRef?.id == category.id && $0.amount < 0 && monthKey(for: $0.date) == key }
            .reduce(0.0) { $0 + $1.amount }
        return cents(-outflow)
    }

    /// Spending in a category across all months up to and including `key`, positive.
    static func spentThrough(_ category: Category, monthKey key: String, txns: [Transaction]) -> Double {
        let outflow = txns
            .filter { $0.categoryRef?.id == category.id && $0.amount < 0 && monthKey(monthKey(for: $0.date), isOnOrBefore: key) }
            .reduce(0.0) { $0 + $1.amount }
        return cents(-outflow)
    }

    /// Available balance in a category at `key`.
    /// Rollover categories carry their unspent balance forward across months;
    /// non-rollover categories reset each month to (allocated − spent) for that month.
    static func available(_ category: Category, upToMonth key: String, txns: [Transaction]) -> Double {
        if category.rollover {
            return cents(allocatedThrough(category, monthKey: key) - spentThrough(category, monthKey: key, txns: txns))
        } else {
            return cents(allocated(category, monthKey: key) - spent(category, monthKey: key, txns: txns))
        }
    }

    /// A category is overspent for the month when its available balance is below zero.
    static func isOverspent(_ category: Category, upToMonth key: String, txns: [Transaction]) -> Bool {
        available(category, upToMonth: key, txns: txns) < -0.005
    }

    // MARK: - Ready to Assign

    /// Ready to Assign (To Be Budgeted) for a month:
    ///   sum(on-budget account balances) − sum(category.available at month).
    /// Equals 0 in a perfectly zero-based budget; positive means money waits to be
    /// assigned; negative means more has been assigned than exists.
    static func readyToAssign(monthKey key: String,
                              accounts: [Account],
                              categories: [Category],
                              txns: [Transaction]) -> Double {
        let pool = onBudgetTotal(accounts, txns: txns)
        let assignedAvailable = categories.reduce(0.0) { acc, cat in
            acc + available(cat, upToMonth: key, txns: txns)
        }
        return cents(pool - assignedAvailable)
    }

    // MARK: - Month summaries

    /// Total inflow recorded in a month (positive).
    static func incomeThisMonth(monthKey key: String, txns: [Transaction]) -> Double {
        let total = txns
            .filter { $0.amount > 0 && monthKey(for: $0.date) == key }
            .reduce(0.0) { $0 + $1.amount }
        return cents(total)
    }

    /// Total outflow recorded in a month (positive magnitude).
    static func expensesThisMonth(monthKey key: String, txns: [Transaction]) -> Double {
        let total = txns
            .filter { $0.amount < 0 && monthKey(for: $0.date) == key }
            .reduce(0.0) { $0 + $1.amount }
        return cents(-total)
    }

    /// Spending grouped by category group for a month (positive magnitudes),
    /// sorted descending by amount. Only groups with spending appear.
    static func byGroupSpending(monthKey key: String,
                                categories: [Category],
                                txns: [Transaction]) -> [(group: CategoryGroup, amount: Double)] {
        var totals: [CategoryGroup: Double] = [:]
        for cat in categories {
            let s = spent(cat, monthKey: key, txns: txns)
            if s > 0 { totals[cat.group, default: 0] += s }
        }
        return totals
            .map { (group: $0.key, amount: cents($0.value)) }
            .sorted { $0.amount > $1.amount }
    }

    /// Spending per individual category for a month, descending. Only spent ones.
    static func byCategorySpending(monthKey key: String,
                                   categories: [Category],
                                   txns: [Transaction]) -> [(category: Category, amount: Double)] {
        categories
            .map { (category: $0, amount: spent($0, monthKey: key, txns: txns)) }
            .filter { $0.amount > 0 }
            .sorted { $0.amount > $1.amount }
    }

    // MARK: - Trends

    /// Last `count` month keys ending at `key`, oldest first. `count` is clamped ≥ 1.
    static func recentMonths(endingAt key: String, count: Int) -> [String] {
        let n = max(1, count)
        return (0..<n).reversed().map { month(key, offsetBy: -$0) }
    }

    /// Income vs. expense per month over a trailing window, oldest first.
    static func monthlyTrend(endingAt key: String,
                             count: Int,
                             txns: [Transaction]) -> [(monthKey: String, income: Double, expense: Double)] {
        recentMonths(endingAt: key, count: count).map { mk in
            (monthKey: mk,
             income: incomeThisMonth(monthKey: mk, txns: txns),
             expense: expensesThisMonth(monthKey: mk, txns: txns))
        }
    }
}
