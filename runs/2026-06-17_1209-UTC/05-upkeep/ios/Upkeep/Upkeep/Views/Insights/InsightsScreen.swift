import SwiftUI
import SwiftData
import Charts

/// Insights: Swift Charts for spend, completions, forecast, and on-time rate.
struct InsightsScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query private var allTasks: [MaintenanceTask]

    @State private var stats: StatsResult?
    @State private var costs: CostSummary?
    @State private var isLoading = false
    @State private var paywallReason: PaywallReason?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Insights")
            .toolbar {
                if !isPro {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { paywallReason = .costTracking } label: {
                            Label("Pro", systemImage: "crown.fill")
                                .font(Theme.rounded(13, .semibold))
                        }
                    }
                }
            }
            .sheet(item: $paywallReason) { reason in
                PaywallView(reason: reason)
            }
        }
        .task(id: dataSignature) { await recompute() }
    }

    /// Recompute when the underlying data changes meaningfully.
    private var dataSignature: String {
        let logCount = allTasks.reduce(0) { $0 + $1.logs.count }
        return "\(allTasks.count)-\(logCount)-\(settings.hemisphereRaw)"
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            VStack(spacing: 14) {
                ProgressView()
                    .controlSize(.large)
                    .tint(Theme.accent)
                Text("Crunching your upkeep…")
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.inkSoft)
            }
            .accessibilityLabel("Computing insights")
        } else if let stats, let costs, !(stats.isEmpty && costs.isEmpty) {
            ScrollView {
                VStack(spacing: 16) {
                    summaryGrid(stats: stats, costs: costs)
                    completionsChart(stats)
                    onTimeCard(stats)
                    if isPro {
                        spendBySystemChart(costs)
                        forecastCard(costs)
                    } else {
                        proTeaser
                    }
                }
                .padding(20)
            }
        } else {
            EmptyStateView(symbol: "chart.bar.xaxis",
                           title: "No insights yet",
                           message: "Log a few completed tasks and your trends, spend, and on-time rate will appear here.")
        }
    }

    // MARK: Summary

    private func summaryGrid(stats: StatsResult, costs: CostSummary) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statCard("Completions", "\(stats.totalCompletions)", "checkmark.seal")
            statCard("On-time rate", "\(Int((stats.onTimeRate * 100).rounded()))%", "target")
            statCard("Streak", "\(stats.currentStreakWeeks) wk", "flame")
            if isPro {
                statCard("Spent this year", settings.formatMoneyShort(costs.spentThisYear), "creditcard")
            } else {
                statCard("Active tasks", "\(stats.activeTaskCount)", "checklist")
            }
        }
    }

    private func statCard(_ title: String, _ value: String, _ symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(value)
                .font(Theme.rounded(26, .bold))
                .foregroundStyle(Theme.ink)
                .monospacedDigit()
            Text(title)
                .font(Theme.rounded(13))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(value)")
    }

    // MARK: Charts

    private func completionsChart(_ stats: StatsResult) -> some View {
        chartCard(title: "Completions over time", symbol: "calendar") {
            Chart(stats.completionsByMonth) { item in
                BarMark(
                    x: .value("Month", item.label),
                    y: .value("Completions", item.count)
                )
                .foregroundStyle(Theme.accent.gradient)
                .cornerRadius(4)
            }
            .frame(height: 200)
            .accessibilityLabel("Bar chart of completions per month")
        }
    }

    private func onTimeCard(_ stats: StatsResult) -> some View {
        chartCard(title: "On-time rate", symbol: "target") {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("\(Int((stats.onTimeRate * 100).rounded()))%")
                        .font(Theme.rounded(34, .bold))
                        .foregroundStyle(Theme.good)
                        .monospacedDigit()
                    Text("of completions on time")
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.inkSoft)
                    Spacer()
                }
                ProgressView(value: min(max(stats.onTimeRate, 0), 1))
                    .tint(Theme.good)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("On-time rate \(Int((stats.onTimeRate * 100).rounded())) percent")
        }
    }

    private func spendBySystemChart(_ costs: CostSummary) -> some View {
        chartCard(title: "Spend by system", symbol: "dollarsign.circle") {
            if costs.bySystem.isEmpty {
                emptyChartNote("Log a completion with a cost to see spend by system.")
            } else {
                Chart(costs.bySystem) { item in
                    BarMark(
                        x: .value("Spent", item.total),
                        y: .value("System", item.systemName)
                    )
                    .foregroundStyle(Theme.accent.gradient)
                    .cornerRadius(5)
                    .annotation(position: .trailing) {
                        Text(settings.formatMoneyShort(item.total))
                            .font(Theme.rounded(11, .semibold))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
                .chartXAxis(.hidden)
                .frame(height: CGFloat(costs.bySystem.count) * 34 + 12)
                .accessibilityLabel("Bar chart of spend by home system")
            }
        }
    }

    private func forecastCard(_ costs: CostSummary) -> some View {
        chartCard(title: "Cost forecast", symbol: "chart.line.uptrend.xyaxis") {
            VStack(spacing: 12) {
                forecastRow("Due now / soon", costs.upcomingEstimated, symbol: "calendar.badge.clock")
                Divider().background(Theme.hairline)
                forecastRow("Annual estimate", costs.annualizedEstimate, symbol: "calendar")
                if !costs.byYear.isEmpty {
                    Divider().background(Theme.hairline)
                    Chart(costs.byYear) { item in
                        BarMark(
                            x: .value("Year", String(item.year)),
                            y: .value("Spent", item.total)
                        )
                        .foregroundStyle(Theme.good.gradient)
                        .cornerRadius(4)
                    }
                    .frame(height: 140)
                    .accessibilityLabel("Spend by year")
                }
            }
        }
    }

    private func forecastRow(_ label: String, _ value: Double, symbol: String) -> some View {
        HStack {
            Label(label, systemImage: symbol)
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
            Spacer()
            Text(settings.formatMoney(value))
                .font(Theme.rounded(17, .semibold))
                .foregroundStyle(Theme.ink)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(settings.formatMoney(value))")
    }

    private var proTeaser: some View {
        VStack(spacing: 14) {
            Image(systemName: "lock.fill")
                .font(.system(size: 32))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text("Unlock cost insights")
                .font(Theme.serif(20, .semibold))
                .foregroundStyle(Theme.ink)
            Text("Spend by system, upcoming cost, and an annualized maintenance forecast are part of Upkeep Pro.")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            PrimaryButton(title: "See Upkeep Pro", systemImage: "crown.fill") {
                paywallReason = .forecast
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface))
    }

    private func emptyChartNote(_ text: String) -> some View {
        Text(text)
            .font(Theme.rounded(14))
            .foregroundStyle(Theme.inkSoft)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func chartCard<Content: View>(title: String,
                                          symbol: String,
                                          @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: symbol)
                .font(Theme.serif(18, .semibold))
                .foregroundStyle(Theme.ink)
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface))
    }

    // MARK: Compute

    @MainActor
    private func recompute() async {
        isLoading = true
        let snapshot = allTasks
        let hemisphere = settings.hemisphere
        let window = settings.clampedDueSoonDays
        try? await Task.sleep(nanoseconds: 300_000_000)
        stats = StatsEngine.compute(tasks: snapshot, hemisphere: hemisphere)
        costs = CostEngine.summarize(tasks: snapshot, hemisphere: hemisphere, dueSoonDays: window)
        isLoading = false
    }
}
