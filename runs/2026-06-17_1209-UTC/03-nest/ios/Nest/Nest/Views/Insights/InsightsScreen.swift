import SwiftUI
import SwiftData
import Charts

/// Tab 3 — Swift Charts over all goals: saved over time, by category, monthly contributions.
struct InsightsScreen: View {
    @Environment(AppSettings.self) private var settings
    @Environment(ProStore.self) private var pro
    @Query private var goals: [Goal]

    @State private var stats: StatsResult?
    @State private var showingPaywall = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Insights")
            .sheet(isPresented: $showingPaywall) { PaywallView() }
            .task(id: goalsFingerprint) {
                // Recompute off the main render path; show loading state until ready.
                stats = StatsEngine.compute(goals: goals)
            }
        }
    }

    /// Cheap fingerprint so the chart recomputes when data changes.
    private var goalsFingerprint: String {
        let count = goals.reduce(0) { $0 + $1.contributions.count }
        return "\(goals.count)-\(count)"
    }

    @ViewBuilder
    private var content: some View {
        if let stats {
            if stats.isEmpty {
                EmptyStateView(
                    symbol: "chart.xyaxis.line",
                    title: "Insights will grow here",
                    message: "Add goals and log contributions, and you'll see your saving trends, category mix, and pace over time."
                )
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        overviewCard(stats)
                        savedOverTimeCard(stats)
                        monthlyCard(stats)
                        categoryCard(stats)
                        if !pro.isPro {
                            advancedLocked
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
        } else {
            VStack(spacing: 12) {
                ProgressView()
                Text("Crunching your numbers…")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
    }

    private func overviewCard(_ s: StatsResult) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 16) {
                    ProgressRing(fraction: s.overallProgress, color: Theme.accent, lineWidth: 10)
                        .frame(width: 72, height: 72)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(settings.display(s.totalSaved))
                            .font(Theme.money(24, .bold))
                            .foregroundStyle(Theme.ink)
                        Text("saved of \(settings.display(s.totalTarget))")
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    Spacer()
                }
                Divider().background(Theme.hairline)
                HStack {
                    miniStat(title: "On track", value: "\(s.onTrackCount)", color: Theme.good)
                    miniStat(title: "Behind", value: "\(s.behindCount)", color: Theme.bad)
                    miniStat(title: "Streak", value: "\(s.contributionStreak) mo", color: Theme.accent)
                }
            }
        }
    }

    private func miniStat(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(Theme.money(18, .bold))
                .foregroundStyle(color)
            Text(title)
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }

    private func savedOverTimeCard(_ s: StatsResult) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Total saved over time")
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.ink)
                if s.savedOverTime.count < 2 {
                    chartPlaceholder("Log a few contributions to see your growth curve.")
                } else {
                    Chart(s.savedOverTime) { point in
                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("Saved", point.cumulative)
                        )
                        .foregroundStyle(
                            LinearGradient(colors: [Theme.accent.opacity(0.35), Theme.accent.opacity(0.02)],
                                           startPoint: .top, endPoint: .bottom)
                        )
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Saved", point.cumulative)
                        )
                        .foregroundStyle(Theme.accent)
                        .interpolationMethod(.monotone)
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let v = value.as(Double.self) {
                                    Text(Money.compact(v, symbol: settings.currency.symbol))
                                }
                            }
                        }
                    }
                    .frame(height: 200)
                    .accessibilityLabel("Total saved over time, ending at \(settings.display(s.totalSaved))")
                }
            }
        }
    }

    private func monthlyCard(_ s: StatsResult) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Monthly contributions")
                        .font(Theme.rounded(15, .semibold))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    if s.bestMonthAmount > 0 {
                        Text("Best: \(s.bestMonthLabel) \(settings.display(s.bestMonthAmount, fractionDigits: 0))")
                            .font(Theme.rounded(12))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
                Chart(s.monthly) { point in
                    BarMark(
                        x: .value("Month", point.label),
                        y: .value("Net", point.net)
                    )
                    .foregroundStyle(point.net >= 0 ? Theme.accent : Theme.bad)
                    .cornerRadius(4)
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text(Money.compact(v, symbol: settings.currency.symbol))
                            }
                        }
                    }
                }
                .frame(height: 180)
                .accessibilityLabel("Net contributions per month for the last twelve months")
            }
        }
    }

    private func categoryCard(_ s: StatsResult) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Saved by category")
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.ink)
                if s.byCategory.isEmpty {
                    chartPlaceholder("Categories appear once you've saved into a goal.")
                } else {
                    Chart(s.byCategory) { item in
                        SectorMark(
                            angle: .value("Amount", item.amount),
                            innerRadius: .ratio(0.6),
                            angularInset: 1.5
                        )
                        .foregroundStyle(Color.fromGoalHex(item.category.tintHex))
                        .cornerRadius(3)
                    }
                    .frame(height: 180)
                    .accessibilityHidden(true)

                    VStack(spacing: 8) {
                        ForEach(s.byCategory) { item in
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(Color.fromGoalHex(item.category.tintHex))
                                    .frame(width: 10, height: 10)
                                    .accessibilityHidden(true)
                                Text(item.category.title)
                                    .font(Theme.rounded(14))
                                    .foregroundStyle(Theme.ink)
                                Spacer()
                                Text(settings.display(item.amount))
                                    .font(Theme.money(14, .medium))
                                    .foregroundStyle(Theme.inkSoft)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(item.category.title): \(settings.display(item.amount))")
                        }
                    }
                }
            }
        }
    }

    private var advancedLocked: some View {
        Button {
            showingPaywall = true
        } label: {
            Card {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(Theme.accent)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Unlock advanced insights")
                            .font(Theme.rounded(15, .semibold))
                            .foregroundStyle(Theme.ink)
                        Text("Nest Pro keeps your full history, projections, and CSV export.")
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Theme.inkFaint)
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func chartPlaceholder(_ message: String) -> some View {
        Text(message)
            .font(Theme.rounded(14))
            .foregroundStyle(Theme.inkSoft)
            .frame(maxWidth: .infinity, minHeight: 120)
            .multilineTextAlignment(.center)
    }
}
