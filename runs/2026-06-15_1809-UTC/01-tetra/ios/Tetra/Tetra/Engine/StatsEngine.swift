import Foundation

/// One point on the "scores over time" chart.
struct ScorePoint: Identifiable {
    let id: UUID
    let date: Date
    let score: Int
    let boardSize: Int
}

/// One bar in the highest-tile distribution.
struct TileBucket: Identifiable {
    var id: Int { tile }
    let tile: Int
    let count: Int
}

/// Aggregated, derived statistics computed off the main update path. Pure & testable.
struct StatsSummary {
    let gamesPlayed: Int
    let wins: Int
    let winRate: Double          // 0...1
    let bestScore: Int
    let totalMoves: Int
    let totalSeconds: Int
    let bestScoreBySize: [Int: Int]
    let scorePoints: [ScorePoint]
    let tileBuckets: [TileBucket]
    let currentStreak: Int       // consecutive days played up to today
    let bestStreak: Int

    var isEmpty: Bool { gamesPlayed == 0 }

    var totalTimeLabel: String {
        let minutes = totalSeconds / 60
        if minutes < 60 { return "\(minutes)m" }
        let hours = minutes / 60
        let rem = minutes % 60
        return "\(hours)h \(rem)m"
    }

    var winRatePercent: Int { Int((winRate * 100).rounded()) }
}

enum StatsEngine {
    /// Builds a full summary from completed game records.
    static func summarize(records: [GameRecord], calendar: Calendar = .current, today: Date = Date()) -> StatsSummary {
        let games = records.count
        let wins = records.filter { $0.won }.count
        let bestScore = records.map(\.score).max() ?? 0
        let totalMoves = records.reduce(0) { $0 + $1.moves }
        let totalSeconds = records.reduce(0) { $0 + $1.durationSeconds }

        var bestBySize: [Int: Int] = [:]
        for r in records {
            bestBySize[r.boardSize] = max(bestBySize[r.boardSize] ?? 0, r.score)
        }

        let points = records
            .sorted { $0.date < $1.date }
            .map { ScorePoint(id: $0.id, date: $0.date, score: $0.score, boardSize: $0.boardSize) }

        // Highest-tile distribution: count games whose highest tile == each power of two.
        var tileCounts: [Int: Int] = [:]
        for r in records where r.highestTile > 0 {
            tileCounts[r.highestTile, default: 0] += 1
        }
        let buckets = tileCounts
            .map { TileBucket(tile: $0.key, count: $0.value) }
            .sorted { $0.tile < $1.tile }

        let (current, best) = streaks(records: records, calendar: calendar, today: today)

        return StatsSummary(
            gamesPlayed: games,
            wins: wins,
            winRate: games == 0 ? 0 : Double(wins) / Double(games),
            bestScore: bestScore,
            totalMoves: totalMoves,
            totalSeconds: totalSeconds,
            bestScoreBySize: bestBySize,
            scorePoints: points,
            tileBuckets: buckets,
            currentStreak: current,
            bestStreak: best
        )
    }

    /// Current streak (consecutive days played ending today or yesterday) and best-ever streak.
    static func streaks(records: [GameRecord], calendar: Calendar = .current, today: Date = Date()) -> (current: Int, best: Int) {
        guard !records.isEmpty else { return (0, 0) }
        // Unique calendar days, sorted ascending.
        let days = Set(records.map { calendar.startOfDay(for: $0.date) }).sorted()
        guard !days.isEmpty else { return (0, 0) }

        // Best streak: longest run of consecutive days.
        var best = 1
        var run = 1
        for i in 1..<max(days.count, 1) where i < days.count {
            let prev = days[i - 1]
            let cur = days[i]
            if let next = calendar.date(byAdding: .day, value: 1, to: prev), calendar.isDate(next, inSameDayAs: cur) {
                run += 1
            } else {
                run = 1
            }
            best = max(best, run)
        }
        if days.count == 1 { best = 1 }

        // Current streak: walk back from today (or yesterday) while each prior day is present.
        let daySet = Set(days)
        let startToday = calendar.startOfDay(for: today)
        var anchor: Date
        if daySet.contains(startToday) {
            anchor = startToday
        } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: startToday), daySet.contains(yesterday) {
            anchor = yesterday
        } else {
            return (0, best)
        }
        var current = 0
        var cursor: Date? = anchor
        while let c = cursor, daySet.contains(c) {
            current += 1
            cursor = calendar.date(byAdding: .day, value: -1, to: c)
        }
        return (current, best)
    }
}
