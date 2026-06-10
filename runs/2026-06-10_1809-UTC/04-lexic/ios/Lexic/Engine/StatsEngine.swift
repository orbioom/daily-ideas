import Foundation

struct LexicStats {
    let played: Int
    let won: Int
    let currentStreak: Int
    let maxStreak: Int
    /// Index 0..5 → number of wins in 1..6 guesses.
    let distribution: [Int]
    var winRate: Double { played > 0 ? Double(won) / Double(played) : 0 }
    var maxBar: Int { distribution.max() ?? 0 }
}

enum StatsEngine {
    private static var cal: Calendar { Calendar.current }

    /// Stats over finished games. Streak counts consecutive finished games by
    /// completion order, broken by a loss (standard Wordle-style behavior).
    static func stats(_ games: [WordGame]) -> LexicStats {
        let finished = games.filter { $0.isFinished }
            .sorted { ($0.finishedAt ?? $0.startedAt) < ($1.finishedAt ?? $1.startedAt) }
        let won = finished.filter { $0.state == .won }
        var dist = [Int](repeating: 0, count: 6)
        for g in won where (1...6).contains(g.guessCount) { dist[g.guessCount - 1] += 1 }

        // Current + max streak across completion order.
        var current = 0, maxS = 0
        for g in finished {
            if g.state == .won { current += 1; maxS = max(maxS, current) }
            else { current = 0 }
        }
        return LexicStats(played: finished.count, won: won.count,
                          currentStreak: current, maxStreak: maxS, distribution: dist)
    }

    /// Lexic "day number" — days since launch epoch, for the share header.
    static func dayNumber(for date: Date = .now) -> Int {
        var comps = DateComponents(); comps.year = 2026; comps.month = 1; comps.day = 1
        let epoch = cal.date(from: comps) ?? date
        let days = cal.dateComponents([.day], from: epoch, to: date).day ?? 0
        return max(1, days + 1)
    }
}
