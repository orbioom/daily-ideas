import SwiftUI
import SwiftData
import Charts

/// Insights screen built on Swift Charts: solves over time, average time by difficulty,
/// totals, streaks, and fastest solves.
struct StatsView: View {
    @Query(sort: \PuzzleProgress.completedDate) private var progress: [PuzzleProgress]
    @Query private var dailies: [DailyResult]

    private var completed: [PuzzleProgress] {
        progress.filter { $0.isComplete }
    }

    var body: some View {
        NavigationStack {
            Group {
                if completed.isEmpty {
                    EmptyStateView(
                        icon: "chart.bar.xaxis",
                        title: "No solves yet",
                        message: "Finish a puzzle and your stats will appear here — solve times, streaks, and more."
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            summaryGrid
                            solvesOverTimeCard
                            averageTimeCard
                            fastestSolvesCard
                        }
                        .padding(16)
                    }
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Stats")
        }
    }

    // MARK: Summary

    private var summaryGrid: some View {
        let totalSolved = completed.count
        let totalWords = completed.reduce(0) { $0 + $1.foundWords.count }
        let currentStreak = StreakCalculator.current(from: dailies)
        let longestStreak = StreakCalculator.longest(from: dailies)

        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statTile(value: "\(totalSolved)", label: "Puzzles solved", icon: "checkmark.seal.fill", tint: Theme.good)
            statTile(value: "\(totalWords)", label: "Words found", icon: "text.magnifyingglass", tint: Theme.accent)
            statTile(value: "\(currentStreak)", label: "Current streak", icon: "flame.fill", tint: Theme.warn)
            statTile(value: "\(longestStreak)", label: "Longest streak", icon: "trophy.fill", tint: Theme.accentDeep)
        }
    }

    private func statTile(value: String, label: String, icon: String, tint: Color) -> some View {
        SeekCard(padding: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(tint)
                Text(value)
                    .font(Theme.rounded(26, .bold))
                    .foregroundStyle(Theme.ink)
                Text(label)
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    // MARK: Solves over time

    private var solvesPerDay: [DayCount] {
        let cal = Calendar.current
        var buckets: [Date: Int] = [:]
        for p in completed {
            guard let date = p.completedDate else { continue }
            let day = cal.startOfDay(for: date)
            buckets[day, default: 0] += 1
        }
        return buckets
            .map { DayCount(day: $0.key, count: $0.value) }
            .sorted { $0.day < $1.day }
    }

    private var solvesOverTimeCard: some View {
        SeekCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Puzzles solved over time")
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                Chart(solvesPerDay) { item in
                    BarMark(
                        x: .value("Day", item.day, unit: .day),
                        y: .value("Solved", item.count)
                    )
                    .foregroundStyle(Theme.accent)
                    .cornerRadius(4)
                    .accessibilityLabel(Formatters.mediumDate(item.day))
                    .accessibilityValue("\(item.count) solved")
                }
                .frame(height: 180)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            }
        }
    }

    // MARK: Average time by difficulty

    private var averageByDifficulty: [DifficultyAvg] {
        var result: [DifficultyAvg] = []
        for diff in Difficulty.allCases {
            let items = completed.filter { $0.difficultyRaw == diff.rawValue && $0.elapsedSec > 0 }
            guard !items.isEmpty else { continue }
            let total = items.reduce(0) { $0 + $1.elapsedSec }
            let avg = total / items.count
            result.append(DifficultyAvg(difficulty: diff, averageSec: avg))
        }
        return result
    }

    private var averageTimeCard: some View {
        SeekCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Average solve time by difficulty")
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                if averageByDifficulty.isEmpty {
                    Text("Solve a few puzzles to see your pace by difficulty.")
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.inkSoft)
                } else {
                    Chart(averageByDifficulty) { item in
                        BarMark(
                            x: .value("Difficulty", item.difficulty.rawValue),
                            y: .value("Seconds", item.averageSec)
                        )
                        .foregroundStyle(by: .value("Difficulty", item.difficulty.rawValue))
                        .cornerRadius(4)
                        .accessibilityLabel(item.difficulty.rawValue)
                        .accessibilityValue(Formatters.clock(item.averageSec))
                    }
                    .chartForegroundStyleScale([
                        Difficulty.easy.rawValue: Theme.good,
                        Difficulty.medium.rawValue: Theme.warn,
                        Difficulty.hard.rawValue: Theme.bad
                    ])
                    .frame(height: 180)
                }
            }
        }
    }

    // MARK: Fastest solves

    private var fastestSolves: [PuzzleProgress] {
        completed
            .filter { ($0.bestTimeSec ?? $0.elapsedSec) > 0 }
            .sorted { ($0.bestTimeSec ?? $0.elapsedSec) < ($1.bestTimeSec ?? $1.elapsedSec) }
            .prefix(5)
            .map { $0 }
    }

    private var fastestSolvesCard: some View {
        SeekCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Fastest solves")
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                ForEach(Array(fastestSolves.enumerated()), id: \.element.puzzleKey) { index, item in
                    HStack {
                        Text("\(index + 1)")
                            .font(Theme.rounded(14, .bold))
                            .foregroundStyle(Theme.inkSoft)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.packName)
                                .font(Theme.rounded(15, .semibold))
                                .foregroundStyle(Theme.ink)
                            Text(item.difficultyRaw)
                                .font(Theme.rounded(12))
                                .foregroundStyle(Theme.inkSoft)
                        }
                        Spacer()
                        Text(Formatters.clock(item.bestTimeSec ?? item.elapsedSec))
                            .font(Theme.rounded(15, .semibold))
                            .foregroundStyle(Theme.accent)
                            .monospacedDigit()
                    }
                    .accessibilityElement(children: .combine)
                    if index < fastestSolves.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }
}

private struct DayCount: Identifiable {
    let day: Date
    let count: Int
    var id: Date { day }
}

private struct DifficultyAvg: Identifiable {
    let difficulty: Difficulty
    let averageSec: Int
    var id: String { difficulty.rawValue }
}
