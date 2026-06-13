import Foundation

struct NetWorthPoint: Identifiable {
    let id = UUID()
    let date: Date
    let assets: Double
    let liabilities: Double
    var net: Double { assets - liabilities }
}

struct AllocationSlice: Identifiable {
    let id = UUID()
    let category: String
    let amount: Double
    let colorIndex: Int
}

/// Pure net-worth math built from accounts and their balance history.
enum NetWorthEngine {
    static func totals(_ accounts: [Account]) -> (assets: Double, liabilities: Double, net: Double) {
        let included = accounts.filter { $0.includeInNetWorth }
        let assets = included.filter { $0.isAsset }.reduce(0) { $0 + $1.balance }
        let liab = included.filter { !$0.isAsset }.reduce(0) { $0 + $1.balance }
        return (assets, liab, assets - liab)
    }

    /// The most recent balance for an account on or before `date`, or nil if none.
    private static func balance(of accountID: UUID, onOrBefore date: Date,
                                entries: [UUID: [BalanceEntry]]) -> Double? {
        guard let list = entries[accountID] else { return nil }
        var best: BalanceEntry?
        for e in list where e.date <= date {
            if let current = best {
                if e.date > current.date { best = e }
            } else {
                best = e
            }
        }
        return best?.balance
    }

    /// Monthly net-worth series across the last `months` calendar months.
    static func monthlySeries(accounts: [Account], entries allEntries: [BalanceEntry],
                              months: Int, now: Date = Date()) -> [NetWorthPoint] {
        let cal = Calendar.current
        var byAccount: [UUID: [BalanceEntry]] = [:]
        for e in allEntries { byAccount[e.accountID, default: []].append(e) }
        let included = accounts.filter { $0.includeInNetWorth }

        var points: [NetWorthPoint] = []
        for offset in stride(from: months - 1, through: 0, by: -1) {
            guard let monthDate = cal.date(byAdding: .month, value: -offset, to: now) else { continue }
            // Use end-of-month (or now for the current month) as the as-of date.
            let asOf: Date
            if offset == 0 {
                asOf = now
            } else {
                let comps = cal.dateComponents([.year, .month], from: monthDate)
                let startNext = cal.date(from: comps).flatMap { cal.date(byAdding: .month, value: 1, to: $0) }
                asOf = startNext.flatMap { cal.date(byAdding: .day, value: -1, to: $0) } ?? monthDate
            }
            var assets = 0.0, liab = 0.0
            var any = false
            for acc in included {
                guard let bal = balance(of: acc.id, onOrBefore: asOf, entries: byAccount) else { continue }
                any = true
                if acc.isAsset { assets += bal } else { liab += bal }
            }
            if any || !points.isEmpty {
                points.append(NetWorthPoint(date: asOf, assets: assets, liabilities: liab))
            }
        }
        return points
    }

    /// Allocation of included asset accounts grouped by coarse category.
    static func assetAllocation(_ accounts: [Account]) -> [AllocationSlice] {
        slices(accounts.filter { $0.includeInNetWorth && $0.isAsset })
    }
    static func liabilityAllocation(_ accounts: [Account]) -> [AllocationSlice] {
        slices(accounts.filter { $0.includeInNetWorth && !$0.isAsset })
    }

    private static func slices(_ accounts: [Account]) -> [AllocationSlice] {
        var totals: [String: Double] = [:]
        var order: [String] = []
        for a in accounts where a.balance > 0 {
            if totals[a.type.category] == nil { order.append(a.type.category) }
            totals[a.type.category, default: 0] += a.balance
        }
        let sorted = order.sorted { (totals[$0] ?? 0) > (totals[$1] ?? 0) }
        return sorted.enumerated().map { idx, cat in
            AllocationSlice(category: cat, amount: totals[cat] ?? 0, colorIndex: idx)
        }
    }

    /// Average monthly change over the last `window` points (linear, simple).
    static func averageMonthlyChange(_ series: [NetWorthPoint], window: Int = 6) -> Double? {
        guard series.count >= 2 else { return nil }
        let pts = Array(series.suffix(window))
        guard let first = pts.first, let last = pts.last, pts.count >= 2 else { return nil }
        return (last.net - first.net) / Double(pts.count - 1)
    }

    /// Months to reach `goal` at the recent average growth rate, or nil if not progressing.
    static func monthsToGoal(current: Double, goal: Double, monthlyChange: Double?) -> Int? {
        guard let rate = monthlyChange, rate > 0, goal > current else { return nil }
        return Int(((goal - current) / rate).rounded(.up))
    }
}
