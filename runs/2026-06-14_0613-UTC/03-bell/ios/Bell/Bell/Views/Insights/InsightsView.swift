import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \MeditationSession.date, order: .reverse) private var sessions: [MeditationSession]

    @State private var computed: Computed?
    @State private var isLoading = true

    /// Snapshot of all derived series — computed off the main render path.
    private struct Computed {
        var perDay: [Stats.DayMinutes]
        var byTime: [Stats.TimeBucket]
        var moods: [Stats.MoodSlice]
        var heat: [Stats.HeatCell]
        var totalSessions: Int
        var totalMinutes: Int
        var avgMinutes: Int
        var longestStreak: Int
        var currentStreak: Int
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    loadingState
                } else if sessions.isEmpty {
                    EmptyStateView(
                        symbol: "chart.bar.xaxis",
                        title: "No insights yet",
                        message: "Sit a few times and your minutes, streaks, and moods will bloom here."
                    )
                } else if let c = computed {
                    content(c)
                } else {
                    loadingState
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Insights")
        }
        .task(id: sessions.count) { await recompute() }
    }

    // MARK: - Loading
    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
                .tint(Theme.accent)
            Text("Gathering your sits…")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @MainActor
    private func recompute() async {
        isLoading = true
        // Extract a Sendable snapshot (plain values) from the SwiftData models on
        // the main actor, then crunch it off the main thread so the loading state
        // is visible and the UI stays smooth.
        let snapshot: [Stats.SessionSnapshot] = sessions.map {
            Stats.SessionSnapshot(date: $0.date, durationSec: $0.durationSec, mood: $0.mood)
        }
        let result = await Task.detached(priority: .userInitiated) { () -> Computed in
            Computed(
                perDay: Stats.minutesPerDay(snapshot, days: 30),
                byTime: Stats.byTimeOfDay(snapshot),
                moods: Stats.moodDistribution(snapshot),
                heat: Stats.heatmap(snapshot, days: 35),
                totalSessions: snapshot.count,
                totalMinutes: Stats.totalMinutes(snapshot),
                avgMinutes: Stats.averageMinutes(snapshot),
                longestStreak: Stats.longestStreak(snapshot),
                currentStreak: Stats.currentStreak(snapshot)
            )
        }.value
        computed = result
        isLoading = false
    }

    // MARK: - Content
    private func content(_ c: Computed) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                totals(c)
                minutesChart(c)
                timeOfDayChart(c)
                moodChart(c)
                heatmap(c)
                if !isPro { proTeaser }
            }
            .padding(Theme.spacing)
        }
    }

    private func totals(_ c: Computed) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatTile(value: "\(c.totalSessions)", label: "sessions", symbol: "circle.hexagongrid")
                StatTile(value: "\(c.totalMinutes)", label: "total min", symbol: "hourglass")
            }
            HStack(spacing: 12) {
                StatTile(value: "\(c.avgMinutes)", label: "avg min", symbol: "chart.line.uptrend.xyaxis", tint: Theme.accentDeep)
                StatTile(value: "\(c.longestStreak)", label: "best streak", symbol: "flame", tint: Theme.warning)
            }
        }
    }

    // MARK: - Minutes per day (last 30)
    private func minutesChart(_ c: Computed) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Minutes per day", subtitle: "Last 30 days")
                Chart(c.perDay) { day in
                    BarMark(
                        x: .value("Day", day.date, unit: .day),
                        y: .value("Minutes", day.minutes)
                    )
                    .foregroundStyle(Theme.accent.gradient)
                    .cornerRadius(3)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .frame(height: 170)
                .accessibilityLabel("Minutes meditated per day over the last 30 days")
                .accessibilityValue(minutesAccessibility(c.perDay))
            }
        }
    }

    private func minutesAccessibility(_ days: [Stats.DayMinutes]) -> String {
        let total = days.reduce(0) { $0 + $1.minutes }
        let active = days.filter { $0.minutes > 0 }.count
        return "\(total) minutes across \(active) active days"
    }

    // MARK: - Time of day
    private func timeOfDayChart(_ c: Computed) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "When you sit", subtitle: "Sessions by time of day")
                Chart(c.byTime) { b in
                    BarMark(
                        x: .value("Sessions", b.count),
                        y: .value("Time", b.bucket.displayName)
                    )
                    .foregroundStyle(Theme.accentSoft.gradient)
                    .cornerRadius(4)
                    .annotation(position: .trailing) {
                        if b.count > 0 {
                            Text("\(b.count)").font(Theme.rounded(11)).foregroundStyle(Theme.textSecondary)
                        }
                    }
                }
                .frame(height: 150)
                .accessibilityLabel("Sessions by time of day")
                .accessibilityValue(c.byTime.map { "\($0.bucket.displayName) \($0.count)" }.joined(separator: ", "))
            }
        }
    }

    // MARK: - Mood
    private func moodChart(_ c: Computed) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Mood after sitting")
                if c.moods.isEmpty {
                    Text("Reflect after a sit to chart your moods.")
                        .font(Theme.rounded(14)).foregroundStyle(Theme.textSecondary)
                } else {
                    Chart(c.moods) { slice in
                        SectorMark(
                            angle: .value("Count", slice.count),
                            innerRadius: .ratio(0.58),
                            angularInset: 1.5
                        )
                        .foregroundStyle(slice.mood.color)
                        .cornerRadius(3)
                    }
                    .frame(height: 170)
                    .accessibilityLabel("Mood distribution")
                    .accessibilityValue(c.moods.map { "\($0.mood.displayName) \($0.count)" }.joined(separator: ", "))

                    moodLegend(c.moods)
                }
            }
        }
    }

    private func moodLegend(_ moods: [Stats.MoodSlice]) -> some View {
        FlowLegend(items: moods.map { ($0.mood.color, "\($0.mood.emoji) \($0.mood.displayName) · \($0.count)") })
    }

    // MARK: - Heatmap
    private func heatmap(_ c: Computed) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Last 5 weeks", subtitle: "Streak heatmap")
                let columns = Array(repeating: GridItem(.flexible(), spacing: 5), count: 7)
                LazyVGrid(columns: columns, spacing: 5) {
                    ForEach(c.heat) { cell in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(heatColor(cell.minutes))
                            .aspectRatio(1, contentMode: .fit)
                            .accessibilityLabel(cell.date.formatted(date: .abbreviated, time: .omitted))
                            .accessibilityValue(cell.minutes == 0 ? "no sit" : "\(cell.minutes) minutes")
                    }
                }
                HStack(spacing: 6) {
                    Text("Less").font(Theme.rounded(11)).foregroundStyle(Theme.textTertiary)
                    ForEach([0, 5, 15, 30, 45], id: \.self) { m in
                        RoundedRectangle(cornerRadius: 3).fill(heatColor(m)).frame(width: 14, height: 14)
                    }
                    Text("More").font(Theme.rounded(11)).foregroundStyle(Theme.textTertiary)
                }
                .accessibilityHidden(true)
            }
        }
    }

    private func heatColor(_ minutes: Int) -> Color {
        switch minutes {
        case 0: return Theme.separator
        case 1..<10: return Theme.accent.opacity(0.30)
        case 10..<20: return Theme.accent.opacity(0.55)
        case 20..<35: return Theme.accent.opacity(0.78)
        default: return Theme.accent
        }
    }

    private var proTeaser: some View {
        NavigationLink {
            PaywallView(reason: .general)
        } label: {
            HStack {
                Image(systemName: "sparkles")
                VStack(alignment: .leading, spacing: 2) {
                    Text("Bell Pro").font(Theme.rounded(15, .semibold))
                    Text("Unlock all bells, soundscapes & unlimited presets")
                        .font(Theme.rounded(12)).foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(Theme.textTertiary)
            }
            .foregroundStyle(Theme.textPrimary)
            .padding(Theme.spacing)
            .background(Theme.accent.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
        }
    }
}

// MARK: - Simple wrapping legend
struct FlowLegend: View {
    let items: [(Color, String)]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(spacing: 8) {
                    Circle().fill(item.0).frame(width: 10, height: 10)
                    Text(item.1).font(Theme.rounded(13)).foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityHidden(true)
    }
}
