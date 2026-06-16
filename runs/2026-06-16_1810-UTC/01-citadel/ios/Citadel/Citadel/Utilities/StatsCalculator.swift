import Foundation

/// A point used in the weekly games chart.
struct WeeklyBucket: Identifiable {
    let id = UUID()
    let weekStart: Date
    let played: Int
    let won: Int
}

/// Aggregated, derived statistics computed from a list of `GameResult`s.
/// Pure value computation — no side effects, safe against empty input.
struct StatsSummary {
    let gamesPlayed: Int
    let wins: Int
    let losses: Int
    let winRate: Double          // 0...1
    let currentStreak: Int
    let bestStreak: Int
    let fastestWinSeconds: Int?  // nil if no wins
    let averageMoves: Double?    // nil if no games
    let dealsWon: Int

    static let empty = StatsSummary(
        gamesPlayed: 0, wins: 0, losses: 0, winRate: 0,
        currentStreak: 0, bestStreak: 0, fastestWinSeconds: nil,
        averageMoves: nil, dealsWon: 0
    )

    /// Compute a summary from results (any order; we sort by date internally).
    static func compute(from results: [GameResult]) -> StatsSummary {
        guard !results.isEmpty else { return .empty }

        let sorted = results.sorted { $0.date < $1.date }
        let wins = sorted.filter { $0.won }.count
        let losses = sorted.count - wins
        let rate = sorted.isEmpty ? 0 : Double(wins) / Double(sorted.count)

        // Streaks: count consecutive wins. "Current" = trailing run of wins.
        var best = 0
        var run = 0
        for r in sorted {
            if r.won {
                run += 1
                best = max(best, run)
            } else {
                run = 0
            }
        }
        // Current streak = trailing run of wins from the end.
        var current = 0
        for r in sorted.reversed() {
            if r.won { current += 1 } else { break }
        }

        let fastest = sorted.filter { $0.won }.map { $0.durationSeconds }.min()
        let avgMoves = sorted.isEmpty ? nil : Double(sorted.reduce(0) { $0 + $1.moves }) / Double(sorted.count)
        let dealsWon = Set(sorted.filter { $0.won }.map { $0.dealNumber }).count

        return StatsSummary(
            gamesPlayed: sorted.count,
            wins: wins,
            losses: losses,
            winRate: rate,
            currentStreak: current,
            bestStreak: best,
            fastestWinSeconds: fastest,
            averageMoves: avgMoves,
            dealsWon: dealsWon
        )
    }

    /// Bucket results into the last `weeks` calendar weeks for charting.
    static func weeklyBuckets(from results: [GameResult],
                              weeks: Int = 8,
                              calendar: Calendar = .current,
                              now: Date = .now) -> [WeeklyBucket] {
        guard weeks > 0 else { return [] }
        // Determine the start of the current week.
        let startOfThisWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now

        var buckets: [WeeklyBucket] = []
        for offset in stride(from: weeks - 1, through: 0, by: -1) {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -offset, to: startOfThisWeek),
                  let weekEnd = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart) else {
                continue
            }
            let inWeek = results.filter { $0.date >= weekStart && $0.date < weekEnd }
            buckets.append(WeeklyBucket(
                weekStart: weekStart,
                played: inWeek.count,
                won: inWeek.filter { $0.won }.count
            ))
        }
        return buckets
    }
}

/// Format seconds as M:SS for display.
func formatDuration(_ seconds: Int) -> String {
    let s = max(0, seconds)
    let m = s / 60
    let r = s % 60
    return String(format: "%d:%02d", m, r)
}
