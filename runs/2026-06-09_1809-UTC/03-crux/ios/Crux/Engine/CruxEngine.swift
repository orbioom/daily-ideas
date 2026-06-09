import Foundation

/// Pure, static task logic: recurrence date math, completion semantics, and
/// smart-list bucketing. No SwiftData here — callers pass in plain arrays and
/// the engine guards every edge (empty lists, zero intervals, missing dates).
enum CruxEngine {

    // MARK: - Calendar

    /// A calendar configured for a given first weekday (1 = Sunday … 2 = Monday).
    static func calendar(firstWeekday: Int = 2) -> Calendar {
        var cal = Calendar.current
        cal.firstWeekday = min(max(firstWeekday, 1), 7)
        return cal
    }

    // MARK: - Recurrence

    /// Next occurrence date strictly after `date` for the given rule.
    /// Returns nil for `.none`. Guards `interval >= 1` for `.everyN`.
    static func nextOccurrence(after date: Date,
                               recurrence: Recurrence,
                               interval: Int,
                               firstWeekday: Int = 2) -> Date? {
        let cal = calendar(firstWeekday: firstWeekday)
        switch recurrence {
        case .none:
            return nil
        case .daily:
            return cal.date(byAdding: .day, value: 1, to: date)
        case .weekdays:
            return nextWeekday(after: date, calendar: cal)
        case .weekly:
            return cal.date(byAdding: .day, value: 7, to: date)
        case .monthly:
            return cal.date(byAdding: .month, value: 1, to: date)
        case .yearly:
            return cal.date(byAdding: .year, value: 1, to: date)
        case .everyN:
            let step = max(1, interval)
            return cal.date(byAdding: .day, value: step, to: date)
        }
    }

    /// First Monday–Friday strictly after `date`.
    private static func nextWeekday(after date: Date, calendar cal: Calendar) -> Date? {
        var candidate = cal.date(byAdding: .day, value: 1, to: date)
        var guardCount = 0
        while let day = candidate, guardCount < 8 {
            let weekday = cal.component(.weekday, from: day)   // 1 = Sun … 7 = Sat
            if weekday != 1 && weekday != 7 { return day }
            candidate = cal.date(byAdding: .day, value: 1, to: day)
            guardCount += 1
        }
        return candidate
    }

    // MARK: - Completion

    /// Completion semantics. For a repeating task, instead of closing it we
    /// advance its scheduled/due dates to the next occurrence and keep it active
    /// (returns `.advanced`). For a one-off task we mark it done with a timestamp
    /// (returns `.completed`). The ViewModel applies the mutation to the model.
    enum CompletionResult: Equatable {
        case completed(at: Date)
        case advanced(scheduled: Date?, due: Date?)
    }

    /// Computes how completing `task` should mutate it. Pure — does not touch
    /// SwiftData. Pass `now` for testability.
    static func completion(for task: TaskItem,
                           now: Date = .now,
                           firstWeekday: Int = 2) -> CompletionResult {
        guard task.recurrence.isRepeating else {
            return .completed(at: now)
        }
        // Advance whichever dates are set off their current anchor.
        let interval = task.recurrenceInterval
        let nextScheduled = task.scheduledDate.flatMap {
            nextOccurrence(after: $0, recurrence: task.recurrence, interval: interval, firstWeekday: firstWeekday)
        }
        let nextDue = task.dueDate.flatMap {
            nextOccurrence(after: $0, recurrence: task.recurrence, interval: interval, firstWeekday: firstWeekday)
        }
        // If a recurring task has no dates at all, anchor it from `now`.
        if nextScheduled == nil && nextDue == nil {
            let fallback = nextOccurrence(after: now, recurrence: task.recurrence, interval: interval, firstWeekday: firstWeekday)
            return .advanced(scheduled: fallback, due: nil)
        }
        return .advanced(scheduled: nextScheduled, due: nextDue)
    }

    // MARK: - Date helpers

    static func startOfDay(_ date: Date, calendar cal: Calendar = .current) -> Date {
        cal.startOfDay(for: date)
    }

    static func endOfDay(_ date: Date, calendar cal: Calendar = .current) -> Date {
        let start = cal.startOfDay(for: date)
        return cal.date(byAdding: DateComponents(day: 1, second: -1), to: start) ?? start
    }

    // MARK: - Smart lists

    /// A named bucket of tasks for the smart lists.
    enum SmartList: String, CaseIterable, Identifiable {
        case today, overdue, upcoming, anytime, someday, logbook
        var id: String { rawValue }
    }

