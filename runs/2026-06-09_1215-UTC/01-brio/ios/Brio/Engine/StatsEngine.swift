import Foundation

/// Pure aggregation over logged sessions for the History header and Insights
/// charts. No state — every value is derived from the passed-in array.
enum StatsEngine {

    struct Summary {
        var totalMinutes: Int
        var totalSessions: Int
        var sessionsThisWeek: Int
        var currentStreak: Int
        var longestStreak: Int
        var completionRate: Double      // 0…1
    }

    struct WeekPoint: Identifiable {
        let id = UUID()
        let weekStart: Date
        let minutes: Int
    }

    struct CategoryPoint: Identifiable {
        let id = UUID()
        let category: WorkoutCategory
        let sessions: Int
        let minutes: Int
    }

    static func summary(_ sessions: [WorkoutSession]) -> Summary {
        let cal = Calendar.current
        let totalMinutes = sessions.reduce(0) { $0 + $1.minutes }
        let completedCount = sessions.filter { $0.completed }.count
        let rate = sessions.isEmpty ? 0 : Double(completedCount) / Double(sessions.count)

        let weekStart = startOfWeek(for: .now, cal: cal)
        let thisWeek = sessions.filter { $0.date >= weekStart }.count

        let (current, longest) = streaks(sessions, cal: cal)

        return Summary(totalMinutes: totalMinutes,
                       totalSessions: sessions.count,
                       sessionsThisWeek: thisWeek,
                       currentStreak: current,
                       longestStreak: longest,
                       completionRate: rate)
    }

    /// Consecutive-day streaks. A day counts if it has ≥1 session.
    static func streaks(_ sessions: [WorkoutSession], cal: Calendar = .current) -> (current: Int, longest: Int) {
        guard !sessions.isEmpty else { return (0, 0) }
        let days = Set(sessions.map { cal.startOfDay(for: $0.date) }).sorted()

        var longest = 1
        var run = 1
        for i in 1..<max(days.count, 1) {
            guard days.count > 1 else { break }
            let prev = days[i - 1]
            let cur = days[i]
            if let next = cal.date(byAdding: .day, value: 1, to: prev), cal.isDate(next, inSameDayAs: cur) {
                run += 1
            } else {
                run = 1
            }
            longest = max(longest, run)
        }

        // Current streak: walk back from today (or yesterday) while days are present.
        let today = cal.startOfDay(for: .now)
        let daySet = Set(days)
        var current = 0
        var cursor = today
        if !daySet.contains(today) {
            // Allow the streak to still be "alive" if the last session was yesterday.
            guard let yesterday = cal.date(byAdding: .day, value: -1, to: today),
                  daySet.contains(yesterday) else {
                return (0, longest)
            }
            cursor = yesterday
        }
        while daySet.contains(cursor) {
            current += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return (current, max(longest, current))
    }

    /// Minutes summed per ISO-ish week for the last `weeks` weeks, oldest → newest.
    static func minutesByWeek(_ sessions: [WorkoutSession], weeks: Int = 8, cal: Calendar = .current) -> [WeekPoint] {
        let thisWeekStart = startOfWeek(for: .now, cal: cal)
        var buckets: [Date: Int] = [:]
        for w in 0..<max(1, weeks) {
            if let start = cal.date(byAdding: .weekOfYear, value: -w, to: thisWeekStart) {
                buckets[start] = 0
            }
        }
        for session in sessions {
            let start = startOfWeek(for: session.date, cal: cal)
            if buckets[start] != nil {
                buckets[start, default: 0] += session.minutes
            }
        }
        return buckets
            .map { WeekPoint(weekStart: $0.key, minutes: $0.value) }
            .sorted { $0.weekStart < $1.weekStart }
    }

    /// Session and minute counts grouped by category, busiest first.
    static func byCategory(_ sessions: [WorkoutSession]) -> [CategoryPoint] {
        var counts: [WorkoutCategory: (Int, Int)] = [:]
        for session in sessions {
            let cat = session.workoutCategory
            let cur = counts[cat] ?? (0, 0)
            counts[cat] = (cur.0 + 1, cur.1 + session.minutes)
        }
        return counts
            .map { CategoryPoint(category: $0.key, sessions: $0.value.0, minutes: $0.value.1) }
            .sorted { $0.sessions > $1.sessions }
    }

    // MARK: - Helpers

    private static func startOfWeek(for date: Date, cal: Calendar) -> Date {
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return cal.date(from: comps) ?? cal.startOfDay(for: date)
    }
}
