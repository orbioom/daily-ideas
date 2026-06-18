import Foundation

/// Derives streaks and stats from a set of DailyResult rows.
enum StreakCalculator {

    /// A day "counts" toward the play streak if at least one word was found that day.
    static func playedKeys(from results: [DailyResult]) -> Set<String> {
        Set(results.filter { $0.wordsFound > 0 }.map { $0.dateKey })
    }

    /// Current streak ending today (or yesterday — a streak stays alive until a missed day).
    static func currentStreak(from results: [DailyResult], today: Date = Date()) -> Int {
        let keys = playedKeys(from: results)
        guard !keys.isEmpty else { return 0 }
        let cal = Calendar(identifier: .gregorian)
        var streak = 0
        // Allow the streak to start from today or yesterday (today not yet played is fine).
        var cursor = cal.startOfDay(for: today)
        if !keys.contains(DateKey.key(for: cursor)) {
            guard let yesterday = cal.date(byAdding: .day, value: -1, to: cursor) else { return 0 }
            cursor = yesterday
            if !keys.contains(DateKey.key(for: cursor)) { return 0 }
        }
        while keys.contains(DateKey.key(for: cursor)) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    /// Longest run of consecutive played days in history.
    static func longestStreak(from results: [DailyResult]) -> Int {
        let keys = playedKeys(from: results)
        guard !keys.isEmpty else { return 0 }
        let cal = Calendar(identifier: .gregorian)
        let dates = keys.compactMap { DateKey.date(from: $0) }
            .map { cal.startOfDay(for: $0) }
            .sorted()
        var longest = 1
        var run = 1
        for i in 1..<max(dates.count, 1) where dates.count > 1 {
            let prev = dates[i - 1]
            let curr = dates[i]
            if let next = cal.date(byAdding: .day, value: 1, to: prev),
               cal.isDate(next, inSameDayAs: curr) {
                run += 1
            } else {
                run = 1
            }
            longest = max(longest, run)
        }
        return longest
    }

    static func geniusRate(from results: [DailyResult]) -> Double {
        guard !results.isEmpty else { return 0 }
        let genius = results.filter { $0.reachedGenius }.count
        return Double(genius) / Double(results.count)
    }

    static func totalPangrams(from results: [DailyResult]) -> Int {
        results.reduce(0) { $0 + $1.pangrams }
    }

    static func totalWords(from results: [DailyResult]) -> Int {
        results.reduce(0) { $0 + $1.wordsFound }
    }
}
