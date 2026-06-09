import Foundation

/// Pure statistics over `CompletionLog` history for the Insights screen.
/// All series are dependency-free and clamp empty inputs gracefully.
enum StatsEngine {

    // MARK: - Points

    struct DayPoint: Identifiable {
        let date: Date
        let count: Int
        var id: Date { date }
    }

    struct WeekPoint: Identifiable {
        let weekStart: Date
        let count: Int
        let minutes: Int
        var id: Date { weekStart }
    }

    struct RoomPoint: Identifiable {
        let room: String
        let count: Int
        let minutes: Int
        var id: String { room }
    }

    struct Summary {
        let totalCompletions: Int
        let totalMinutes: Int
        let currentStreak: Int
        let roomsTouched: Int
    }

    // MARK: - Daily series

    /// Completions per day for the last `days` days (oldest → newest).
    static func dailySeries(_ logs: [CompletionLog], days: Int, now: Date = .now, calendar: Calendar = .current) -> [DayPoint] {
        let span = max(1, days)
        let today = calendar.startOfDay(for: now)
        var counts: [Date: Int] = [:]
        for log in logs {
            let day = calendar.startOfDay(for: log.date)
            counts[day, default: 0] += 1
        }
        var points: [DayPoint] = []
        for offset in stride(from: span - 1, through: 0, by: -1) {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            points.append(DayPoint(date: day, count: counts[day] ?? 0))
        }
        return points
    }

    // MARK: - Weekly series

    /// Completions per week for the last `weeks` weeks (oldest → newest).
    static func weeklySeries(_ logs: [CompletionLog], weeks: Int, now: Date = .now, calendar: Calendar = .current) -> [WeekPoint] {
        let span = max(1, weeks)
        let thisWeekStart = startOfWeek(now, calendar: calendar)
        var counts: [Date: (count: Int, minutes: Int)] = [:]
        for log in logs {
            let ws = startOfWeek(log.date, calendar: calendar)
            var entry = counts[ws] ?? (0, 0)
            entry.count += 1
            entry.minutes += log.minutes
            counts[ws] = entry
        }
        var points: [WeekPoint] = []
        for offset in stride(from: span - 1, through: 0, by: -1) {
            guard let ws = calendar.date(byAdding: .weekOfYear, value: -offset, to: thisWeekStart) else { continue }
            let e = counts[ws] ?? (0, 0)
            points.append(WeekPoint(weekStart: ws, count: e.count, minutes: e.minutes))
        }
        return points
    }

    private static func startOfWeek(_ date: Date, calendar: Calendar) -> Date {
        let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: comps) ?? calendar.startOfDay(for: date)
    }

    // MARK: - By room

    /// Completions grouped by room, busiest first.
    static func byRoom(_ logs: [CompletionLog]) -> [RoomPoint] {
        var grouped: [String: (count: Int, minutes: Int)] = [:]
        for log in logs {
            var e = grouped[log.roomName] ?? (0, 0)
            e.count += 1
            e.minutes += log.minutes
            grouped[log.roomName] = e
        }
        return grouped
            .map { RoomPoint(room: $0.key, count: $0.value.count, minutes: $0.value.minutes) }
            .sorted { $0.count > $1.count }
    }

    // MARK: - Summary

    static func summary(_ logs: [CompletionLog], now: Date = .now, calendar: Calendar = .current) -> Summary {
        let totalMinutes = logs.reduce(0) { $0 + $1.minutes }
        let rooms = Set(logs.map { $0.roomName })
        return Summary(totalCompletions: logs.count,
                       totalMinutes: totalMinutes,
                       currentStreak: streak(logs, now: now, calendar: calendar),
                       roomsTouched: rooms.count)
    }

    /// Consecutive days (ending today or yesterday) with at least one completion.
    static func streak(_ logs: [CompletionLog], now: Date = .now, calendar: Calendar = .current) -> Int {
        guard !logs.isEmpty else { return 0 }
        let days = Set(logs.map { calendar.startOfDay(for: $0.date) })
        var streak = 0
        var cursor = calendar.startOfDay(for: now)
        // Allow the streak to "start" yesterday if nothing logged yet today.
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
}
