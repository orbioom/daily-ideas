import Foundation

/// Pure engine — no SwiftData imports, no side effects.
/// All functions take plain arrays so they can be tested in isolation.
enum StreakEngine {

    // MARK: - Scheduling

    /// Returns true if the habit is scheduled on the given calendar day.
    static func isScheduled(_ habit: Habit, on day: Date, calendar: Calendar) -> Bool {
        switch habit.scheduleType {
        case .everyDay:
            return true
        case .specificDays:
            let weekday = calendar.component(.weekday, from: day) // 1=Sun … 7=Sat
            let bit = weekday - 1 // bit 0=Sun … bit 6=Sat
            return (habit.weekdayMask >> bit) & 1 == 1
        case .timesPerWeek:
            return true // any day is valid; completion judged per-week
        }
    }

    // MARK: - Completion

    /// Total count logged for a habit on a given day.
    static func count(for habit: Habit, on day: Date, entries: [HabitEntry], calendar: Calendar) -> Int {
        let start = calendar.startOfDay(for: day)
        return entries
            .filter { $0.habit?.id == habit.id && calendar.startOfDay(for: $0.day) == start }
            .reduce(0) { $0 + $1.count }
    }

    /// Returns true when the habit is considered "done" for that day.
    static func isComplete(_ habit: Habit, on day: Date, entries: [HabitEntry], calendar: Calendar) -> Bool {
        count(for: habit, on: day, entries: entries, calendar: calendar) >= habit.dailyTarget
    }

    // MARK: - Streaks (everyDay / specificDays)

    /// Consecutive scheduled+completed days ending at or before today.
    /// If today is scheduled but not yet complete, we don't break the streak —
    /// we simply stop counting today and let yesterday's streak stand.
    static func currentStreak(_ habit: Habit, entries: [HabitEntry], asOf today: Date, calendar: Calendar) -> Int {
        guard habit.scheduleType != .timesPerWeek else {
            return weeksStreak(habit, entries: entries, asOf: today, calendar: calendar)
        }

        let todayStart = calendar.startOfDay(for: today)
        var streak = 0
        var cursor = todayStart

        // Walk backwards until we find an unscheduled gap or an incomplete scheduled day
        while true {
            if isScheduled(habit, on: cursor, calendar: calendar) {
                if isComplete(habit, on: cursor, entries: entries, calendar: calendar) {
                    streak += 1
                } else if cursor == todayStart {
                    // Today incomplete — don't break streak yet, just skip today
                } else {
                    break
                }
            }
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            // Safety: don't walk past creation date
            if prev < calendar.startOfDay(for: habit.createdAt) { break }
            cursor = prev
        }
        return streak
    }

    /// Longest ever streak for everyDay/specificDays habits.
    static func longestStreak(_ habit: Habit, entries: [HabitEntry], calendar: Calendar) -> Int {
        guard habit.scheduleType != .timesPerWeek else {
            return longestWeeksStreak(habit, entries: entries, calendar: calendar)
        }

        let today = calendar.startOfDay(for: .now)
        var longest = 0
        var current = 0
        var cursor = calendar.startOfDay(for: habit.createdAt)

        while cursor <= today {
            if isScheduled(habit, on: cursor, calendar: calendar) {
                if isComplete(habit, on: cursor, entries: entries, calendar: calendar) {
                    current += 1
                    longest = max(longest, current)
                } else {
                    current = 0
                }
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return longest
    }

    // MARK: - Streaks (timesPerWeek)

    /// Consecutive weeks (ending this week) where target was met.
    static func weeksStreak(_ habit: Habit, entries: [HabitEntry], asOf today: Date, calendar: Calendar) -> Int {
        var streak = 0
        var weekStart = startOfWeek(for: today, calendar: calendar)

        for _ in 0..<520 { // guard against infinite loop (max 10 years)
            guard let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else { break }
            let done = daysCompleted(habit, entries: entries, from: weekStart, through: weekEnd, calendar: calendar)
            if done >= habit.timesPerWeekTarget {
                streak += 1
            } else if weekStart > calendar.startOfDay(for: today) {
                // Future week, skip
            } else {
                break
            }
            guard let prev = calendar.date(byAdding: .weekOfYear, value: -1, to: weekStart) else { break }
            if prev < calendar.startOfDay(for: habit.createdAt) { break }
            weekStart = prev
        }
        return streak
    }

    static func longestWeeksStreak(_ habit: Habit, entries: [HabitEntry], calendar: Calendar) -> Int {
        let today = calendar.startOfDay(for: .now)
        var longest = 0
        var current = 0
        var weekStart = startOfWeek(for: calendar.startOfDay(for: habit.createdAt), calendar: calendar)

        while weekStart <= today {
            guard let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else { break }
            let done = daysCompleted(habit, entries: entries, from: weekStart, through: weekEnd, calendar: calendar)
            if done >= habit.timesPerWeekTarget {
                current += 1
                longest = max(longest, current)
            } else {
                current = 0
            }
            guard let next = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart) else { break }
            weekStart = next
        }
        return longest
    }

    // MARK: - Weekly progress

    static func weeklyProgress(for habit: Habit, entries: [HabitEntry], weekOf date: Date, calendar: Calendar) -> (done: Int, target: Int) {
        let ws = startOfWeek(for: date, calendar: calendar)
        guard let we = calendar.date(byAdding: .day, value: 6, to: ws) else {
            return (0, habit.timesPerWeekTarget)
        }
        let done = daysCompleted(habit, entries: entries, from: ws, through: we, calendar: calendar)
        return (done, habit.timesPerWeekTarget)
    }

    // MARK: - Completion rate

    /// Fraction of scheduled days (in the last N days) where the habit was completed.
    static func completionRate(_ habit: Habit, entries: [HabitEntry], lastNDays n: Int, calendar: Calendar) -> Double {
        let today = calendar.startOfDay(for: .now)
        var scheduled = 0
        var completed = 0
        for offset in 0..<n {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            if isScheduled(habit, on: day, calendar: calendar) {
                scheduled += 1
                if isComplete(habit, on: day, entries: entries, calendar: calendar) {
                    completed += 1
                }
            }
        }
        guard scheduled > 0 else { return 0 }
        return Double(completed) / Double(scheduled)
    }

    // MARK: - Helpers

    private static func daysCompleted(_ habit: Habit, entries: [HabitEntry], from start: Date, through end: Date, calendar: Calendar) -> Int {
        var count = 0
        var cursor = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: end)
        while cursor <= endDay {
            if isComplete(habit, on: cursor, entries: entries, calendar: calendar) {
                count += 1
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return count
    }

    static func startOfWeek(for date: Date, calendar: Calendar) -> Date {
        let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: comps) ?? calendar.startOfDay(for: date)
    }

    /// Total completions across all time.
    static func totalCompletions(_ habit: Habit, entries: [HabitEntry], calendar: Calendar) -> Int {
        let today = calendar.startOfDay(for: .now)
        let start = calendar.startOfDay(for: habit.createdAt)
        var cursor = start
        var total = 0
        while cursor <= today {
            if isComplete(habit, on: cursor, entries: entries, calendar: calendar) {
                total += 1
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return total
    }
}
