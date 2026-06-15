import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    @Query(sort: \BreakLog.date, order: .reverse) private var breaks: [BreakLog]
    @Query(sort: \ExerciseSession.date, order: .reverse) private var sessions: [ExerciseSession]

    @State private var paywallReason: PaywallReason?
    @State private var isComputing = true

    private let stats = StatsEngine()

    /// Free users see 7 days; Pro unlocks the full 8-week window.
    private var windowDays: Int { isPro ? 56 : 7 }

    private var series: [DayStat] {
        stats.dailySeries(logs: breaks, sessions: sessions, days: windowDays)
    }

    /// The recent slice shown in charts (cap to keep bars readable).
    private var chartSeries: [DayStat] {
        let recent = stats.dailySeries(logs: breaks, sessions: sessions, days: min(windowDays, 14))
        return recent
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    if isComputing {
                        loadingView
                    } else if breaks.isEmpty && sessions.isEmpty {
                        EmptyStateView(
                            symbol: "chart.bar.xaxis",
                            title: "No insights yet",
                            message: "Take a few breaks and complete a routine — your trends, streaks and weekly summary will appear here."
                        )
                        .padding(.top, 40)
                    } else {
                        summaryRow
                        breaksChartCard
                        minutesChartCard
                        adherenceCard
                        if !isPro { proTeaser }
                    }
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Insights")
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
            .task {
                // Brief computed/loading state for the aggregation pass.
                isComputing = true
                try? await Task.sleep(nanoseconds: 250_000_000)
                isComputing = false
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 14) {
            ProgressView().tint(Theme.accent)
            Text("Gathering your week…")
                .font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity, minHeight: 280)
        .accessibilityLabel("Loading insights")
    }

    private var summaryRow: some View {
        HStack(spacing: 12) {
            StatTile(value: "\(stats.currentStreak(breaks))",
                     label: "Day streak", systemImage: "flame.fill", tint: Theme.teal)
            StatTile(value: "\(stats.totalBreaks(breaks))",
                     label: "Total breaks", systemImage: "eye.fill")
            StatTile(value: String(format: "%.0f", stats.totalExerciseMinutes(sessions)),
                     label: "Exercise min", systemImage: "figure.mind.and.body")
        }
    }

    private var breaksChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Breaks per day", systemImage: "chart.bar.fill")
            Chart(chartSeries) { day in
                BarMark(
                    x: .value("Day", day.date, unit: .day),
                    y: .value("Breaks", day.breaks)
                )
                .foregroundStyle(Theme.accent.gradient)
                .cornerRadius(4)
                RuleMark(y: .value("Goal", settings.dailyBreakGoal))
                    .foregroundStyle(Theme.teal.opacity(0.7))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
            .frame(height: 180)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: max(1, chartSeries.count / 5))) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.day())
                }
            }
            .accessibilityLabel("Bar chart of breaks per day with your daily goal marked")
            Text("Dashed line is your daily goal of \(settings.dailyBreakGoal) breaks.")
                .font(Theme.rounded(12)).foregroundStyle(Theme.inkFaint)
        }
        .padding(18)
        .cardSurface()
    }

    private var minutesChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Exercise minutes", systemImage: "chart.line.uptrend.xyaxis")
            Chart(chartSeries) { day in
                LineMark(
                    x: .value("Day", day.date, unit: .day),
                    y: .value("Minutes", day.exerciseMinutes)
                )
                .foregroundStyle(Theme.teal)
                .interpolationMethod(.catmullRom)
                AreaMark(
                    x: .value("Day", day.date, unit: .day),
                    y: .value("Minutes", day.exerciseMinutes)
                )
                .foregroundStyle(Theme.teal.opacity(0.15))
                .interpolationMethod(.catmullRom)
                PointMark(
                    x: .value("Day", day.date, unit: .day),
                    y: .value("Minutes", day.exerciseMinutes)
                )
                .foregroundStyle(Theme.teal)
                .symbolSize(day.exerciseMinutes > 0 ? 30 : 0)
            }
            .frame(height: 160)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: max(1, chartSeries.count / 5))) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.day())
                }
            }
            .accessibilityLabel("Line chart of exercise minutes per day")
        }
        .padding(18)
        .cardSurface()
    }

    private var adherenceCard: some View {
        let adherence = stats.adherence(logs: breaks, dailyGoal: settings.dailyBreakGoal, days: windowDays)
        let daysMet = stats.daysGoalMet(logs: breaks, dailyGoal: settings.dailyBreakGoal, days: windowDays)
        return VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Adherence", systemImage: "target")
            HStack(spacing: 18) {
                ZStack {
                    ProgressRing(progress: adherence, lineWidth: 12, showGlow: false)
                        .frame(width: 88, height: 88)
                    Text("\(Int((adherence * 100).rounded()))%")
                        .font(Theme.rounded(20, .bold)).foregroundStyle(Theme.ink)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Adherence \(Int((adherence * 100).rounded())) percent of your daily goal")
                VStack(alignment: .leading, spacing: 6) {
                    Text("You hit your goal on \(daysMet) of the last \(windowDays) days.")
                        .font(Theme.rounded(15)).foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Adherence is your average daily breaks versus your goal of \(settings.dailyBreakGoal).")
                        .font(Theme.rounded(12)).foregroundStyle(Theme.inkFaint)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
        }
        .padding(18)
        .cardSurface()
    }

    private var proTeaser: some View {
        Button { paywallReason = .fullHistory } label: {
            HStack(spacing: 12) {
                Image(systemName: "lock.fill").foregroundStyle(Theme.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("See your full history").font(Theme.rounded(15, .semibold)).foregroundStyle(Theme.ink)
                    Text("Iris Pro reveals all 8 weeks of trends and summaries.")
                        .font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Theme.inkFaint)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .cardSurface(fill: Theme.accentSoft)
        }
        .buttonStyle(.plain)
    }
}
