import SwiftUI
import SwiftData
import Charts

/// Player statistics: totals, win rate, best/average times by size, streaks,
/// and a per-difficulty chart. Shows a friendly empty state until there's data.
struct StatsView: View {
    @Query(sort: \PuzzleResult.date, order: .reverse) private var results: [PuzzleResult]

    private var summary: StatsSummary { StatsCalculator.summarize(results) }

    var body: some View {
        NavigationStack {
            Group {
                if summary.isEmpty {
                    EmptyStateView(
                        systemImage: "chart.bar",
                        title: "No stats yet",
                        message: "Solve a few puzzles and your times, win rate, and streaks will show up here."
                    )
                } else {
                    content
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 18) {
                overviewGrid
                winRateChartCard
                bestTimesCard
            }
            .padding(20)
        }
    }

    private var overviewGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 14), count: 2)
        return LazyVGrid(columns: columns, spacing: 14) {
            metricTile(value: "\(summary.totalSolved)", label: "Solved", icon: "checkmark.seal.fill")
            metricTile(value: percent(summary.winRate), label: "Win rate", icon: "percent")
            metricTile(value: "\(summary.currentStreak)", label: "Current streak", icon: "flame.fill")
            metricTile(value: "\(summary.bestStreak)", label: "Best streak", icon: "trophy.fill")
        }
    }

    private func metricTile(value: String, label: String, icon: String) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                Text(value)
                    .font(.title.weight(.bold))
                    .foregroundStyle(Theme.textPrimary)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private var winRateChartCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("By difficulty")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)

                let data = Difficulty.allCases.compactMap { diff -> DiffStat? in
                    let played = summary.playedByDifficulty[diff] ?? 0
                    guard played > 0 else { return nil }
                    return DiffStat(
                        difficulty: diff,
                        played: played,
                        won: summary.winsByDifficulty[diff] ?? 0
                    )
                }

                if data.isEmpty {
                    Text("Play a few puzzles to see this chart.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                } else {
                    Chart(data) { stat in
                        BarMark(
                            x: .value("Difficulty", stat.difficulty.displayName),
                            y: .value("Solved", stat.won)
                        )
                        .foregroundStyle(Theme.accent)
                        .cornerRadius(6)
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .frame(height: 180)
                    .accessibilityLabel("Bar chart of puzzles solved by difficulty")

                    VStack(spacing: 6) {
                        ForEach(data) { stat in
                            HStack {
                                Text(stat.difficulty.displayName)
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.textPrimary)
                                Spacer()
                                Text("\(stat.won)/\(stat.played) · \(percent(stat.winRate))")
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(stat.difficulty.displayName): \(stat.won) of \(stat.played) won, \(percent(stat.winRate))")
                        }
                    }
                }
            }
        }
    }

    private var bestTimesCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Best & average times")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)

                let sizes = summary.bestTimeBySize.keys.sorted()
                if sizes.isEmpty {
                    Text("Win a puzzle to record your time.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                } else {
                    ForEach(sizes, id: \.self) { size in
                        HStack {
                            Text("\(size)×\(size)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 1) {
                                Text("Best \(format(summary.bestTimeBySize[size]))")
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.accent)
                                Text("Avg \(format(summary.averageTimeBySize[size]))")
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(size) by \(size): best \(format(summary.bestTimeBySize[size])), average \(format(summary.averageTimeBySize[size]))")
                    }
                }
            }
        }
    }

    // MARK: Helpers

    private struct DiffStat: Identifiable {
        let difficulty: Difficulty
        let played: Int
        let won: Int
        var id: String { difficulty.rawValue }
        var winRate: Double { played > 0 ? Double(won) / Double(played) : 0 }
    }

    private func percent(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }

    private func format(_ seconds: Int?) -> String {
        guard let seconds, seconds > 0 else { return "—" }
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
