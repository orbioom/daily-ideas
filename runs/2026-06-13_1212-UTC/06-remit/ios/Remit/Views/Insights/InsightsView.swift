import SwiftUI
import SwiftData
import Charts

/// True monthly obligations, on-time rate, spend-by-category, monthly trend,
/// autopay split, and a payment history that survives bill deletion.
struct InsightsView: View {
    @Query(sort: \Bill.dueDate) private var bills: [Bill]
    @Query(sort: \Payment.date, order: .reverse) private var payments: [Payment]
    @AppStorage("currencyCode") private var currencyCode = "USD"

    private var stats: BillStats { BillStats.from(bills, payments: payments) }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if bills.isEmpty && payments.isEmpty {
                    EmptyStateView(icon: "chart.pie.fill",
                                   title: "No insights yet",
                                   message: "Add a few bills and mark them paid. Your monthly obligations, on-time rate, and spending breakdown will appear here.")
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            statsGrid
                            categoryChart
                            trendChart
                            autopaySplit
                            historyList
                        }
                        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 28)
                    }
                }
            }
            .navigationTitle("Insights")
        }
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatTile(value: Fmt.money(stats.totalMonthlyObligations, code: currencyCode),
                     label: "True monthly obligations")
            StatTile(value: payments.isEmpty ? "—" : "\(Int((stats.onTimeRate * 100).rounded()))%",
                     label: "On-time rate", accent: stats.onTimeRate >= 0.9 ? Theme.good : Theme.warn)
            StatTile(value: Fmt.money(stats.paidThisMonth, code: currencyCode),
                     label: "Paid this month", accent: Theme.good)
            StatTile(value: "\(bills.count)", label: "Active bills", accent: Theme.ink)
        }
    }

    @ViewBuilder private var categoryChart: some View {
        if !stats.spendByCategory.isEmpty {
            Card {
                VStack(alignment: .leading, spacing: 10) {
                    Label("This month by category", systemImage: "chart.pie.fill")
                        .font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                    Chart(stats.spendByCategory) { item in
                        BarMark(
                            x: .value("Amount", doubleValue(item.amount)),
                            y: .value("Category", item.category.label)
                        )
                        .foregroundStyle(item.category.color)
                        .cornerRadius(5)
                    }
                    .frame(height: CGFloat(stats.spendByCategory.count) * 36 + 20)
                    .chartXAxis { AxisMarks(position: .bottom) }
                    .accessibilityLabel("Spending by category for this month")
                }
            }
        }
    }

    @ViewBuilder private var trendChart: some View {
        let trend = stats.monthlyTrend
        if trend.contains(where: { $0.total > 0 }) {
            Card {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Paid over time", systemImage: "chart.line.uptrend.xyaxis")
                        .font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                    Chart(trend) { m in
                        BarMark(
                            x: .value("Month", m.label),
                            y: .value("Paid", doubleValue(m.total))
                        )
                        .foregroundStyle(Theme.accent)
                        .cornerRadius(5)
                    }
                    .frame(height: 170)
                    .chartYAxis { AxisMarks(position: .leading) }
                    .accessibilityLabel("Total paid per month over the last six months")
                }
            }
        }
    }

    @ViewBuilder private var autopaySplit: some View {
        if !bills.isEmpty {
            Card {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Autopay vs manual").font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                    HStack(spacing: 12) {
                        splitTile("Autopay", stats.autopayCount, Theme.accent, "arrow.triangle.2.circlepath")
                        splitTile("Manual", stats.manualCount, Theme.warn, "hand.tap.fill")
                    }
                }
            }
        }
    }

    private func splitTile(_ label: String, _ count: Int, _ color: Color, _ icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 18)).foregroundStyle(color)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text("\(count)").font(Theme.rounded(20, .bold)).foregroundStyle(Theme.ink)
                Text(label).font(Theme.rounded(12, .medium)).foregroundStyle(Theme.inkSoft)
            }
            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(count)")
    }

    @ViewBuilder private var historyList: some View {
        if !payments.isEmpty {
            Card {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Payment history").font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                        Spacer()
                        Text("\(stats.onTimeCount) on time · \(stats.lateCount) late")
                            .font(Theme.rounded(12, .medium)).foregroundStyle(Theme.inkSoft)
                    }
                    let recent = Array(payments.prefix(20))
                    ForEach(Array(recent.enumerated()), id: \.offset) { idx, p in
                        HStack(spacing: 12) {
                            Image(systemName: p.wasOnTime ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                .foregroundStyle(p.wasOnTime ? Theme.good : Theme.bad)
                                .frame(width: 24)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(p.billNameSnapshot)
                                    .font(Theme.rounded(15, .semibold)).foregroundStyle(Theme.ink)
                                Text(Fmt.relativeDay(p.date))
                                    .font(Theme.rounded(12, .regular)).foregroundStyle(Theme.inkSoft)
                            }
                            Spacer()
                            Text(Fmt.money(p.amount, code: currencyCode))
                                .font(Theme.rounded(14, .bold)).foregroundStyle(Theme.inkSoft)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(p.billNameSnapshot), \(Fmt.money(p.amount, code: currencyCode)), \(p.wasOnTime ? "on time" : "late"), \(Fmt.relativeDay(p.date))")
                        if idx < recent.count - 1 { Divider().background(Theme.hairline) }
                    }
                }
            }
        }
    }

    /// Converts a Decimal to Double only for the chart's plottable axis (never
    /// for money storage). Safe: chart magnitudes are well within Double range.
    private func doubleValue(_ d: Decimal) -> Double {
        NSDecimalNumber(decimal: d).doubleValue
    }
}
