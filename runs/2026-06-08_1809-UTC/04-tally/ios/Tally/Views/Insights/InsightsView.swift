import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \Transaction.date, order: .reverse) private var all: [Transaction]
    @AppStorage("tally.currency") private var currency = Locale.current.currency?.identifier ?? "USD"

    @State private var month = Date()

    private var trend: [MoneyEngine.MonthTotal] { MoneyEngine.monthlyTrend(all, months: 6) }
    private var monthTxns: [Transaction] { MoneyEngine.transactions(all, inMonth: month) }
    private var daily: [MoneyEngine.DayPoint] { MoneyEngine.dailyExpense(monthTxns, month: month) }
    private var byCat: [MoneyEngine.CategorySpend] { MoneyEngine.expenseByCategory(monthTxns) }

    private var avgExpense: Double {
        let months = trend.filter { $0.expense > 0 }
        guard !months.isEmpty else { return 0 }
        return months.reduce(0) { $0 + $1.expense } / Double(months.count)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if all.isEmpty {
                    EmptyStateView(icon: "chart.xyaxis.line",
                                   title: "No insights yet",
                                   message: "Log a few transactions to reveal your trends.")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            trendCard
                            MonthBar(month: $month)
                            cumulativeCard
                            topCategoriesCard
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Insights")
        }
    }

    private var trendCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Eyebrow(text: "Income vs Expense · 6 months")
                Spacer()
                Text("avg \(Money.compact(avgExpense, code: currency))")
                    .font(Brand.mono(11)).foregroundStyle(Brand.text3)
            }
            Chart(trend) { m in
                BarMark(x: .value("Month", m.month, unit: .month),
                        y: .value("Amount", m.income))
                    .foregroundStyle(Brand.live)
                    .position(by: .value("Kind", "Income"))
                BarMark(x: .value("Month", m.month, unit: .month),
                        y: .value("Amount", m.expense))
                    .foregroundStyle(Color(hex: 0xC0553E))
                    .position(by: .value("Kind", "Expense"))
            }
            .chartForegroundStyleScale(["Income": Brand.live, "Expense": Color(hex: 0xC0553E)])
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { _ in
                    AxisValueLabel(format: .dateTime.month(.narrow))
                }
            }
            .frame(height: 190)
            .accessibilityLabel("Bar chart of income versus expense over six months")
        }
        .glassCard()
    }

    private var cumulativeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Spending pace this month")
            if daily.allSatisfy({ $0.cumulative == 0 }) {
                Text("No spending recorded for \(Format.monthYear.string(from: month)).")
                    .font(.subheadline).foregroundStyle(Brand.text2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Chart(daily) { p in
                    AreaMark(x: .value("Day", p.day), y: .value("Total", p.cumulative))
                        .foregroundStyle(Color(hex: 0x3E9E78).opacity(0.18))
                    LineMark(x: .value("Day", p.day), y: .value("Total", p.cumulative))
                        .foregroundStyle(Color(hex: 0x3E9E78))
                }
                .frame(height: 170)
                .accessibilityLabel("Cumulative spending line for the month")
            }
        }
        .glassCard()
    }

    private var topCategoriesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Top categories · \(Format.monthYear.string(from: month))")
            if byCat.isEmpty {
                Text("No expenses this month.").font(.subheadline).foregroundStyle(Brand.text2)
            } else {
                ForEach(byCat.prefix(6)) { slice in
                    HStack(spacing: 10) {
                        Image(systemName: slice.category.icon).foregroundStyle(slice.category.color).frame(width: 22)
                        Text(slice.category.title).foregroundStyle(Brand.text)
                        Spacer()
                        Text(Money.format(slice.amount, code: currency)).font(Brand.mono(12)).foregroundStyle(Brand.text2)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(slice.category.title): \(Money.format(slice.amount, code: currency))")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }
}
