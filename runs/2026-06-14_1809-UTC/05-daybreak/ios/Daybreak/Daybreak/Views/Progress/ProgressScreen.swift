import SwiftUI
import SwiftData
import Charts

/// Progress: streaks, runs heatmap, totals, per-routine completion, and Swift Charts.
/// Stats are computed in an async @MainActor function with a loading state.
struct ProgressScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings

    @Query(sort: \RoutineRun.date, order: .reverse) private var runs: [RoutineRun]
    @Query(sort: \Routine.sortOrder) private var routines: [Routine]

    @State private var stats: ProgressStats?
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Progress")
        }
        .task(id: dataSignature) { await recompute() }
    }

    /// Recompute whenever data or the relevant settings change.
    private var dataSignature: String {
        "\(runs.count)-\(routines.count)-\(settings.completionThresholdRaw)-\(settings.weekStartRaw)"
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            VStack(spacing: 14) {
                ProgressView()
                    .controlSize(.large)
                    .tint(Theme.accent)
                Text("Gathering your mornings…")
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.inkSoft)
            }
            .accessibilityLabel("Computing progress")
        } else if let stats, !stats.isEmpty {
            ScrollView {
                VStack(spacing: 16) {
                    streakCard(stats)
                    summaryGrid(stats)
                    heatmapCard(stats)
                    weeklyRunsChart(stats)
                    minutesTrendChart(stats)
                    perRoutineChart(stats)
                }
                .padding(20)
            }
        } else {
            EmptyStateView(symbol: "chart.bar.xaxis",
                           title: "No runs yet",
                           message: "Run a routine and your streaks, heatmap, and charts will bloom here.")
        }
    }

    // MARK: Streak

    private func streakCard(_ s: ProgressStats) -> some View {
        HStack(spacing: 20) {
            StreakRing(streak: s.currentStreak, progress: ringProgress(s), size: 104)
            VStack(alignment: .leading, spacing: 10) {
                streakLine("Current", "\(s.currentStreak) day\(s.currentStreak == 1 ? "" : "s")", "flame.fill")
                streakLine("Longest", "\(s.longestStreak) day\(s.longestStreak == 1 ? "" : "s")", "trophy.fill")
                if let best = s.bestTimeOfDay {
                    streakLine("Best time", best.label, best.symbol)
                }
            }
            Spacer()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.surface))
    }

    private func ringProgress(_ s: ProgressStats) -> Double {
        guard s.longestStreak > 0 else { return s.currentStreak > 0 ? 1 : 0 }
        return min(1, Double(s.currentStreak) / Double(s.longestStreak))
    }

    private func streakLine(_ label: String, _ value: String, _ icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 20)
                .accessibilityHidden(true)
            Text(label)
                .font(Theme.rounded(13))
                .foregroundStyle(Theme.inkSoft)
            Spacer(minLength: 8)
            Text(value)
                .font(Theme.rounded(15, .semibold))
                .foregroundStyle(Theme.ink)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Summary

    private func summaryGrid(_ s: ProgressStats) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statCard("Total runs", "\(s.totalRuns)", "play.circle.fill")
            statCard("Completed", "\(Int((s.completionRate * 100).rounded()))%", "checkmark.seal.fill")
            statCard("Minutes", "\(s.totalMinutes)", "clock.fill")
            statCard("Completed runs", "\(s.completedRuns)", "checklist")
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

    // MARK: Heatmap

    private func heatmapCard(_ s: ProgressStats) -> some View {
        chartCard(title: "Last 5 weeks", symbol: "square.grid.3x3.fill") {
            HeatmapView(cells: s.heat)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    // MARK: Charts

    private func weeklyRunsChart(_ s: ProgressStats) -> some View {
        chartCard(title: "Runs per week", symbol: "calendar") {
            Chart(s.weeks) { week in
                BarMark(
                    x: .value("Week", week.weekStart, unit: .weekOfYear),
                    y: .value("Runs", week.runs)
                )
                .foregroundStyle(Theme.accent.gradient)
                .cornerRadius(5)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .weekOfYear)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
            .frame(height: 180)
            .accessibilityLabel("Bar chart of runs per week")
        }
    }

    private func minutesTrendChart(_ s: ProgressStats) -> some View {
        chartCard(title: "Minutes trend", symbol: "chart.line.uptrend.xyaxis") {
            Chart(s.weeks) { week in
                LineMark(
                    x: .value("Week", week.weekStart, unit: .weekOfYear),
                    y: .value("Minutes", week.minutes)
                )
                .foregroundStyle(Theme.accent)
                .interpolationMethod(.catmullRom)
                AreaMark(
                    x: .value("Week", week.weekStart, unit: .weekOfYear),
                    y: .value("Minutes", week.minutes)
                )
                .foregroundStyle(Theme.accent.opacity(0.15).gradient)
                .interpolationMethod(.catmullRom)
                PointMark(
                    x: .value("Week", week.weekStart, unit: .weekOfYear),
                    y: .value("Minutes", week.minutes)
                )
                .foregroundStyle(Theme.accent)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .weekOfYear)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
            .frame(height: 180)
            .accessibilityLabel("Line chart of minutes per week")
        }
    }

    private func perRoutineChart(_ s: ProgressStats) -> some View {
        chartCard(title: "Per-routine completion", symbol: "list.bullet.rectangle") {
            if s.perRoutine.isEmpty {
                Text("Run a routine to see its completion rate.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Chart(s.perRoutine) { item in
                    BarMark(
                        x: .value("Rate", item.rate),
                        y: .value("Routine", item.name)
                    )
                    .foregroundStyle(Theme.accent.gradient)
                    .cornerRadius(5)
                    .annotation(position: .trailing) {
                        Text("\(Int((item.rate * 100).rounded()))%")
                            .font(Theme.rounded(11, .semibold))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
                .chartXScale(domain: 0.0...1.0)
                .chartXAxis {
                    AxisMarks(values: [0.0, 0.5, 1.0]) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let rate = value.as(Double.self) {
                                Text("\(Int((rate * 100).rounded()))%")
                            }
                        }
                    }
                }
                .frame(height: CGFloat(s.perRoutine.count) * 38 + 20)
                .accessibilityLabel("Bar chart of completion rate per routine")
            }
        }
    }

    private func chartCard<Content: View>(title: String, symbol: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: symbol)
                .font(Theme.rounded(18, .semibold))
                .foregroundStyle(Theme.ink)
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface))
    }

    // MARK: Async compute

    @MainActor
    private func recompute() async {
        isLoading = true
        let runsSnapshot = runs
        let routinesSnapshot = routines
        let firstWeekday = settings.weekStart.firstWeekday
        let threshold = settings.completionThreshold
        try? await Task.sleep(nanoseconds: 300_000_000)
        stats = RoutineEngine.compute(runs: runsSnapshot,
                                      routines: routinesSnapshot,
                                      settings: firstWeekday,
                                      threshold: threshold)
        isLoading = false
    }
}
