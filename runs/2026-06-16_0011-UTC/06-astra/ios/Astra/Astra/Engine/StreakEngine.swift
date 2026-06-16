import Foundation

/// Computes the current daily-reflection streak from journal entries.
enum StreakEngine {

    /// Number of consecutive days (ending today or yesterday) with at least one entry.
    static func currentStreak(entries: [JournalEntry], now: Date = Date()) -> Int {
        let cal = Calendar.current
        // Unique day-starts that have an entry.
        let days = Set(entries.map { cal.startOfDay(for: $0.date) })
        guard !days.isEmpty else { return 0 }

        var streak = 0
        var cursor = cal.startOfDay(for: now)

        // Allow the streak to be "alive" if today has no entry yet but yesterday did.
        if !days.contains(cursor) {
            guard let yesterday = cal.date(byAdding: .day, value: -1, to: cursor),
                  days.contains(yesterday) else {
                return 0
            }
            cursor = yesterday
        }

        while days.contains(cursor) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    /// Whether an entry exists for today.
    static func hasEntryToday(entries: [JournalEntry], now: Date = Date()) -> Bool {
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        return entries.contains { cal.startOfDay(for: $0.date) == today }
    }
}
