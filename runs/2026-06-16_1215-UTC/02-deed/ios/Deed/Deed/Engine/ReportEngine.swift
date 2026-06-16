import Foundation

struct MonthlyFlow: Identifiable {
    let id = UUID()
    let monthStart: Date
    let label: String
    let income: Decimal
    let expense: Decimal
    var net: Decimal { income - expense }
}

struct CategorySlice: Identifiable {
    let id = UUID()
    let category: TxnCategory
    let amount: Decimal
}

struct PropertyNOI: Identifiable {
    let id: UUID
    let name: String
    let noi: Decimal
    let colorHex: Int
}

/// Aggregations for the Reports screen.
enum ReportEngine {

    /// Income & expense totals per month for the trailing `months` months.
    static func monthlyFlows(for properties: [Property], months: Int, asOf today: Date = Date()) -> [MonthlyFlow] {
        guard months > 0 else { return [] }
        let cal = Calendar.deed
        let anchorMonth = RentLedger.monthStart(today)

        // Build buckets oldest -> newest.
        var buckets: [(start: Date, income: Decimal, expense: Decimal)] = []
        for offset in stride(from: months - 1, through: 0, by: -1) {
            if let start = cal.date(byAdding: .month, value: -offset, to: anchorMonth) {
                buckets.append((start, 0, 0))
            }
        }
        guard !buckets.isEmpty else { return [] }

        let allTxns = properties.flatMap { $0.transactions }
        for txn in allTxns {
            guard let index = buckets.firstIndex(where: { RentLedger.sameMonth($0.start, txn.date) }) else { continue }
            if txn.kind == .income {
                buckets[index].income += txn.amount
            } else {
                buckets[index].expense += txn.amount
            }
        }

        return buckets.map {
            MonthlyFlow(monthStart: $0.start, label: DateText.short($0.start), income: $0.income, expense: $0.expense)
        }
    }

    /// Expense breakdown by category over the trailing window (operating + capex + mortgage interest).
    static func expenseBreakdown(for properties: [Property], months: Int, asOf today: Date = Date()) -> [CategorySlice] {
        guard months > 0 else { return [] }
        let cal = Calendar.deed
        let cutoff = cal.date(byAdding: .month, value: -months, to: today) ?? today

        var totals: [TxnCategory: Decimal] = [:]
        for property in properties {
            for txn in property.transactions where txn.kind == .expense && txn.date >= cutoff && txn.date <= today {
                totals[txn.category, default: 0] += txn.amount
            }
        }
        return totals
            .map { CategorySlice(category: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
    }

    /// NOI per property over trailing 12 months.
    static func noiByProperty(for properties: [Property], closingCostPct: Double, asOf today: Date = Date()) -> [PropertyNOI] {
        properties
            .map { property in
                let m = FinanceEngine.metrics(for: property, settings: closingCostPct, asOf: today)
                return PropertyNOI(id: property.id, name: property.name, noi: m.noi, colorHex: property.colorHex)
            }
            .sorted { $0.noi > $1.noi }
    }

    /// Total net for the window — used for headline figures.
    static func totalNet(_ flows: [MonthlyFlow]) -> Decimal {
        flows.reduce(Decimal(0)) { $0 + $1.net }
    }
}
