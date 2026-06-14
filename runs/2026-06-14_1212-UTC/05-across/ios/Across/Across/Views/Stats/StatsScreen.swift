import SwiftUI
import SwiftData
import Charts

/// Solver stats: streaks, solve-time trend, solves over time, completion rate,
/// and average time by difficulty. Computed in an async @MainActor function with
/// a brief loading state.
struct StatsScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings

    @Query private var allProgress: [PuzzleProgress]
    @Query private var allResults: [DailyResult]

    @State private var result: StatsResult?
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Stats")
        }
        .task(id: dataSignature) { await recompute() }
    }

    private var dataSignature: String {
        let pc = allProgress.count
        let psum = allProgress.reduce(0) { $0 + $1.elapsedSeconds + ($1.completed ? 1 : 0) }
        let rc = allResults.count
        let rsum = allResults.reduce(0) { $0 + $1.elapsedSeconds + ($1.solved ? 1 : 0) }
        return "\(pc)-\(psum)-\(rc)-\(rsum)"
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            VStack(spacing: 14) {
                ProgressView().controlSize(.large).tint(Theme.accent)
                Text("Crunching your solves…")
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.inkSoft)
            }
            .accessibilityLabel("Computing statistics")
        } else if let result, !result.isEmpty {
            ScrollView {
                VStack(spacing: 16) {
                    headlineGrid(result)
                    solveTimeTrend(result)
                    solvesOverTime(result)
                    difficultyChart(result)
                    completionCard(result)
                }
                .padding(20)
            }
        } else {
            EmptyStateView(symbol: "chart.xyaxis.line",
                           title: "No stats yet",
                           message: "Solve a few puzzles and your streaks, times, and trends will appear here.",
                           actionTitle: "Load sample data") {
                SeedData.reseed(context: context)
            }
        }
    }

    // MARK: Headline numbers

    private func headlineGrid(_ r: StatsResult) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statCard("Current streak", "\(r.currentStreak)", "flame.fill", suffix: r.currentStreak == 1 ? "day" : "days")
            statCard("Best streak", "\(r.bestStreak)", "trophy.fill", suffix: r.bestStreak == 1 ? "day" : "days")
            statCard("Puzzles solved", "\(r.totalSolved)", "checkmark.seal.fill")
            statCard("Average time", r.averageSeconds > 0 ? TimeFormat.clock(r.averageSeconds) : "—", "stopwatch")
        }
    }

    private func statCard(_ title: String, _ value: String, _ symbol: String, suffix: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(Theme.rounded(26, .bold))
                    .foregroundStyle(Theme.ink)
                    .monospacedDigit()
                if let suffix {
                    Text(suffix)
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            Text(title)
                .font(Theme.rounded(13))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(value) \(suffix ?? "")")
    }

    // MARK: Solve-time trend

    private func solveTimeTrend(_ r: StatsResult) -> some View {
        let solved = r.points.filter { $0.solved && $0.elapsedSeconds > 0 }.suffix(30)
        return chartCard(title: "Solve-time trend", symbol: "stopwatch") {
            if solved.count < 2 {
                notEnough("Solve a few daily puzzles to see your times trend.")
            } else {
                Chart(Array(solved)) { point in
                    LineMark(x: .value("Day", point.date),
                             y: .value("Seconds", point.elapsedSeconds))
                        .foregroundStyle(Theme.accent)
                        .interpolationMethod(.catmullRom)
                    AreaMark(x: .value("Day", point.date),
                             y: .value("Seconds", point.elapsedSeconds))
                        .foregroundStyle(Theme.accent.opacity(0.12))
                        .interpolationMethod(.catmullRom)
                    PointMark(x: .value("Day", point.date),
                              y: .value("Seconds", point.elapsedSeconds))
                        .foregroundStyle(Theme.accent)
                        .symbolSize(18)
                }
                .chartYAxis { AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let s = value.as(Int.self) { Text(TimeFormat.clock(s)) }
                    }
                } }
                .frame(height: 190)
                .accessibilityLabel("Solve time trend line chart")
            }
        }
    }

    // MARK: Solves over time

    private func solvesOverTime(_ r: StatsResult) -> some View {
        // Group solved daily points by week for a tidy bar chart.
        let weekly = weeklySolves(r.points)
        return chartCard(title: "Solves over time", symbol: "calendar") {
            if weekly.isEmpty {
                notEnough("Your weekly solve counts will appear here.")
            } else {
                Chart(weekly) { bin in
                    BarMark(x: .value("Week", bin.label),
                            y: .value("Solves", bin.count))
                        .foregroundStyle(Theme.accent.gradient)
                        .cornerRadius(5)
                }
                .frame(height: 180)
                .accessibilityLabel("Weekly solves bar chart")
            }
        }
    }

    private struct WeekBin: Identifiable {
        let id = UUID()
        let label: String
        let count: Int
    }

    private func weeklySolves(_ points: [DayPoint]) -> [WeekBin] {
        let cal = Calendar(identifier: .gregorian)
        var buckets: [Date: Int] = [:]
        for p in points where p.solved {
            let week = cal.dateInterval(of: .weekOfYear, for: p.date)?.start ?? p.date
            buckets[week, default: 0] += 1
        }
        let f = DateFormatter(); f.dateFormat = "M/d"
        return buckets.keys.sorted().suffix(8).map { wk in
            WeekBin(label: f.string(from: wk), count: buckets[wk] ?? 0)
        }
    }

    // MARK: Difficulty averages

    private func difficultyChart(_ r: StatsResult) -> some View {
        chartCard(title: "Average time by difficulty", symbol: "dial.medium") {
            if r.difficultyAverages.isEmpty {
                notEnough("Solve puzzles across difficulties to compare your pace.")
            } else {
                Chart(r.difficultyAverages) { item in
                    BarMark(x: .value("Seconds", item.averageSeconds),
                            y: .value("Difficulty", item.difficulty.title))
                        .foregroundStyle(barColor(item.difficulty))
                        .cornerRadius(5)
                        .annotation(position: .trailing) {
                            Text(TimeFormat.clock(item.averageSeconds))
                                .font(Theme.mono(11, .semibold))
                                .foregroundStyle(Theme.inkSoft)
                        }
                }
                .chartXAxis(.hidden)
                .frame(height: CGFloat(r.difficultyAverages.count) * 44 + 12)
                .accessibilityLabel("Average solve time by difficulty")
            }
        }
    }

    private func barColor(_ d: Difficulty) -> Color {
        switch d {
        case .easy: return Theme.good
        case .medium: return Theme.accent
        case .hard: return Color.dyn(0x7A4FB0, 0xB58CE6)
        }
    }

    // MARK: Completion

    private func completionCard(_ r: StatsResult) -> some View {
        chartCard(title: "Completion rate", symbol: "percent") {
            VStack(spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(Int((r.completionRate * 100).rounded()))%")
                        .font(Theme.rounded(34, .bold))
                        .foregroundStyle(Theme.ink)
                        .monospacedDigit()
                    Text("of puzzles started were solved")
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.inkSoft)
                    Spacer()
                }
                ProgressView(value: min(max(r.completionRate, 0), 1))
                    .tint(Theme.accent)
                if let best = r.bestSeconds {
                    Label("Fastest solve: \(TimeFormat.clock(best))", systemImage: "bolt.fill")
                        .font(Theme.rounded(13, .medium))
                        .foregroundStyle(Theme.good)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .accessibilityElement(children: .combine)
        }
    }

    // MARK: Building blocks

    private func notEnough(_ text: String) -> some View {
        Text(text)
            .font(Theme.rounded(14))
            .foregroundStyle(Theme.inkSoft)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func chartCard<Content: View>(title: String, symbol: String, @ViewBuilder content: () -> Content) -> some View {
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

    // MARK: Async compute

    @MainActor
    private func recompute() async {
        isLoading = true
        let dailySnaps = allResults.map {
            StatsEngine.DailySnapshot(dateKey: $0.dateKey,
                                      solved: $0.solved,
                                      elapsedSeconds: $0.elapsedSeconds,
                                      difficulty: $0.difficulty)
        }
        let progressSnaps = allProgress.map {
            StatsEngine.ProgressSnapshot(puzzleID: $0.puzzleID,
                                         completed: $0.completed,
                                         elapsedSeconds: $0.elapsedSeconds,
                                         solvedAt: $0.solvedAt)
        }
        try? await Task.sleep(nanoseconds: 300_000_000)
        let computed = StatsEngine.compute(daily: dailySnaps, progress: progressSnaps) { id in
            PuzzleBank.puzzle(id: id)?.difficulty ?? .medium
        }
        result = computed
        isLoading = false
    }
}
