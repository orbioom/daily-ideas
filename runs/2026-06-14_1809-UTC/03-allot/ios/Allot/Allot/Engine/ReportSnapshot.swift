import Foundation
import SwiftUI

/// Immutable, render-ready data for the Reports screen, computed off the models.
struct ReportSnapshot {
    struct CategorySlice: Identifiable {
        let id = UUID()
        let name: String
        let emoji: String
        let amount: Double
        let colorHue: Double
    }
    struct MonthBar: Identifiable {
        let id = UUID()
        let monthKey: String
        let label: String
        let income: Double
        let expense: Double
    }
    struct TrendPoint: Identifiable {
        let id = UUID()
        let monthKey: String
        let label: String
        let netSpending: Double
    }

    var monthTitle: String
    var income: Double
    var expense: Double
    var net: Double
    var netWorth: Double
    var slices: [CategorySlice]
    var monthly: [MonthBar]
    var trend: [TrendPoint]

    var hasData: Bool { !slices.isEmpty || income > 0 || expense > 0 }

    static let empty = ReportSnapshot(monthTitle: "", income: 0, expense: 0, net: 0,
                                      netWorth: 0, slices: [], monthly: [], trend: [])

    /// Build the snapshot for a given month.
    static func build(monthKey: String,
                      accounts: [Account],
                      categories: [Category],
                      txns: [Transaction]) -> ReportSnapshot {
        let income = BudgetEngine.incomeThisMonth(monthKey: monthKey, txns: txns)
        let expense = BudgetEngine.expensesThisMonth(monthKey: monthKey, txns: txns)
        let netWorth = BudgetEngine.netWorth(accounts, txns: txns)

        let perCategory = BudgetEngine.byCategorySpending(monthKey: monthKey, categories: categories, txns: txns)
        let count = max(perCategory.count, 1)
        let slices: [CategorySlice] = perCategory.enumerated().map { idx, entry in
            CategorySlice(name: entry.category.name,
                          emoji: entry.category.emoji,
                          amount: entry.amount,
                          colorHue: Double(idx) / Double(count))
        }

        let trend = BudgetEngine.monthlyTrend(endingAt: monthKey, count: 6, txns: txns)
        let monthly: [MonthBar] = trend.map { m in
            MonthBar(monthKey: m.monthKey,
                     label: shortLabel(m.monthKey),
                     income: m.income,
                     expense: m.expense)
        }
        let trendPoints: [TrendPoint] = trend.map { m in
            TrendPoint(monthKey: m.monthKey,
                       label: shortLabel(m.monthKey),
                       netSpending: m.expense)
        }

        return ReportSnapshot(monthTitle: BudgetEngine.title(forMonthKey: monthKey),
                              income: income,
                              expense: expense,
                              net: BudgetEngine.cents(income - expense),
                              netWorth: netWorth,
                              slices: slices,
                              monthly: monthly,
                              trend: trendPoints)
    }

    private static func shortLabel(_ monthKey: String) -> String {
        guard let date = BudgetEngine.date(forMonthKey: monthKey) else { return monthKey }
        let f = DateFormatter()
        f.dateFormat = "MMM"
        return f.string(from: date)
    }
}
