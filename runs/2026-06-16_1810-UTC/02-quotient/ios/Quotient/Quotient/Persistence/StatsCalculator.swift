import Foundation

/// Aggregated statistics derived from `PuzzleResult` records.
struct StatsSummary {
    var totalSolved: Int = 0
    var totalPlayed: Int = 0
    var currentStreak: Int = 0
    var bestStreak: Int = 0
    var bestTimeBySize: [Int: Int] = [:]      // size -> best seconds (won only)
    var averageTimeBySize: [Int: Int] = [:]   // size -> avg seconds (won only)
    var winsByDifficulty: [Difficulty: Int] = [:]
    var playedByDifficulty: [Difficulty: Int] = [:]

    var winRate: Double {
        totalPlayed > 0 ? Double(totalSolved) / Double(totalPlayed) : 0
    }

    var isEmpty: Bool { totalPlayed == 0 }

    func winRate(for difficulty: Difficulty) -> Double {
        let played = playedByDifficulty[difficulty] ?? 0
        guard played > 0 else { return 0 }
        return Double(winsByDifficulty[difficulty] ?? 0) / Double(played)
    }
}

enum StatsCalculator {

    static func summarize(_ results: [PuzzleResult]) -> StatsSummary {
        var summary = StatsSummary()
        guard !results.isEmpty else { return summary }

        summary.totalPlayed = results.count
        let wins = results.filter { $0.won }
        summary.totalSolved = wins.count

        // Per-difficulty counts.
        for r in results {
            summary.playedByDifficulty[r.difficulty, default: 0] += 1
            if r.won { summary.winsByDifficulty[r.difficulty, default: 0] += 1 }
        }

        // Best & average time by size (won games only, positive durations).
        var timesBySize: [Int: [Int]] = [:]
        for r in wins where r.durationSeconds > 0 {
            timesBySize[r.size, default: []].append(r.durationSeconds)
        }
        for (size, times) in timesBySize {
            guard !times.isEmpty else { continue }
            summary.bestTimeBySize[size] = times.min()
            summary.averageTimeBySize[size] = times.reduce(0, +) / times.count
        }

        // Streaks: based on consecutive *daily* wins by date key.
        let (current, best) = dailyStreaks(results)
        summary.currentStreak = current
        summary.bestStreak = best

        return summary
    }

    /// Computes the current and best consecutive-day daily-win streaks.
    static func dailyStreaks(_ results: [PuzzleResult]) -> (current: Int, best: Int) {
        let dailyWins = results.filter { $0.won && $0.isDaily && !$0.dateKey.isEmpty }
        let wonKeys = Set(dailyWins.map { $0.dateKey })
        guard !wonKeys.isEmpty else { return (0, 0) }

        let cal = Calendar(identifier: .gregorian)
        let sortedDates = wonKeys.compactMap { DateKey.date(from: $0) }
            .map { cal.startOfDay(for: $0) }
            .sorted()
        guard !sortedDates.isEmpty else { return (0, 0) }

        // Best streak: longest run of consecutive days.
        var best = 1
        var run = 1
        for i in 1..<sortedDates.count {
            if let next = cal.date(byAdding: .day, value: 1, to: sortedDates[i - 1]),
               cal.isDate(next, inSameDayAs: sortedDates[i]) {
                run += 1
            } else {
                run = 1
            }
            best = max(best, run)
        }

        // Current streak: counting back from today (or yesterday).
        let today = cal.startOfDay(for: Date())
        var current = 0
        var cursor = today
        if !wonKeys.contains(DateKey.key(for: today)) {
            // If today not done, the streak may still be alive through yesterday.
            if let yesterday = cal.date(byAdding: .day, value: -1, to: today) {
                cursor = yesterday
            }
        }
        while wonKeys.contains(DateKey.key(for: cursor)) {
            current += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }

        return (current, best)
    }
}
