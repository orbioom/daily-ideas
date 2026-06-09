import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query private var goals: [Goal]
    @AppStorage("cache.symbol") private var symbol = "$"

    private var active: [Goal] { goals.filter { !$0.isArchived } }

    var body: some View {
        NavigationStack {
            ScrollView {
                if active.isEmpty {
                    EmptyStateView(icon: "chart.xyaxis.line",
                                   title: "No data yet",
                                   message: "Add goals and contributions to see your saving trends.")
                        .glassCard().padding(20)
                } else {
                    VStack(spacing: 18) {
                        statsGrid
                        cumulativeCard
                        monthlyCard
                        breakdownCard
                    }
                    .padding(20)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle("Insights")
        }
    }

    private var statsGrid: some View {
        let cols = [GridItem(.flexible()), GridItem(.flexible())]
        let saved = SavingsEngine.totalSaved(active)
        let complete = active.filter { $0.isComplete }.count
        let thisMonth = SavingsEngine.monthlyContributions(active, months: 1).first?.deposited ?? 0
        return LazyVGrid(columns: cols, spacing: 14) {
            tile("Total saved", Money.compact(saved, symbol: symbol), "banknote.fill", Brand.live)
            tile("This month", Money.compact(thisMonth, symbol: symbol), "calendar", Brand.info)
            tile("Active goals", "\(active.count)", "target", Brand.magic)
            tile("Completed", "\(complete)", "checkmark.seal.fill", Brand.live)
        }
    }

    private func tile(_ label: String, _ value: String, _ icon: String, _ tint: Color) -> some View {
        GlassCard(padding: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon).foregroundStyle(tint).accessibilityHidden(true)
                Text(value).font(Brand.mono(20, weight: .semibold)).foregroundStyle(Brand.text)
                Text(label).font(.caption).foregroundStyle(Brand.text3)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private var cumulativeCard: some View {
        let series = SavingsEngine.cumulativeSavings(active)
        return GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "Savings over time")
                if series.count < 2 {
                    Text("Log a couple of deposits to see your growth curve.")
                        .font(.subheadline).foregroundStyle(Brand.text3)
                        .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 10)
                } else {
                    Chart(series) { p in
                        LineMark(x: .value("Date", p.date), y: .value("Total", p.total))
                            .foregroundStyle(Brand.live).interpolationMethod(.monotone)
                        AreaMark(x: .value("Date", p.date), y: .value("Total", p.total))
                            .foregroundStyle(Brand.live.opacity(0.12)).interpolationMethod(.monotone)
                    }
                    .frame(height: 190)
                    .accessibilityLabel("Cumulative savings over time")
                }
            }
        }
    }

    private var monthlyCard: some View {
        let series = SavingsEngine.monthlyContributions(active, months: 6)
        return GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "Net deposits · last 6 months")
                Chart(series) { p in
                    BarMark(x: .value("Month", p.month, unit: .month),
                            y: .value("Deposited", p.deposited))
                        .foregroundStyle(p.deposited >= 0 ? Brand.info : Brand.danger)
                        .cornerRadius(4)
                }
                .frame(height: 170)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { _ in
                        AxisValueLabel(format: .dateTime.month(.narrow))
                    }
                }
                .accessibilityLabel("Net deposits per month for the last six months")
            }
        }
    }

    private var breakdownCard: some View {
        let items = active.filter { $0.saved > 0 }.sorted { $0.saved > $1.saved }
        return GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "Where your savings sit")
                if items.isEmpty {
                    Text("No savings recorded yet.").font(.subheadline).foregroundStyle(Brand.text3)
                } else {
                    Chart(items) { goal in
                        SectorMark(angle: .value("Saved", goal.saved), innerRadius: .ratio(0.6), angularInset: 1.5)
                            .foregroundStyle(goal.color.color)
                            .cornerRadius(3)
                    }
                    .frame(height: 170)
                    .accessibilityLabel("Savings split across goals")
                    ForEach(items) { goal in
                        HStack {
                            Circle().fill(goal.color.color).frame(width: 10, height: 10)
                            Text(goal.name).font(.subheadline).foregroundStyle(Brand.text)
                            Spacer()
                            Text(Money.string(goal.saved, symbol: symbol)).font(Brand.mono(13)).foregroundStyle(Brand.text2)
                        }
                        .padding(.vertical, 1)
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }
}
