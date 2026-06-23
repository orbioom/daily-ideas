import SwiftUI
import SwiftData
import Charts

/// Insights tab: streaks, totals, sessions-per-day bar chart, mood-trend line, and
/// technique breakdown. Computation runs on a background task with a loading state.
struct InsightsView: View {
    @Query private var sessions: [BreathSession]
    @Query private var moods: [MoodEntry]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var range: Range = .twoWeeks
    @State private var computed: ComputedInsights?
    @State private var isLoading = true

    enum Range: Int, CaseIterable, Identifiable {
        case week = 7, twoWeeks = 14, month = 30
        var id: Int { rawValue }
        var label: String {
            switch self {
            case .week: return "7 days"
            case .twoWeeks: return "14 days"
            case .month: return "30 days"
            }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty && moods.isEmpty {
                    emptyState
                } else if isLoading || computed == nil {
                    LoadingView(message: "Crunching your numbers…")
                } else if let computed {
                    content(computed)
                }
            }
            .emberScreenBackground()
            .navigationTitle("Insights")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Range", selection: $range) {
                            ForEach(Range.allCases) { Text($0.label).tag($0) }
                        }
                    } label: {
                        Label(range.label, systemImage: "calendar")
                    }
                }
            }
            .task(id: rangeKey) { await recompute() }
        }
    }

    /// Recompute when data or range changes.
    private var rangeKey: String {
        "\(range.rawValue)-\(sessions.count)-\(moods.count)"
    }

    @MainActor
    private func recompute() async {
        isLoading = true
        // Briefly yield so the loading state is shown and the UI stays responsive
        // while we build the metrics. StatsEngine reads @Model objects, so it runs
        // on the main actor where those objects are safe to touch.
        try? await Task.sleep(nanoseconds: 250_000_000)
        if Task.isCancelled { return }
        let days = range.rawValue
        let engine = StatsEngine(sessions: sessions, moods: moods)
        computed = ComputedInsights(
            currentStreak: engine.currentStreak,
            longestStreak: engine.longestStreak,
            totalSessions: engine.totalSessions,
            totalMinutes: engine.totalMinutes,
            avgMinutes: engine.averageSessionMinutes,
            moodLift: engine.averageMoodLift,
            daily: engine.dailyCounts(days: days),
            mood: engine.moodTrend(days: days),
            styles: engine.styleBreakdown)
        isLoading = false
    }

    private var emptyState: some View {
        ScrollView {
            EmptyStateView(icon: "chart.bar.xaxis",
                           title: "No insights yet",
                           message: "Complete a few breathing sessions and log your mood to unlock charts and streak tracking.")
                .padding()
        }
    }

    private func content(_ data: ComputedInsights) -> some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                summaryGrid(data)
                sessionsChart(data)
                moodChart(data)
                styleChart(data)
            }
            .padding(Theme.Spacing.md)
        }
    }

    private func summaryGrid(_ data: ComputedInsights) -> some View {
        VStack(spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.md) {
                StatPill(value: "\(data.currentStreak)", label: "Current Streak",
                         systemImage: "flame.fill", tint: Theme.emberWarm)
                StatPill(value: "\(data.longestStreak)", label: "Best Streak",
                         systemImage: "trophy.fill", tint: Theme.warn)
            }
            HStack(spacing: Theme.Spacing.md) {
                StatPill(value: "\(data.totalSessions)", label: "Sessions",
                         systemImage: "wind", tint: Theme.calmTeal)
                StatPill(value: "\(Int(data.totalMinutes.rounded()))", label: "Total Min",
                         systemImage: "hourglass", tint: Theme.deepBlue)
                StatPill(value: data.moodLift.map { String(format: "%+.1f", $0) } ?? "—",
                         label: "Avg Mood Lift", systemImage: "arrow.up.heart", tint: Theme.good)
            }
        }
    }

    private func sessionsChart(_ data: ComputedInsights) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader(title: "Sessions per day", subtitle: range.label)
            if data.daily.allSatisfy({ $0.count == 0 }) {
                Text("No sessions in this range yet.")
                    .font(.subheadline).foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                Chart(data.daily) { item in
                    BarMark(
                        x: .value("Day", item.date, unit: .day),
                        y: .value("Sessions", item.count)
                    )
                    .foregroundStyle(Theme.calmTeal.gradient)
                    .cornerRadius(4)
                }
                .chartYAxis { AxisMarks(position: .leading) }
                .chartXAxis { AxisMarks(values: .stride(by: .day, count: max(1, range.rawValue / 7))) }
                .frame(height: 180)
                .accessibilityLabel("Bar chart of sessions per day over the last \(range.label)")
            }
        }
        .emberCard()
    }

    private func moodChart(_ data: ComputedInsights) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader(title: "Mood trend", subtitle: "Daily average, 1–5")
            let points = data.mood.filter { $0.average > 0 }
            if points.isEmpty {
                Text("Log your mood to see a trend.")
                    .font(.subheadline).foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                Chart(points) { point in
                    LineMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Mood", point.average)
                    )
                    .foregroundStyle(Theme.emberWarm)
                    .interpolationMethod(.catmullRom)
                    PointMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Mood", point.average)
                    )
                    .foregroundStyle(Theme.emberWarm)
                }
                .chartYScale(domain: 1...5)
                .frame(height: 180)
                .accessibilityLabel("Line chart of average daily mood over the last \(range.label)")
            }
        }
        .emberCard()
    }

    private func styleChart(_ data: ComputedInsights) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader(title: "Favorite techniques", subtitle: "By sessions completed")
            if data.styles.isEmpty {
                Text("No technique data yet.")
                    .font(.subheadline).foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: 80)
            } else {
                Chart(data.styles) { slice in
                    BarMark(
                        x: .value("Sessions", slice.count),
                        y: .value("Technique", slice.style.displayName)
                    )
                    .foregroundStyle(slice.style.accent)
                    .cornerRadius(4)
                    .annotation(position: .trailing) {
                        Text("\(slice.count)")
                            .font(.caption2).foregroundStyle(Theme.textSecondary)
                    }
                }
                .frame(height: CGFloat(data.styles.count) * 44 + 20)
                .accessibilityLabel("Bar chart of sessions by technique")
            }
        }
        .emberCard()
    }
}

/// Snapshot of computed metrics produced off the main actor.
struct ComputedInsights {
    let currentStreak: Int
    let longestStreak: Int
    let totalSessions: Int
    let totalMinutes: Double
    let avgMinutes: Double
    let moodLift: Double?
    let daily: [DayCount]
    let mood: [MoodPoint]
    let styles: [StyleSlice]
}

#Preview {
    InsightsView()
        .previewModelContainer()
}
