import Foundation

/// Deterministically maps a calendar date + word length to the day's answer, and
/// builds the stable SavedGame / GameResult keys. Everyone with the same date and
/// length gets the same word; the same date always yields the same word.
enum DailyPuzzle {

    static let maxGuesses = 6

    /// The answer for a given date and length. Deterministic and stable.
    static func answer(for date: Date, length: Int, calendar: Calendar = .current) -> String {
        let pool = WordLists.answers(length: length)
        guard !pool.isEmpty else { return "" }
        let idx = DailySeed.index(for: date, count: pool.count, calendar: calendar)
        return pool[safe: idx] ?? (pool.first ?? "")
    }

    /// A yyyy-MM-dd string for keys / labels, in the user's calendar.
    static func dateStamp(for date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        let y = c.year ?? 2026
        let m = c.month ?? 1
        let d = c.day ?? 1
        return String(format: "%04d-%02d-%02d", y, m, d)
    }

    /// SavedGame key for a daily/archive puzzle.
    static func savedKey(mode: GameMode, date: Date, length: Int, calendar: Calendar = .current) -> String {
        switch mode {
        case .practice:
            return "practice"
        case .daily:
            return "daily-\(dateStamp(for: date, calendar: calendar))-len\(length)"
        case .archive:
            return "archive-\(dateStamp(for: date, calendar: calendar))-len\(length)"
        }
    }

    /// Start of day for a date, for stable date comparisons / storage.
    static func startOfDay(_ date: Date, calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: date)
    }

    /// The most recent `count` daily dates ending today (today first).
    static func recentDates(count: Int, from today: Date = .now, calendar: Calendar = .current) -> [Date] {
        let base = calendar.startOfDay(for: today)
        var out: [Date] = []
        for offset in 0..<max(0, count) {
            if let d = calendar.date(byAdding: .day, value: -offset, to: base) {
                out.append(d)
            }
        }
        return out
    }
}
