import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: AppSettings

    @Query private var companions: [Companion]
    @Query(sort: \GoalCompletion.date) private var completions: [GoalCompletion]
    @Query(sort: \CheckIn.date) private var checkIns: [CheckIn]

    @State private var showPaywall = false

    private var companion: Companion? { companions.first }

    // Pro sees full history; free sees a trimmed window.
    private var historyWindow: Int { settings.isPro ? 30 : 14 }

    private var completionDays: Set<Date> { Set(completions.map { DateUtils.startOfDay($0.date) }) }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if completions.isEmpty && checkIns.isEmpty {
                    EmptyStateView(systemImage: "chart.bar.fill",
                                   title: "No insights yet",
                                   message: "Complete a few goals and check in to see your trends bloom here.")
                } else {
                    content
                }
            }
            .navigationTitle("Insights")
            .sheet(isPresented: $showPaywall) { PaywallView(reason: .fullInsights) }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                statsRow
                completionsChart
                moodChart
                categoryDonut
                if settings.isPro {
                    xpChart
                } else {
                    proInsightsTeaser
                }
            }
            .padding()
        }
    }

    // MARK: Stats

    private var statsRow: some View {
        let streak = CareEngine.streaks(completionDays: completionDays)
        let rate = InsightsEngine.completionRate(completions, window: historyWindow)
        return HStack(spacing: 12) {
            StatTile(value: "\(streak.current)", label: "Day streak", systemImage: "flame.fill", tint: Theme.accent)
            StatTile(value: "\(streak.longest)", label: "Longest", systemImage: "trophy.fill", tint: Theme.warn)
            StatTile(value: "\(Int((rate * 100).rounded()))%", label: "Completion", systemImage: "checkmark.seal.fill", tint: Theme.good)
        }
    }

    // MARK: Completions bar

    private var completionsChart: some View {
        let data = InsightsEngine.completionsByDay(completions, days: 14)
        return chartCard(title: "Completions", subtitle: "Last 14 days") {
            Chart(data) { point in
                BarMark(
                    x: .value("Day", point.date, unit: .day),
                    y: .value("Completed", point.count)
                )
                .foregroundStyle(Theme.accent.gradient)
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 3)) { value in
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                }
            }
            .chartYAxis { AxisMarks(position: .leading) }
            .frame(height: 160)
            .accessibilityLabel("Bar chart of goals completed each day over the last 14 days")
        }
    }

    // MARK: Mood line

    private var moodChart: some View {
        let data = InsightsEngine.moodTrend(checkIns, days: historyWindow)
        return chartCard(title: "Mood trend", subtitle: settings.isPro ? "Last 30 days" : "Last 14 days") {
            if data.isEmpty {
                emptyChartHint("Add daily check-ins in Reflect to grow this trend.")
            } else {
                Chart(data) { point in
                    LineMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Mood", point.mood)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Theme.good)
                    PointMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Mood", point.mood)
                    )
                    .foregroundStyle(Theme.good)
                    .symbolSize(28)
                }
                .chartYScale(domain: 1...5)
                .chartYAxis {
                    AxisMarks(values: [1, 2, 3, 4, 5]) { AxisValueLabel() }
                }
                .frame(height: 160)
                .accessibilityLabel("Line chart of your mood from 1 to 5 over time")
            }
        }
    }

    // MARK: Category donut

    private var categoryDonut: some View {
        let slices = InsightsEngine.categoryBalance(completions)
        return chartCard(title: "Category balance", subtitle: "Where your care goes") {
            if slices.isEmpty {
                emptyChartHint("Complete goals to see your balance across categories.")
            } else {
                HStack(spacing: 18) {
                    Chart(slices) { slice in
                        SectorMark(
                            angle: .value("Count", slice.count),
                            innerRadius: .ratio(0.6),
                            angularInset: 1.5
                        )
                        .foregroundStyle(slice.category.color)
                        .cornerRadius(3)
                    }
                    .frame(width: 130, height: 130)
                    .accessibilityLabel("Donut chart of completions by category")

                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(slices) { slice in
                            HStack(spacing: 8) {
                                Circle().fill(slice.category.color).frame(width: 9, height: 9)
                                Text(slice.category.label)
                                    .font(Theme.rounded(12, .medium))
                                    .foregroundStyle(Theme.ink)
                                Spacer()
                                Text("\(slice.count)")
                                    .font(Theme.rounded(12, .semibold))
                                    .foregroundStyle(Theme.inkSoft)
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                }
            }
        }
    }

    // MARK: XP / level (Pro)

    private var xpChart: some View {
        let data = InsightsEngine.xpOverTime(completions, days: 30)
        return chartCard(title: "Growth", subtitle: "Cumulative XP, last 30 days") {
            if data.isEmpty {
                emptyChartHint("Your growth curve will appear as you complete goals.")
            } else {
                Chart(data) { point in
                    AreaMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("XP", point.cumulativeXP)
                    )
                    .foregroundStyle(Theme.accent.opacity(0.18).gradient)
                    LineMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("XP", point.cumulativeXP)
                    )
                    .foregroundStyle(Theme.accent)
                    .interpolationMethod(.monotone)
                }
                .frame(height: 160)
                .accessibilityLabel("Area chart of cumulative experience over the last 30 days")
            }
        }
    }

    private var proInsightsTeaser: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.system(size: 26))
                .foregroundStyle(Theme.warn)
            Text("Full Insights with Pro")
                .font(Theme.rounded(17, .bold))
                .foregroundStyle(Theme.ink)
            Text("Unlock your complete 30-day history, growth curve, and longer mood trends.")
                .font(Theme.rounded(13))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
            Button("See Wren Pro") { showPaywall = true }
                .buttonStyle(WrenSecondaryButtonStyle())
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .card(Theme.surfaceAlt)
    }

    // MARK: Helpers

    private func chartCard<Content: View>(title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title, subtitle: subtitle)
            content()
        }
        .padding(16)
        .card(Theme.surface)
    }

    private func emptyChartHint(_ text: String) -> some View {
        Text(text)
            .font(Theme.rounded(13))
            .foregroundStyle(Theme.inkSoft)
            .frame(maxWidth: .infinity, minHeight: 120)
            .multilineTextAlignment(.center)
    }
}
