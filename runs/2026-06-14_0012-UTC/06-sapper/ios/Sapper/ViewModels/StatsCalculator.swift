import Foundation

/// Aggregated stats for one difficulty.
struct DifficultyStats: Identifiable {
    let difficulty: Difficulty
    var played: Int
    var won: Int
    var bestTime: Double?    // among wins
    var avgTime: Double?     // among wins

    var id: String { difficulty.rawValue }
    var winRate: Double { played > 0 ? Double(won) / Double(played) : 0 }
}

/// Pure aggregation over `GameRecord`s. Kept free of SwiftUI/SwiftData so it is
/// trivially testable and reusable by Home + Stats.
enum StatsCalculator {

    /// Per-difficulty stats for the standard difficulties (excludes daily games).
    static func byDifficulty(_ records: [GameRecord]) -> [DifficultyStats] {
        let order: [Difficulty] = [.beginner, .intermediate, .expert, .custom]
        return order.map { diff in
            let group = records.filter { $0.difficultyRaw == diff.rawValue }
            let wins = group.filter { $0.won }
            let times = wins.map { $0.durationSec }
            let best = times.min()
            let avg = times.isEmpty ? nil : times.reduce(0, +) / Double(times.count)
            return DifficultyStats(difficulty: diff,
                                   played: group.count,
                                   won: wins.count,
                                   bestTime: best,
                                   avgTime: avg)
        }
    }

    /// Best win time for one difficulty, if any.
    static func bestTime(_ records: [GameRecord], for diff: Difficulty) -> Double? {
        records.filter { $0.difficultyRaw == diff.rawValue && $0.won }
            .map { $0.durationSec }
            .min()
    }

    static func totalPlayed(_ records: [GameRecord]) -> Int { records.count }
    static func totalWon(_ records: [GameRecord]) -> Int { records.filter { $0.won }.count }

    static func overallWinRate(_ records: [GameRecord]) -> Double {
        guard !records.isEmpty else { return 0 }
        return Double(totalWon(records)) / Double(records.count)
    }

    /// Current win streak counting from the most recent games backward.
    static func currentWinStreak(_ records: [GameRecord]) -> Int {
        let sorted = records.sorted { $0.date > $1.date }
        var streak = 0
        for r in sorted {
            if r.won { streak += 1 } else { break }
        }
        return streak
    }

    /// Longest win streak across all of history.
    static func bestWinStreak(_ records: [GameRecord]) -> Int {
        let sorted = records.sorted { $0.date < $1.date }
        var best = 0
        var run = 0
        for r in sorted {
            if r.won { run += 1; best = max(best, run) } else { run = 0 }
        }
        return best
    }
}
