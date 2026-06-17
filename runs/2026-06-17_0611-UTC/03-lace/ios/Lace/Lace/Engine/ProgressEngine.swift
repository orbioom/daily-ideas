import Foundation

/// Aggregated progress for the active plan & overall training history. Pure
/// functions over the completed-session list; all division is guarded.
enum ProgressEngine {

    struct Stats {
        var totalSessions: Int
        var totalSeconds: Int
        var runSeconds: Int
        var currentStreakDays: Int
        var longestStreakDays: Int
        var sessionsThisWeek: Int

        var totalMinutes: Int { Int((Double(totalSeconds) / 60.0).rounded()) }
        var runMinutes: Int { Int((Double(runSeconds) / 60.0).rounded()) }
    }

    /// Overall completion fraction of a plan given its completed sessions.
    /// Division-guarded; counts distinct completed (week, index) pairs.
    static func completionFraction(plan: TrainingPlan, completed: [CompletedSession]) -> Double {
        guard plan.totalSessions > 0 else { return 0 }
        let relevant = completed.filter { $0.planId == plan.id }
        let distinct = Set(relevant.map { "\($0.week)-\($0.sessionIndex)" })
        return min(1.0, Double(distinct.count) / Double(plan.totalSessions))
    }

    /// Sessions completed this calendar week (active plan or all — caller filters).
    static func sessionsThisWeek(_ completed: [CompletedSession], calendar: Calendar = .current, now: Date = Date()) -> Int {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: now) else { return 0 }
        return completed.filter { week.contains($0.date) }.count
    }

    /// Distinct active days in the current consecutive streak ending today or yesterday.
    static func currentStreak(_ completed: [CompletedSession], calendar: Calendar = .current, now: Date = Date()) -> Int {
        let days = distinctDays(completed, calendar: calendar)
        guard !days.isEmpty else { return 0 }

        let today = calendar.startOfDay(for: now)
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return 0 }

        // Streak only counts if the most recent activity was today or yesterday.
        guard let latest = days.first, latest == today || latest == yesterday else { return 0 }

        var streak = 0
        var cursor = latest
        let daySet = Set(days)
        while daySet.contains(cursor) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    /// The longest run of consecutive active days in the whole history.
    static func longestStreak(_ completed: [CompletedSession], calendar: Calendar = .current) -> Int {
        let days = distinctDays(completed, calendar: calendar).sorted()
        guard !days.isEmpty else { return 0 }
        var longest = 1
        var current = 1
        for i in 1..<days.count {
            guard let prev = days[safe: i - 1], let day = days[safe: i] else { continue }
            if let expected = calendar.date(byAdding: .day, value: 1, to: prev), expected == day {
                current += 1
            } else {
                current = 1
            }
            longest = max(longest, current)
        }
        return longest
    }

    /// Full stats bundle.
    static func stats(_ completed: [CompletedSession], calendar: Calendar = .current, now: Date = Date()) -> Stats {
        Stats(
            totalSessions: completed.count,
            totalSeconds: completed.reduce(0) { $0 + $1.durationSeconds },
            runSeconds: completed.reduce(0) { $0 + $1.runSeconds },
            currentStreakDays: currentStreak(completed, calendar: calendar, now: now),
            longestStreakDays: longestStreak(completed, calendar: calendar),
            sessionsThisWeek: sessionsThisWeek(completed, calendar: calendar, now: now)
        )
    }

    /// Minutes grouped by ISO week start, oldest→newest, for the bar chart.
    static func minutesPerWeek(_ completed: [CompletedSession], calendar: Calendar = .current) -> [WeekBucket] {
        var buckets: [Date: Int] = [:]
        for s in completed {
            guard let interval = calendar.dateInterval(of: .weekOfYear, for: s.date) else { continue }
            buckets[interval.start, default: 0] += s.durationSeconds
        }
        return buckets
            .map { WeekBucket(weekStart: $0.key, minutes: Int((Double($0.value) / 60.0).rounded())) }
            .sorted { $0.weekStart < $1.weekStart }
    }

    /// Cumulative session count over time, oldest→newest, for the line chart.
    static func cumulativeSessions(_ completed: [CompletedSession]) -> [CumulativePoint] {
        let sorted = completed.sorted { $0.date < $1.date }
        var running = 0
        return sorted.map { s in
            running += 1
            return CumulativePoint(date: s.date, count: running)
        }
    }

    // MARK: - Helpers

    private static func distinctDays(_ completed: [CompletedSession], calendar: Calendar) -> [Date] {
        let days = Set(completed.map { calendar.startOfDay(for: $0.date) })
        return days.sorted(by: >)   // most-recent first
    }
}

/// A week's total minutes, for charts.
struct WeekBucket: Identifiable {
    var id: Date { weekStart }
    let weekStart: Date
    let minutes: Int
}

/// A point on the cumulative-sessions line.
struct CumulativePoint: Identifiable {
    var id: Date { date }
    let date: Date
    let count: Int
}
