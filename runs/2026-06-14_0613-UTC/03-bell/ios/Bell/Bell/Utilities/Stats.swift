import Foundation

/// Minimal read interface shared by the SwiftData model and the Sendable
/// snapshot so the same stat functions serve the Today screen (live models) and
/// the Insights screen (off-main computation).
protocol SessionStat {
    var date: Date { get }
    var durationSec: Int { get }
    var mood: Mood { get }
}

extension MeditationSession: SessionStat {}

/// Pure functions over sessions for the Today + Insights screens. Identifiable
/// chart series structs live here too.
enum Stats {

    /// Sendable value snapshot for crunching off the main actor.
    struct SessionSnapshot: SessionStat, Sendable {
        let date: Date
        let durationSec: Int
        let mood: Mood
    }

    private static func timeOfDay(of s: SessionStat) -> TimeOfDay {
        let hour = Calendar.current.component(.hour, from: s.date)
        return TimeOfDay.from(hour: hour)
    }

    // MARK: - Today

    static func minutesToday(_ sessions: [some SessionStat], now: Date = Date()) -> Int {
        let cal = Calendar.current
        return sessions
            .filter { cal.isDate($0.date, inSameDayAs: now) }
            .reduce(0) { $0 + $1.durationSec / 60 }
    }

    static func totalMinutes(_ sessions: [some SessionStat]) -> Int {
        sessions.reduce(0) { $0 + $1.durationSec / 60 }
    }

    static func averageMinutes(_ sessions: [some SessionStat]) -> Int {
        guard !sessions.isEmpty else { return 0 }
        return totalMinutes(sessions) / sessions.count
    }

    /// Current streak in days (consecutive days ending today or yesterday).
    static func currentStreak(_ sessions: [some SessionStat], now: Date = Date()) -> Int {
        let cal = Calendar.current
        let days = Set(sessions.map { cal.startOfDay(for: $0.date) })
        guard !days.isEmpty else { return 0 }

        var streak = 0
        var cursor = cal.startOfDay(for: now)
        if !days.contains(cursor) {
            guard let yesterday = cal.date(byAdding: .day, value: -1, to: cursor),
                  days.contains(yesterday) else { return 0 }
            cursor = yesterday
        }
        while days.contains(cursor) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    /// Longest streak ever.
    static func longestStreak(_ sessions: [some SessionStat]) -> Int {
        let cal = Calendar.current
        let days = Set(sessions.map { cal.startOfDay(for: $0.date) }).sorted()
        guard !days.isEmpty else { return 0 }

        var longest = 1
        var run = 1
        for i in 1..<days.count {
            if let prev = cal.date(byAdding: .day, value: 1, to: days[i - 1]),
               cal.isDate(prev, inSameDayAs: days[i]) {
                run += 1
            } else {
                run = 1
            }
            longest = max(longest, run)
        }
        return longest
    }

    // MARK: - Chart series

    struct DayMinutes: Identifiable {
        let id: Date
        let date: Date
        let minutes: Int
    }

    /// Minutes per day for the last `days` days (zero-filled).
    static func minutesPerDay(_ sessions: [some SessionStat], days: Int = 30, now: Date = Date()) -> [DayMinutes] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        var buckets: [Date: Int] = [:]
        for s in sessions {
            let d = cal.startOfDay(for: s.date)
            buckets[d, default: 0] += s.durationSec / 60
        }
        var out: [DayMinutes] = []
        for offset in stride(from: days - 1, through: 0, by: -1) {
            guard let d = cal.date(byAdding: .day, value: -offset, to: today) else { continue }
            out.append(DayMinutes(id: d, date: d, minutes: buckets[d] ?? 0))
        }
        return out
    }

    struct TimeBucket: Identifiable {
        let id: String
        let bucket: TimeOfDay
        let count: Int
    }

    static func byTimeOfDay(_ sessions: [some SessionStat]) -> [TimeBucket] {
        var counts: [TimeOfDay: Int] = [:]
        for s in sessions { counts[timeOfDay(of: s), default: 0] += 1 }
        return TimeOfDay.allCases.map { TimeBucket(id: $0.rawValue, bucket: $0, count: counts[$0] ?? 0) }
    }

    struct MoodSlice: Identifiable {
        let id: String
        let mood: Mood
        let count: Int
    }

    static func moodDistribution(_ sessions: [some SessionStat]) -> [MoodSlice] {
        var counts: [Mood: Int] = [:]
        for s in sessions { counts[s.mood, default: 0] += 1 }
        return Mood.allCases
            .map { MoodSlice(id: $0.rawValue, mood: $0, count: counts[$0] ?? 0) }
            .filter { $0.count > 0 }
    }

    struct HeatCell: Identifiable {
        let id: Date
        let date: Date
        let minutes: Int
    }

    /// Last `days` days as heatmap cells.
    static func heatmap(_ sessions: [some SessionStat], days: Int = 35, now: Date = Date()) -> [HeatCell] {
        minutesPerDay(sessions, days: days, now: now).map { HeatCell(id: $0.id, date: $0.date, minutes: $0.minutes) }
    }
}
