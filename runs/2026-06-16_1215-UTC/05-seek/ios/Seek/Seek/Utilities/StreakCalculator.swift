import Foundation

/// Computes current and longest daily streaks from completed daily results.
enum StreakCalculator {

    /// The current streak counts consecutive completed days ending today or yesterday.
    static func current(from results: [DailyResult], today: Date = .now) -> Int {
        let completedKeys = Set(results.filter { $0.completed }.map { $0.dateKey })
        guard !completedKeys.isEmpty else { return 0 }
        let calendar = Calendar.current

        // The streak may end today or (if today isn't done yet) yesterday.
        var anchor: Date
        if completedKeys.contains(Formatters.dayKey(today)) {
            anchor = today
        } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
                  completedKeys.contains(Formatters.dayKey(yesterday)) {
            anchor = yesterday
        } else {
            return 0
        }

        var streak = 0
        var cursor = anchor
        while completedKeys.contains(Formatters.dayKey(cursor)) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    /// The longest run of consecutive completed days, anywhere in history.
    static func longest(from results: [DailyResult]) -> Int {
        let completed = results.filter { $0.completed }
        guard !completed.isEmpty else { return 0 }
        let calendar = Calendar.current

        // Convert keys to dates, sort, then scan for the longest consecutive run.
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"

        let dates = completed
            .compactMap { formatter.date(from: $0.dateKey) }
            .map { calendar.startOfDay(for: $0) }
            .sorted()
        guard !dates.isEmpty else { return 0 }

        var best = 1
        var run = 1
        var i = 1
        while i < dates.count {
            let prev = dates[i - 1]
            let curr = dates[i]
            if let next = calendar.date(byAdding: .day, value: 1, to: prev),
               calendar.isDate(next, inSameDayAs: curr) {
                run += 1
            } else if calendar.isDate(prev, inSameDayAs: curr) {
                // Same day duplicate; ignore.
            } else {
                run = 1
            }
            best = max(best, run)
            i += 1
        }
        return best
    }
}
