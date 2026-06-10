import Foundation

struct GameSummary {
    let game: Game
    let plays: Int
    let best: Int
    let averageScore: Double
    let averageAccuracy: Double
    let lastScore: Int
}

enum StatsEngine {
    private static var cal: Calendar { Calendar.current }

    static func summary(_ results: [GameResult], game: Game) -> GameSummary {
        let r = results.filter { $0.game == game }.sorted { $0.date < $1.date }
        guard !r.isEmpty else {
            return GameSummary(game: game, plays: 0, best: 0, averageScore: 0, averageAccuracy: 0, lastScore: 0)
        }
        let best = r.map(\.score).max() ?? 0
        let avg = Double(r.map(\.score).reduce(0, +)) / Double(r.count)
        let acc = r.map(\.accuracy).reduce(0, +) / Double(r.count)
        return GameSummary(game: game, plays: r.count, best: best,
                           averageScore: avg, averageAccuracy: acc, lastScore: r.last?.score ?? 0)
    }

    /// Days (start-of-day) on which at least one game was played.
    static func playedDays(_ results: [GameResult]) -> Set<Date> {
        Set(results.map { cal.startOfDay(for: $0.date) })
    }

    static func streak(_ results: [GameResult], today: Date = .now) -> Int {
        let days = playedDays(results)
        guard !days.isEmpty else { return 0 }
        let t = cal.startOfDay(for: today)
        var cursor = t
        if !days.contains(t) {
            cursor = cal.date(byAdding: .day, value: -1, to: t) ?? t
            if !days.contains(cursor) { return 0 }
        }
        var n = 0
        while days.contains(cursor) {
            n += 1
            guard let p = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = p
        }
        return n
    }

    static func totalScore(_ results: [GameResult]) -> Int {
        results.map(\.score).reduce(0, +)
    }

    /// Best single combined "brain score" per day over the last n days, for the
    /// trend chart. Combined = sum of best result per game that day.
    static func dailyBest(_ results: [GameResult], days n: Int, today: Date = .now) -> [(date: Date, score: Int)] {
        let t = cal.startOfDay(for: today)
        let byDay = Dictionary(grouping: results) { cal.startOfDay(for: $0.date) }
        return (0..<n).reversed().map { offset in
            let d = cal.date(byAdding: .day, value: -offset, to: t) ?? t
            let dayResults = byDay[d] ?? []
            // best per game, summed
            let perGame = Dictionary(grouping: dayResults) { $0.game }
                .mapValues { $0.map(\.score).max() ?? 0 }
            return (d, perGame.values.reduce(0, +))
        }
    }

    /// Today's deterministic daily-workout games (three distinct games).
    static func workoutGames(for date: Date = .now) -> [Game] {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in f.string(from: date).utf8 { hash ^= UInt64(byte); hash = hash &* 0x100000001b3 }
        var all = Game.allCases
        var picked: [Game] = []
        var h = hash
        while picked.count < 3 && !all.isEmpty {
            h = h &* 6364136223846793005 &+ 1442695040888963407
            let idx = Int((h >> 33) % UInt64(all.count))
            picked.append(all.remove(at: idx))
        }
        return picked
    }
}
