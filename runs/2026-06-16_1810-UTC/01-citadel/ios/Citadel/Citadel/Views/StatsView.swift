import SwiftUI
import SwiftData
import Charts

/// Stats screen: headline numbers, streaks, and a weekly games chart.
struct StatsView: View {
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("isPro") private var isPro = false

    @Query(sort: \GameResult.date, order: .forward) private var results: [GameResult]

    private var summary: StatsSummary { StatsSummary.compute(from: results) }
    private var buckets: [WeeklyBucket] { StatsSummary.weeklyBuckets(from: results, weeks: 8) }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.feltGradient(for: colorScheme).ignoresSafeArea()
                content
            }
            .navigationTitle("Stats")
        }
    }

    @ViewBuilder
    private var content: some View {
        if results.isEmpty {
            emptyState
        } else {
            ScrollView {
                VStack(spacing: 18) {
                    headlineGrid
                    streakCard
                    chartCard
                    if !isPro {
                        proHint
                    }
                }
                .padding(16)
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No games yet", systemImage: "chart.bar.xaxis")
        } description: {
            Text("Play a few hands and your stats will appear here — wins, streaks, and your fastest solves.")
        }
        .foregroundStyle(Theme.feltText(for: colorScheme))
    }

    // MARK: - Headline grid

    private var headlineGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statCard(title: "Played", value: "\(summary.gamesPlayed)", symbol: "rectangle.stack")
            statCard(title: "Win rate",
                     value: "\(Int((summary.winRate * 100).rounded()))%",
                     symbol: "percent")
            statCard(title: "Wins", value: "\(summary.wins)", symbol: "trophy")
            statCard(title: "Deals won", value: "\(summary.dealsWon)", symbol: "checkmark.seal")
            statCard(title: "Best time",
                     value: summary.fastestWinSeconds.map { formatDuration($0) } ?? "—",
                     symbol: "stopwatch")
            statCard(title: "Avg moves",
                     value: summary.averageMoves.map { String(Int($0.rounded())) } ?? "—",
                     symbol: "arrow.left.arrow.right")
        }
    }

    @ViewBuilder
    private func statCard(title: String, value: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.caption)
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(value)
    }

    // MARK: - Streaks

    private var streakCard: some View {
        HStack(spacing: 0) {
            streakColumn(title: "Current streak", value: summary.currentStreak, highlight: summary.currentStreak >= 3)
            Divider().frame(height: 44)
            streakColumn(title: "Best streak", value: summary.bestStreak, highlight: summary.bestStreak >= 5)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    @ViewBuilder
    private func streakColumn(title: String, value: Int, highlight: Bool) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                if highlight {
                    Image(systemName: "flame.fill")
                        .font(.subheadline)
                        .foregroundStyle(Theme.gold)
                        .accessibilityHidden(true)
                }
                Text("\(value)")
                    .font(.system(.title, design: .rounded).weight(.bold))
                    .foregroundStyle(highlight ? Theme.gold : .primary)
            }
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue("\(value)")
    }

    // MARK: - Chart

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Last 8 weeks")
                .font(.headline)
            Text("Games played and won each week")
                .font(.caption)
                .foregroundStyle(.secondary)

            Chart(buckets) { bucket in
                BarMark(
                    x: .value("Week", bucket.weekStart, unit: .weekOfYear),
                    y: .value("Games", bucket.played)
                )
                .foregroundStyle(by: .value("Result", "Played"))
                .position(by: .value("Result", "Played"))

                BarMark(
                    x: .value("Week", bucket.weekStart, unit: .weekOfYear),
                    y: .value("Games", bucket.won)
                )
                .foregroundStyle(by: .value("Result", "Won"))
                .position(by: .value("Result", "Won"))
            }
            .chartForegroundStyleScale([
                "Played": Theme.accent.opacity(0.35),
                "Won": Theme.gold
            ])
            .chartXAxis {
                AxisMarks(values: .stride(by: .weekOfYear)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.week(.weekOfMonth), centered: true)
                }
            }
            .frame(height: 180)
            .accessibilityLabel("Bar chart of games played and won over the last eight weeks")
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var proHint: some View {
        HStack(spacing: 10) {
            Image(systemName: "crown.fill")
                .foregroundStyle(Theme.gold)
                .accessibilityHidden(true)
            Text("Showing your latest games. Citadel Pro keeps your full history.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Theme.gold.opacity(0.12))
        )
    }
}
