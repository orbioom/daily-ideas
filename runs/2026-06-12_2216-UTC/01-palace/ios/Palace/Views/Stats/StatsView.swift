import SwiftUI
import SwiftData
import Charts

private struct OutcomePoint: Identifiable {
    let id = UUID()
    let day: Date
    let outcome: String
    let count: Int
}

struct StatsView: View {
    @Query(sort: \GameRecord.date) private var records: [GameRecord]

    private var wins: [GameRecord] { records.filter(\.won) }

    private var winRate: Double {
        records.isEmpty ? 0 : Double(wins.count) / Double(records.count)
    }

    private var bestTime: Int? { wins.map(\.durationSeconds).min() }
    private var bestScore: Int? { wins.map(\.score).max() }
    private var fewestMoves: Int? { wins.map(\.moves).min() }

    private var currentStreak: Int {
        var streak = 0
        for record in records.reversed() {
            if record.won { streak += 1 } else { break }
        }
        return streak
    }

    private var longestStreak: Int {
        var best = 0, run = 0
        for record in records {
            run = record.won ? run + 1 : 0
            best = max(best, run)
        }
        return best
    }

    /// Wins/losses per day over the last 14 days, for the outcomes chart.
    private var outcomePoints: [OutcomePoint] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: cal.date(byAdding: .day, value: -13, to: .now) ?? .now)
        var byDay: [Date: (won: Int, lost: Int)] = [:]
        for record in records where record.date >= start {
            let day = cal.startOfDay(for: record.date)
            var entry = byDay[day] ?? (0, 0)
            if record.won { entry.won += 1 } else { entry.lost += 1 }
            byDay[day] = entry
        }
        var points: [OutcomePoint] = []
        for (day, entry) in byDay.sorted(by: { $0.key < $1.key }) {
            if entry.won > 0 { points.append(OutcomePoint(day: day, outcome: "Won", count: entry.won)) }
            if entry.lost > 0 { points.append(OutcomePoint(day: day, outcome: "Lost", count: entry.lost)) }
        }
        return points
    }

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    ContentUnavailableView(
                        "No Statistics Yet",
                        systemImage: "chart.bar",
                        description: Text("Play a few games and your win rate, streaks, and bests will build up here.")
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                StatTile(title: "Games", value: "\(records.count)")
                                StatTile(title: "Win Rate", value: winRate.formatted(.percent.precision(.fractionLength(0))))
                                StatTile(title: "Current Streak", value: "\(currentStreak)", caption: "wins in a row")
                                StatTile(title: "Longest Streak", value: "\(longestStreak)", caption: "wins in a row")
                            }
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                StatTile(title: "Best Time", value: bestTime.map(Format.duration) ?? "—")
                                StatTile(title: "Best Score", value: bestScore.map(String.init) ?? "—")
                                StatTile(title: "Fewest Moves", value: fewestMoves.map(String.init) ?? "—")
                            }

                            VStack(alignment: .leading, spacing: 10) {
                                Text("Last 14 Days")
                                    .font(.headline)
                                if outcomePoints.isEmpty {
                                    Text("No games in the last two weeks.")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .padding(.vertical, 24)
                                } else {
                                    Chart(outcomePoints) { point in
                                        BarMark(
                                            x: .value("Day", point.day, unit: .day),
                                            y: .value("Games", point.count)
                                        )
                                        .foregroundStyle(by: .value("Outcome", point.outcome))
                                        .cornerRadius(3)
                                    }
                                    .chartForegroundStyleScale([
                                        "Won": PalaceTheme.gold,
                                        "Lost": Color(.systemGray3),
                                    ])
                                    .frame(height: 180)
                                    .accessibilityLabel("Bar chart of wins and losses per day for the last 14 days")
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .palacePanel()
                        }
                        .padding()
                    }
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle("Statistics")
        }
    }
}
