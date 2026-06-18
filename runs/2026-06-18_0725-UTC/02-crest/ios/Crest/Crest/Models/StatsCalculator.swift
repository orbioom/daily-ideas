import Foundation

/// Pure aggregations over GameResult records for Stats and Daily screens.
enum StatsCalculator {

    struct LayoutStat: Identifiable {
        let id: String
        let layout: BoardLayout
        let played: Int
        let won: Int
        var winRate: Double { played == 0 ? 0 : Double(won) / Double(played) }
    }

    struct ScorePoint: Identifiable {
        let id = UUID()
        let date: Date
        let score: Int
        let won: Bool
    }

    static func totalPlayed(_ results: [GameResult]) -> Int { results.count }

    static func totalWins(_ results: [GameResult]) -> Int { results.filter { $0.won }.count }

    static func winRate(_ results: [GameResult]) -> Double {
        guard !results.isEmpty else { return 0 }
        return Double(totalWins(results)) / Double(results.count)
    }

    static func bestScore(_ results: [GameResult]) -> Int {
        results.map(\.score).max() ?? 0
    }

    static func longestCombo(_ results: [GameResult]) -> Int {
        results.map(\.longestCombo).max() ?? 0
    }

    static func totalTime(_ results: [GameResult]) -> Double {
        results.reduce(0) { $0 + $1.durationSec }
    }

    static func byLayout(_ results: [GameResult]) -> [LayoutStat] {
        BoardLayout.allCases.map { layout in
            let subset = results.filter { $0.layout == layout }
            return LayoutStat(
                id: layout.rawValue,
                layout: layout,
                played: subset.count,
                won: subset.filter { $0.won }.count
            )
        }
    }

    /// Most-recent-N games as score-over-time points (oldest first).
    static func scoreTrend(_ results: [GameResult], limit: Int = 20) -> [ScorePoint] {
        let sorted = results.sorted { $0.date < $1.date }
        let tail = sorted.suffix(limit)
        return tail.map { ScorePoint(date: $0.date, score: $0.score, won: $0.won) }
    }

    // MARK: Daily streak

    /// Day-keys (yyyymmdd) on which a daily game was WON.
    static func dailyWinDayKeys(_ results: [GameResult], calendar: Calendar = .current) -> Set<Int> {
        var set = Set<Int>()
        for r in results where r.isDaily && r.won {
            set.insert(Format.dayKey(r.date, calendar: calendar))
        }
        return set
    }

    /// Current consecutive daily-win streak ending today (or yesterday).
    static func currentStreak(_ results: [GameResult], today: Date = Date(), calendar: Calendar = .current) -> Int {
        let wins = dailyWinDayKeys(results, calendar: calendar)
        guard !wins.isEmpty else { return 0 }
        var streak = 0
        var cursor = calendar.startOfDay(for: today)
        // Allow the streak to count from today; if today not won yet, start from yesterday.
        if !wins.contains(Format.dayKey(cursor, calendar: calendar)) {
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }
        while wins.contains(Format.dayKey(cursor, calendar: calendar)) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    static func bestDailyScore(_ results: [GameResult]) -> Int {
        results.filter { $0.isDaily }.map(\.score).max() ?? 0
    }
}
