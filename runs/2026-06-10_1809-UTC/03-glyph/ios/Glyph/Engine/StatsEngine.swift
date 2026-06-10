import Foundation

struct DifficultyStats {
    let difficulty: SudokuDifficulty
    let played: Int
    let won: Int
    let bestSeconds: Int?
    let averageSeconds: Int?
    var winRate: Double { played > 0 ? Double(won) / Double(played) : 0 }
}

enum StatsEngine {
    private static var cal: Calendar { Calendar.current }

    static func stats(_ games: [SudokuGame], difficulty: SudokuDifficulty) -> DifficultyStats {
        let all = games.filter { $0.difficulty == difficulty }
        let wins = all.filter { $0.isComplete }
        let cleanWins = wins.filter { $0.mistakes == 0 }
        let times = wins.map(\.elapsedSeconds).filter { $0 > 0 }
        let best = cleanWins.map(\.elapsedSeconds).filter { $0 > 0 }.min() ?? times.min()
        let avg = times.isEmpty ? nil : times.reduce(0, +) / times.count
        return DifficultyStats(difficulty: difficulty, played: all.count, won: wins.count,
                               bestSeconds: best, averageSeconds: avg)
    }

    static func totalWins(_ games: [SudokuGame]) -> Int { games.filter { $0.isComplete }.count }

    /// Daily streak based on days with at least one completed game.
    static func streak(_ games: [SudokuGame], today: Date = .now) -> Int {
        let days = Set(games.filter { $0.isComplete }.compactMap { $0.finishedAt }
            .map { cal.startOfDay(for: $0) })
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

    static func format(_ seconds: Int?) -> String {
        guard let s = seconds, s > 0 else { return "—" }
        return format(s)
    }

    static func format(_ seconds: Int) -> String {
        let m = seconds / 60, s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }

    /// Deterministic seed for the daily puzzle so everyone gets the same board.
    static func dailySeed(for date: Date = .now) -> UInt64 {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyyMMdd"
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in f.string(from: date).utf8 { hash ^= UInt64(byte); hash = hash &* 0x100000001b3 }
        return hash
    }

    static func dailyKey(for date: Date = .now) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}