    /// Tasks due/scheduled today (or earlier) and not yet done. Excludes overdue
    /// (handled separately) by including anything with anchor <= end of today.
    static func today(_ tasks: [TaskItem], now: Date = .now, calendar cal: Calendar = .current) -> [TaskItem] {
        let end = endOfDay(now, calendar: cal)
        return tasks
            .filter { task in
                guard !task.isDone else { return false }
                let scheduledHit = task.scheduledDate.map { $0 <= end } ?? false
                let dueHit = task.dueDate.map { $0 <= end } ?? false
                return scheduledHit || dueHit
            }
            .sorted(by: ordering)
    }

    /// Tasks whose due date is before the start of today and not done.
    static func overdue(_ tasks: [TaskItem], now: Date = .now, calendar cal: Calendar = .current) -> [TaskItem] {
        let start = startOfDay(now, calendar: cal)
        return tasks
            .filter { task in
                guard !task.isDone, let due = task.dueDate else { return false }
                return due < start
            }
            .sorted(by: ordering)
    }

    /// A single day of upcoming tasks.
    struct UpcomingDay: Identifiable {
        let date: Date
        let tasks: [TaskItem]
        var id: Date { date }
    }

    /// Future scheduled/due tasks (after today), grouped by day and sorted.
    static func upcoming(_ tasks: [TaskItem], now: Date = .now, calendar cal: Calendar = .current) -> [UpcomingDay] {
        let end = endOfDay(now, calendar: cal)
        let future = tasks.filter { task in
            guard !task.isDone, !task.isSomeday, let anchor = task.anchorDate else { return false }
            return anchor > end
        }
        var groups: [Date: [TaskItem]] = [:]
        for task in future {
            guard let anchor = task.anchorDate else { continue }
            let day = startOfDay(anchor, calendar: cal)
            groups[day, default: []].append(task)
        }
        return groups
            .map { UpcomingDay(date: $0.key, tasks: $0.value.sorted(by: ordering)) }
            .sorted { $0.date < $1.date }
    }

    /// Not done, no dates, not someday — the "anytime" backlog.
    static func anytime(_ tasks: [TaskItem]) -> [TaskItem] {
        tasks
            .filter { !$0.isDone && $0.anchorDate == nil && !$0.isSomeday }
            .sorted(by: ordering)
    }

    /// Parked-for-later tasks.
    static func someday(_ tasks: [TaskItem]) -> [TaskItem] {
        tasks
            .filter { $0.isSomeday && !$0.isDone }
            .sorted(by: ordering)
    }

    /// Completed tasks, most recently finished first.
    static func logbook(_ tasks: [TaskItem]) -> [TaskItem] {
        tasks
            .filter { $0.isDone }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    /// Shared ordering: higher priority first, then earlier anchor date, then
    /// manual sortOrder, then creation date — deterministic and stable.
    static func ordering(_ a: TaskItem, _ b: TaskItem) -> Bool {
        if a.priority.rank != b.priority.rank {
            return a.priority.rank > b.priority.rank
        }
        let da = a.anchorDate ?? .distantFuture
        let db = b.anchorDate ?? .distantFuture
        if da != db { return da < db }
        if a.sortOrder != b.sortOrder { return a.sortOrder < b.sortOrder }
        return a.createdAt < b.createdAt
    }

    // MARK: - Counts

    /// Active-task counts per smart list, for badges in Browse.
    static func counts(_ tasks: [TaskItem], now: Date = .now, calendar cal: Calendar = .current) -> [SmartList: Int] {
        var result: [SmartList: Int] = [:]
        result[.today] = today(tasks, now: now, calendar: cal).count + overdue(tasks, now: now, calendar: cal).count
        result[.overdue] = overdue(tasks, now: now, calendar: cal).count
        result[.upcoming] = upcoming(tasks, now: now, calendar: cal).reduce(0) { $0 + $1.tasks.count }
        result[.anytime] = anytime(tasks).count
        result[.someday] = someday(tasks).count
        result[.logbook] = logbook(tasks).count
        return result
    }

    // MARK: - Completion chart data

    /// One bar in the "completed per day" chart.
    struct CompletionPoint: Identifiable {
        let date: Date
        let count: Int
        var id: Date { date }
    }

    /// Count of tasks completed on each of the last `days` calendar days,
    /// oldest first. Always returns exactly `days` points (zero-filled).
    static func completionsPerDay(_ tasks: [TaskItem],
                                  days: Int = 14,
                                  now: Date = .now,
                                  calendar cal: Calendar = .current) -> [CompletionPoint] {
        let span = max(1, days)
        let today = startOfDay(now, calendar: cal)
        var buckets: [Date: Int] = [:]
        for task in tasks where task.isDone {
            guard let completed = task.completedAt else { continue }
            let day = startOfDay(completed, calendar: cal)
            buckets[day, default: 0] += 1
        }
        var points: [CompletionPoint] = []
        for offset in stride(from: span - 1, through: 0, by: -1) {
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { continue }
            points.append(CompletionPoint(date: day, count: buckets[day] ?? 0))
        }
        return points
    }
}
