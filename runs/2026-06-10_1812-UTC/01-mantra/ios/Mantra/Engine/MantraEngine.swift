import Foundation

/// Deterministic, seedable RNG (SplitMix64) so the daily set is stable across
/// relaunches on the same calendar day.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

/// Pure functions for the daily set and practice statistics. No I/O, no SwiftData
/// — fed plain values so it is trivial to reason about and test.
enum MantraEngine {

    static func dayKey(_ date: Date, calendar: Calendar = .current) -> Int {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return (c.year ?? 2026) * 10_000 + (c.month ?? 1) * 100 + (c.day ?? 1)
    }

    /// A stable shuffled selection of affirmations for a given day.
    static func dailySet(from pool: [Affirmation], date: Date = .now, count: Int) -> [Affirmation] {
        guard !pool.isEmpty else { return [] }
        var gen = SeededGenerator(seed: UInt64(bitPattern: Int64(dayKey(date))))
        let shuffled = pool.shuffled(using: &gen)
        return Array(shuffled.prefix(max(1, min(count, shuffled.count))))
    }

    /// Affirmation of the day — first of the daily set, deterministic.
    static func affirmationOfDay(from pool: [Affirmation], date: Date = .now) -> Affirmation? {
        dailySet(from: pool, date: date, count: 1).first
    }

    /// Current streak: consecutive calendar days (ending today or yesterday)
    /// that contain at least one practice log.
    static func currentStreak(logs: [PracticeLog], now: Date = .now, calendar: Calendar = .current) -> Int {
        guard !logs.isEmpty else { return 0 }
        let days = Set(logs.map { calendar.startOfDay(for: $0.date) })
        var streak = 0
        var cursor = calendar.startOfDay(for: now)
        // Allow the streak to count if today has no log yet but yesterday does.
        if !days.contains(cursor) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor),
                  days.contains(yesterday) else { return 0 }
            cursor = yesterday
        }
        while days.contains(cursor) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    static func daysPracticed(logs: [PracticeLog], calendar: Calendar = .current) -> Int {
        Set(logs.map { calendar.startOfDay(for: $0.date) }).count
    }

    static func favoriteCategory(logs: [PracticeLog]) -> MantraCategory? {
        guard !logs.isEmpty else { return nil }
        let counts = Dictionary(grouping: logs, by: { $0.category }).mapValues { $0.count }
        return counts.max(by: { $0.value < $1.value })?.key
    }

    /// Counts per day for the last `span` days (oldest first), for the chart.
    static func dailyCounts(logs: [PracticeLog], span: Int = 14, now: Date = .now,
                            calendar: Calendar = .current) -> [(date: Date, count: Int)] {
        let today = calendar.startOfDay(for: now)
        let byDay = Dictionary(grouping: logs, by: { calendar.startOfDay(for: $0.date) })
            .mapValues { $0.count }
        return (0..<span).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return (day, byDay[day] ?? 0)
        }
    }
}
