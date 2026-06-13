import Foundation

enum StatsEngine {
    /// Consecutive days (ending today or yesterday) with at least one daily game played.
    static func dailyStreak(results: [GameResult], now: Date = Date()) -> Int {
        let dailyKeys = Set(results.filter { $0.mode == .daily }.map { $0.dayKey })
        guard !dailyKeys.isEmpty else { return 0 }
        let cal = Calendar.current
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.timeZone = .current
        var streak = 0
        // Allow the streak to count from today or yesterday.
        var start = now
        if !dailyKeys.contains(f.string(from: now)) {
            guard let y = cal.date(byAdding: .day, value: -1, to: now), dailyKeys.contains(f.string(from: y)) else { return 0 }
            start = y
        }
        var day = start
        while dailyKeys.contains(f.string(from: day)) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return streak
    }

    static func overallAccuracy(_ results: [GameResult]) -> Double? {
        let total = results.reduce(0) { $0 + $1.total }
        guard total > 0 else { return nil }
        let correct = results.reduce(0) { $0 + $1.correct }
        return Double(correct) / Double(total)
    }

    static func bestDailyScore(_ results: [GameResult]) -> Int {
        results.filter { $0.mode == .daily }.map { $0.score }.max() ?? 0
    }

    static func categoryAccuracy(_ results: [GameResult]) -> [(category: TriviaCategory, accuracy: Double, games: Int)] {
        var correct: [TriviaCategory: Int] = [:]
        var total: [TriviaCategory: Int] = [:]
        var games: [TriviaCategory: Int] = [:]
        for r in results {
            guard let c = r.category else { continue }
            correct[c, default: 0] += r.correct
            total[c, default: 0] += r.total
            games[c, default: 0] += 1
        }
        return TriviaCategory.allCases.compactMap { c in
            guard let t = total[c], t > 0 else { return nil }
            return (c, Double(correct[c] ?? 0) / Double(t), games[c] ?? 0)
        }
    }

    static func isDailyDone(results: [GameResult], date: Date = Date()) -> GameResult? {
        let key = QuizEngine.dayKey(date)
        return results.first { $0.mode == .daily && $0.dayKey == key }
    }
}
