import Foundation

/// A single point in the "solves over time" / "solve-time trend" series.
struct DayPoint: Identifiable {
    let id = UUID()
    let date: Date
    let dateKey: String
    let elapsedSeconds: Int
    let solved: Bool
}

/// Average solve time grouped by difficulty.
struct DifficultyAverage: Identifiable {
    let id = UUID()
    let difficulty: Difficulty
    let averageSeconds: Int
    let count: Int
}

/// The computed stats payload.
struct StatsResult {
    var totalSolved: Int = 0
    var dailySolved: Int = 0
    var currentStreak: Int = 0
    var bestStreak: Int = 0
    var completionRate: Double = 0      // 0...1 of attempted puzzles solved
    var averageSeconds: Int = 0
    var bestSeconds: Int? = nil
    var points: [DayPoint] = []         // chronological
    var difficultyAverages: [DifficultyAverage] = []

    var isEmpty: Bool { totalSolved == 0 && points.isEmpty }
}

/// Pure stats computation over the persisted history. No SwiftData access here —
/// callers pass snapshots so this can run off the main queue's data safely.
enum StatsEngine {

    /// A lightweight snapshot of a DailyResult (so we don't hold @Model refs).
    struct DailySnapshot {
        let dateKey: String
        let solved: Bool
        let elapsedSeconds: Int
        let difficulty: Difficulty
    }

    /// A lightweight snapshot of a PuzzleProgress.
    struct ProgressSnapshot {
        let puzzleID: String
        let completed: Bool
        let elapsedSeconds: Int
        let solvedAt: Date?
    }

    static func compute(daily: [DailySnapshot],
                        progress: [ProgressSnapshot],
                        difficultyFor: (String) -> Difficulty) -> StatsResult {
        var result = StatsResult()

        // --- Daily-based series + streaks ---
        let solvedDaily = daily.filter { $0.solved }
        result.dailySolved = solvedDaily.count

        // Chronological points from daily results.
        let sortedDaily = daily.sorted { $0.dateKey < $1.dateKey }
        result.points = sortedDaily.compactMap { snap in
            guard let date = DateKey.date(from: snap.dateKey) else { return nil }
            return DayPoint(date: date,
                            dateKey: snap.dateKey,
                            elapsedSeconds: snap.elapsedSeconds,
                            solved: snap.solved)
        }

        // Streaks over the set of solved daily date keys.
        let solvedKeys = Set(solvedDaily.map { $0.dateKey })
        let (current, best) = streaks(solvedKeys: solvedKeys)
        result.currentStreak = current
        result.bestStreak = best

        // --- Totals from progress (covers archive + daily) ---
        let completed = progress.filter { $0.completed }
        result.totalSolved = completed.count
        if !progress.isEmpty {
            result.completionRate = Double(completed.count) / Double(progress.count)
        }

        // Times: prefer all completed solves for average/best.
        let times = completed.map { max(0, $0.elapsedSeconds) }.filter { $0 > 0 }
        if !times.isEmpty {
            result.averageSeconds = times.reduce(0, +) / times.count
            result.bestSeconds = times.min()
        }

        // --- Average by difficulty (from completed progress) ---
        var buckets: [Difficulty: [Int]] = [:]
        for p in completed where p.elapsedSeconds > 0 {
            let diff = difficultyFor(p.puzzleID)
            buckets[diff, default: []].append(p.elapsedSeconds)
        }
        result.difficultyAverages = Difficulty.allCases.compactMap { diff in
            guard let arr = buckets[diff], !arr.isEmpty else { return nil }
            return DifficultyAverage(difficulty: diff,
                                     averageSeconds: arr.reduce(0, +) / arr.count,
                                     count: arr.count)
        }

        return result
    }

    /// Current streak (counting back from today or yesterday) and best streak.
    private static func streaks(solvedKeys: Set<String>) -> (current: Int, best: Int) {
        guard !solvedKeys.isEmpty else { return (0, 0) }

        // Sort the keys' dates.
        let dates = solvedKeys.compactMap { DateKey.date(from: $0) }.sorted()
        guard !dates.isEmpty else { return (0, 0) }

        let cal = Calendar(identifier: .gregorian)

        // Best streak: longest run of consecutive days.
        var best = 1
        var run = 1
        for i in 1..<max(dates.count, 1) {
            guard dates.count > 1 else { break }
            let prev = cal.startOfDay(for: dates[i - 1])
            let cur = cal.startOfDay(for: dates[i])
            let gap = cal.dateComponents([.day], from: prev, to: cur).day ?? 0
            if gap == 1 { run += 1; best = max(best, run) }
            else if gap == 0 { /* same day, ignore */ }
            else { run = 1 }
        }
        if dates.count == 1 { best = 1 }

        // Current streak: must include today or yesterday.
        let todayStart = cal.startOfDay(for: .now)
        let solvedDaySet = Set(dates.map { cal.startOfDay(for: $0) })
        var current = 0
        var cursor = todayStart
        // If today isn't solved, allow starting at yesterday.
        if !solvedDaySet.contains(todayStart) {
            cursor = cal.date(byAdding: .day, value: -1, to: todayStart) ?? todayStart
            if !solvedDaySet.contains(cursor) { return (0, best) }
        }
        while solvedDaySet.contains(cursor) {
            current += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return (current, best)
    }
}
