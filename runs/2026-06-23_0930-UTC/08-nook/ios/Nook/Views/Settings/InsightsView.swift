import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query private var tasks: [MaintenanceTask]
    @Query private var settingsRows: [AppSettings]

    private var settings: AppSettings { settingsRows.first ?? AppSettings() }

    private var allRecords: [ServiceRecord] {
        tasks.flatMap { $0.records }
    }

    private var totalSpent: Double { allRecords.reduce(0) { $0 + $1.cost } }
    private var totalCompletions: Int { allRecords.count }

    /// Spend grouped by recurrence cadence (a proxy for "system" buckets).
    private var spendByRecurrence: [(label: String, amount: Double)] {
        var dict: [Recurrence: Double] = [:]
        for task in tasks {
            let cost = task.totalCost
            guard cost > 0 else { continue }
            dict[task.recurrence, default: 0] += cost
        }
        return Recurrence.allCases.compactMap { rec in
            guard let amt = dict[rec], amt > 0 else { return nil }
            return (rec.shortLabel, amt)
        }
    }

    /// Completions per month for the last 6 months.
    private var completionsByMonth: [(month: Date, count: Int)] {
        let cal = Calendar.current
        let now = Date.now
        var buckets: [(Date, Int)] = []
        for offset in stride(from: 5, through: 0, by: -1) {
            guard let monthDate = cal.date(byAdding: .month, value: -offset, to: now),
                  let interval = cal.dateInterval(of: .month, for: monthDate) else { continue }
            let count = allRecords.filter { interval.contains($0.completedDate) }.count
            buckets.append((interval.start, count))
        }
        return buckets
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                summaryTiles
                completionsCard
                spendCard
            }
            .padding(Theme.Spacing.lg)
        }
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.inline)
        .background(Theme.bg.ignoresSafeArea())
    }

    private var summaryTiles: some View {
        HStack(spacing: Theme.Spacing.md) {
            StatTile(value: "\(totalCompletions)",
                     label: "Tasks completed",
                     systemImage: "checkmark.circle.fill",
                     tint: Theme.ok)
            StatTile(value: Formatters.currency(totalSpent, code: settings.currencyCode),
                     label: "Total logged spend",
                     systemImage: "dollarsign.circle.fill",
                     tint: Theme.accent)
        }
    }

    private var completionsCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Completions, last 6 months").font(.headline).foregroundStyle(Theme.textPrimary)
            if totalCompletions == 0 {
                Text("No completed tasks yet. Mark a task done to start tracking your history here.")
                    .font(.subheadline).foregroundStyle(Theme.textSecondary)
            } else {
                Chart(completionsByMonth, id: \.month) { item in
                    BarMark(
                        x: .value("Month", item.month, unit: .month),
                        y: .value("Completed", item.count)
                    )
                    .foregroundStyle(Theme.accent)
                    .cornerRadius(4)
                }
                .frame(height: 180)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { value in
                        AxisValueLabel(format: .dateTime.month(.narrow))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .accessibilityLabel("Bar chart of tasks completed per month over the last six months")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var spendCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Spend by cadence").font(.headline).foregroundStyle(Theme.textPrimary)
            if spendByRecurrence.isEmpty {
                Text("No costs logged yet. Add a cost when you mark a task done to see spending here.")
                    .font(.subheadline).foregroundStyle(Theme.textSecondary)
            } else {
                Chart(spendByRecurrence, id: \.label) { item in
                    BarMark(
                        x: .value("Amount", item.amount),
                        y: .value("Cadence", item.label)
                    )
                    .foregroundStyle(Theme.accent.gradient)
                    .cornerRadius(4)
                    .annotation(position: .trailing) {
                        Text(Formatters.currency(item.amount, code: settings.currencyCode))
                            .font(.caption2)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .frame(height: max(120, CGFloat(spendByRecurrence.count) * 44))
                .chartXAxis {
                    AxisMarks(position: .bottom)
                }
                .accessibilityLabel("Bar chart of total spend grouped by task cadence")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

#Preview {
    NavigationStack { InsightsView() }
        .previewModelContainer()
}
