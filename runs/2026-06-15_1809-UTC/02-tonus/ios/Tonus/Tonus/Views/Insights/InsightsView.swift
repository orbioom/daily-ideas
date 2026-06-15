import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \SessionLog.date, order: .reverse) private var allLogs: [SessionLog]

    @State private var paywallReason: PaywallReason?
    @State private var isComputing = true
    @State private var didCompute = false

    /// Free users see only the last N days; Pro sees everything.
    private var visibleLogs: [SessionLog] {
        if isPro { return allLogs }
        let engine = StatsEngine(logs: allLogs)
        return engine.logsWithin(days: Pro.freeHistoryDays)
    }

    private var stats: StatsEngine { StatsEngine(logs: visibleLogs) }

    /// Number of days of history to chart (free is capped).
    private var chartDays: Int { isPro ? 56 : Pro.freeHistoryDays }

    var body: some View {
        NavigationStack {
            Group {
                if isComputing {
                    computingState
                } else if allLogs.filter({ $0.finished }).isEmpty {
                    EmptyStateView(
                        symbol: "chart.bar.doc.horizontal",
                        title: "No insights yet",
                        message: "Finish your first session and your streak, minutes, and trends will appear here."
                    )
                } else {
                    content
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Insights")
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
            .task {
                // Brief computing pass on first appearance so aggregation never blocks the first frame.
                guard !didCompute else { isComputing = false; return }
                try? await Task.sleep(nanoseconds: 300_000_000)
                isComputing = false
                didCompute = true
            }
        }
    }

    private var computingState: some View {
        VStack(spacing: 16) {
            SwiftUI.ProgressView()
                .controlSize(.large)
                .tint(Theme.accent)
            Text("Computing your insights…")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Computing your insights")
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                totalsGrid
                adherenceCard
                sessionsChart
                minutesChart
                heatmapCard
                if !isPro { freeLimitCard }
            }
            .padding(16)
        }
    }

    // MARK: Totals

    private var totalsGrid: some View {
        let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        return LazyVGrid(columns: columns, spacing: 12) {
            StatTile(value: "\(stats.currentStreak)", label: "current streak", symbol: "flame.fill", tint: Theme.warn)
            StatTile(value: "\(stats.bestStreak)", label: "best streak", symbol: "rosette", tint: Theme.accent)
            StatTile(value: "\(stats.totalSessions)", label: "sessions", symbol: "checkmark.circle.fill", tint: Theme.good)
            StatTile(value: "\(stats.totalReps)", label: "total reps", symbol: "repeat", tint: Theme.accent)
            StatTile(value: "\(stats.totalMinutesRounded)", label: "minutes", symbol: "clock.fill", tint: Theme.hold)
            StatTile(value: "\(stats.sessionsThisWeek)", label: "this week", symbol: "calendar", tint: Theme.accent)
        }
    }

    // MARK: Adherence

    private var adherenceCard: some View {
        let goal = settings.weeklyGoal
        let progress = stats.adherence(weeklyGoal: goal)
        return HStack(spacing: 18) {
            ProgressRing(progress: progress, size: 92,
                         label: "\(Int((progress * 100).rounded()))%",
                         caption: "of goal")
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Weekly adherence")
                .accessibilityValue("\(Int((progress * 100).rounded())) percent of your goal of \(goal) sessions")
            VStack(alignment: .leading, spacing: 6) {
                Text("Weekly adherence")
                    .font(Theme.rounded(17, .bold))
                    .foregroundStyle(Theme.ink)
                Text("\(stats.sessionsThisWeek) of \(goal) sessions this week. \(Int(stats.minutesThisWeek.rounded())) minutes trained.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .cardSurface()
    }

    // MARK: Charts

    private var sessionsChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Sessions per day", systemImage: "chart.bar.fill")
            Chart(stats.dailySeries(days: min(chartDays, 28))) { day in
                BarMark(
                    x: .value("Day", day.day, unit: .day),
                    y: .value("Sessions", day.sessions)
                )
                .foregroundStyle(Theme.accent)
                .cornerRadius(3)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine().foregroundStyle(Theme.hairline)
                    AxisValueLabel()
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                    AxisGridLine().foregroundStyle(Theme.hairline)
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
            .frame(height: 180)
            .accessibilityLabel("Bar chart of sessions per day")
        }
        .padding(18)
        .cardSurface()
    }

    private var minutesChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Minutes trend", systemImage: "chart.line.uptrend.xyaxis")
            Chart(stats.dailySeries(days: min(chartDays, 28))) { day in
                LineMark(
                    x: .value("Day", day.day, unit: .day),
                    y: .value("Minutes", day.minutes)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Theme.hold)
                AreaMark(
                    x: .value("Day", day.day, unit: .day),
                    y: .value("Minutes", day.minutes)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(LinearGradient(colors: [Theme.hold.opacity(0.25), Theme.hold.opacity(0.02)],
                                                startPoint: .top, endPoint: .bottom))
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine().foregroundStyle(Theme.hairline)
                    AxisValueLabel()
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                    AxisGridLine().foregroundStyle(Theme.hairline)
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
            .frame(height: 180)
            .accessibilityLabel("Line chart of minutes trained per day")
        }
        .padding(18)
        .cardSurface()
    }

    // MARK: Heatmap

    private var heatmapCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Last 4 weeks", systemImage: "square.grid.3x3.fill")
            WeekHeatmap(series: stats.dailySeries(days: 28))
            HStack(spacing: 6) {
                Text("Less").font(Theme.rounded(11)).foregroundStyle(Theme.inkFaint)
                ForEach(0..<4, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Theme.accent.opacity(0.2 + Double(i) * 0.26))
                        .frame(width: 12, height: 12)
                }
                Text("More").font(Theme.rounded(11)).foregroundStyle(Theme.inkFaint)
                Spacer()
            }
            .accessibilityHidden(true)
        }
        .padding(18)
        .cardSurface()
    }

    private var freeLimitCard: some View {
        Button {
            paywallReason = .fullHistory
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "lock.fill").foregroundStyle(Theme.accent).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Showing the last \(Pro.freeHistoryDays) days")
                        .font(Theme.rounded(15, .semibold))
                        .foregroundStyle(Theme.ink)
                    Text("Unlock Tonus Pro for your full lifetime insights.")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Theme.inkFaint).accessibilityHidden(true)
            }
            .padding(16)
            .cardSurface(fill: Theme.accentSoft)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens the Tonus Pro upgrade")
    }
}

/// A GitHub-style activity grid for the last 4 weeks (oldest-first series).
struct WeekHeatmap: View {
    let series: [DayStat]

    /// Columns of 7 (weeks). We arrange newest at the right.
    private var weeks: [[DayStat]] {
        stride(from: 0, to: series.count, by: 7).map { start in
            Array(series[start..<min(start + 7, series.count)])
        }
    }

    private func intensity(_ day: DayStat) -> Double {
        if day.sessions <= 0 { return 0 }
        // 1 session → moderate, 2+ → strong.
        return min(1.0, 0.45 + Double(day.sessions) * 0.28)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 5) {
            ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                VStack(spacing: 5) {
                    ForEach(week) { day in
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(day.sessions > 0
                                  ? Theme.accent.opacity(0.2 + intensity(day) * 0.6)
                                  : Theme.surfaceAlt)
                            .frame(width: 14, height: 14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .strokeBorder(Theme.hairline, lineWidth: 0.5)
                            )
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Activity heatmap for the last four weeks")
        .accessibilityValue("\(series.filter { $0.sessions > 0 }.count) active days out of \(series.count)")
    }
}
