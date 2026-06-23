import Foundation

/// Pure functions that turn a list of sessions into stats. No SwiftData / UI here
/// so the logic is easy to reason about and crash-proof.
enum FocusAnalytics {

    struct DayBucket: Identifiable {
        let id = UUID()
        let date: Date
        let minutes: Int
    }

    struct ProjectBucket: Identifiable {
        let id = UUID()
        let name: String
        let colorHex: String
        let minutes: Int
    }

    struct HourBucket: Identifiable {
        let id = UUID()
        let hour: Int
        let minutes: Int
    }

    struct Summary {
        var totalMinutes: Int
        var completedSessions: Int
        var abandonedSessions: Int
        var totalDistractions: Int
        var avgSessionMinutes: Int
        var bestDayMinutes: Int
        /// Completion rate 0...1.
        var completionRate: Double
    }

    /// Only sessions counted toward focus stats: actually completed blocks.
    static func completed(_ sessions: [FocusSession]) -> [FocusSession] {
        sessions.filter { $0.wasCompleted }
    }

    static func summary(_ sessions: [FocusSession]) -> Summary {
        let done = completed(sessions)
        let totalMin = done.reduce(0) { $0 + $1.focusedMinutes }
        let abandoned = sessions.count - done.count
        let distractions = sessions.reduce(0) { $0 + $1.distractionCount }
        let avg = done.isEmpty ? 0 : totalMin / done.count
        let byDay = dailyMinutes(sessions, days: 365)
        let best = byDay.map(\.minutes).max() ?? 0
        let rate = sessions.isEmpty ? 0 : Double(done.count) / Double(sessions.count)
        return Summary(totalMinutes: totalMin,
                       completedSessions: done.count,
                       abandonedSessions: max(0, abandoned),
                       totalDistractions: distractions,
                       avgSessionMinutes: avg,
                       bestDayMinutes: best,
                       completionRate: rate)
    }

    /// Focus minutes for each of the last `days` days (oldest first), including zeros.
    static func dailyMinutes(_ sessions: [FocusSession], days: Int) -> [DayBucket] {
        let count = max(1, days)
        let cal = Calendar.current
        let done = completed(sessions)
        var totals: [Date: Int] = [:]
        for s in done {
            let key = cal.startOfDay(for: s.startedAt)
            totals[key, default: 0] += s.focusedMinutes
        }
        var result: [DayBucket] = []
        for offset in stride(from: count - 1, through: 0, by: -1) {
            let day = Date.daysAgo(offset)
            result.append(DayBucket(date: day, minutes: totals[day] ?? 0))
        }
        return result
    }

    /// Minutes grouped by project for sessions in the given window.
    static func byProject(_ sessions: [FocusSession]) -> [ProjectBucket] {
        let done = completed(sessions)
        var buckets: [String: (hex: String, min: Int)] = [:]
        for s in done {
            let name = s.project?.name ?? "Unassigned"
            let hex = s.project?.colorHex ?? "5B6470"
            let cur = buckets[name] ?? (hex, 0)
            buckets[name] = (hex, cur.min + s.focusedMinutes)
        }
        return buckets
            .map { ProjectBucket(name: $0.key, colorHex: $0.value.hex, minutes: $0.value.min) }
            .sorted { $0.minutes > $1.minutes }
    }

    /// Minutes per hour-of-day (0...23), always 24 entries.
    static func byHour(_ sessions: [FocusSession]) -> [HourBucket] {
        let done = completed(sessions)
        var totals = Array(repeating: 0, count: 24)
        for s in done {
            let h = min(23, max(0, s.hourOfDay))
            totals[h] += s.focusedMinutes
        }
        return totals.enumerated().map { HourBucket(hour: $0.offset, minutes: $0.element) }
    }

    /// Current consecutive-day streak (days with ≥1 completed session), counting today or yesterday as the anchor.
    static func currentStreak(_ sessions: [FocusSession]) -> Int {
        let cal = Calendar.current
        let activeDays = Set(completed(sessions).map { cal.startOfDay(for: $0.startedAt) })
        guard !activeDays.isEmpty else { return 0 }
        var anchor = Date().startOfDay
        if !activeDays.contains(anchor) {
            // Allow the streak to still be "alive" if yesterday was active.
            guard let yest = cal.date(byAdding: .day, value: -1, to: anchor),
                  activeDays.contains(yest) else { return 0 }
            anchor = yest
        }
        var streak = 0
        var cursor = anchor
        while activeDays.contains(cursor) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    /// Longest historical streak of consecutive active days.
    static func longestStreak(_ sessions: [FocusSession]) -> Int {
        let cal = Calendar.current
        let days = Set(completed(sessions).map { cal.startOfDay(for: $0.startedAt) }).sorted()
        guard !days.isEmpty else { return 0 }
        var longest = 1
        var run = 1
        for i in 1..<days.count {
            if let next = cal.date(byAdding: .day, value: 1, to: days[i - 1]), next == days[i] {
                run += 1
            } else {
                run = 1
            }
            longest = max(longest, run)
        }
        return longest
    }

    /// Sessions whose start falls within the last `days` days (inclusive of today).
    static func within(_ sessions: [FocusSession], days: Int) -> [FocusSession] {
        let cutoff = Date.daysAgo(max(0, days - 1))
        return sessions.filter { $0.startedAt >= cutoff }
    }
}
