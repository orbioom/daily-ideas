import Foundation

/// Pure logic: deterministic question-of-day, streaks, pulse trends, and
/// occasion roll-forward.
enum DuetEngine {

    static func dateKey(for date: Date = .now, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 2000, c.month ?? 1, c.day ?? 1)
    }

    /// FNV-1a over the date key — both partners always get the same card.
    static func seed(for key: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in key.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        return hash
    }

    /// The day's question. Skips questions answered on earlier days so a
    /// couple cycles the whole bank before repeats; skips Spark if hidden.
    static func questionOfDay(dateKey key: String,
                              previouslyAnswered: Set<Int>,
                              includeSpark: Bool) -> Question {
        let pool = QuestionBank.all.filter { includeSpark || $0.category != .spark }
        let fallback = pool.first ?? QuestionBank.all[0]
        guard !pool.isEmpty else { return fallback }
        let start = Int(seed(for: key) % UInt64(pool.count))
        for offset in 0..<pool.count {
            let q = pool[(start + offset) % pool.count]
            if !previouslyAnswered.contains(q.id) { return q }
        }
        // Whole bank answered — cycle again deterministically.
        return pool[start]
    }

    /// Consecutive days with a revealed answer, ending today or yesterday.
    static func streak(answers: [Answer], calendar: Calendar = .current, now: Date = .now) -> Int {
        let revealedKeys = Set(answers.filter(\.revealed).map(\.dateKey))
        var streak = 0
        var cursor = calendar.startOfDay(for: now)
        if !revealedKeys.contains(dateKey(for: cursor, calendar: calendar)) {
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }
        while revealedKeys.contains(dateKey(for: cursor, calendar: calendar)) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    /// Next occurrence of an occasion (annual roll-forward, Feb-29 safe).
    static func nextOccurrence(of occasion: Occasion, after now: Date = .now,
                               calendar: Calendar = .current) -> Date? {
        guard occasion.repeatsAnnually else {
            return occasion.date >= calendar.startOfDay(for: now) ? occasion.date : nil
        }
        let comps = calendar.dateComponents([.month, .day], from: occasion.date)
        return calendar.nextDate(after: calendar.startOfDay(for: now).addingTimeInterval(-1),
                                 matching: comps, matchingPolicy: .nextTime)
    }

    static func daysUntil(_ date: Date, calendar: Calendar = .current, now: Date = .now) -> Int {
        let from = calendar.startOfDay(for: now)
        let to = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: from, to: to).day ?? 0
    }

    /// True if a check-in already exists in the current calendar week.
    static func hasCheckInThisWeek(_ checkIns: [CheckIn],
                                   calendar: Calendar = .current, now: Date = .now) -> Bool {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: now) else { return false }
        return checkIns.contains { $0.date >= week.start && $0.date < week.end }
    }
}
