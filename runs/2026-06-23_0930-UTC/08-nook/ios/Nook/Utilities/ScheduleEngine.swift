import Foundation

/// Pure, testable logic for due-date math and home-health scoring.
/// No SwiftData / SwiftUI dependencies so it is trivial to reason about.
enum ScheduleEngine {

    /// Number of whole days from `today` until `due` (negative = overdue).
    static func daysUntil(_ due: Date, from today: Date = .now, calendar: Calendar = .current) -> Int {
        let a = calendar.startOfDay(for: today)
        let b = calendar.startOfDay(for: due)
        return calendar.dateComponents([.day], from: a, to: b).day ?? 0
    }

    /// Classify a task into a due bucket.
    static func status(for task: MaintenanceTask,
                       today: Date = .now,
                       dueSoonWindow: Int = 14,
                       calendar: Calendar = .current) -> DueStatus {
        guard task.isActive else { return .inactive }
        let days = daysUntil(task.nextDue, from: today, calendar: calendar)
        if days < 0 { return .overdue }
        if days == 0 { return .dueToday }
        if days <= max(1, dueSoonWindow) { return .dueSoon }
        return .upcoming
    }

    /// Computes the next due date when a task is marked done.
    /// One-time tasks become inactive (no further recurrence).
    /// Recurring tasks advance from the *later* of today or the current due date,
    /// so a long-overdue task does not pile up multiple missed cycles.
    static func advancedDueDate(for task: MaintenanceTask,
                                completedOn date: Date = .now,
                                calendar: Calendar = .current) -> Date? {
        guard task.recurrence != .oneTime else { return nil }
        let base = max(calendar.startOfDay(for: date), calendar.startOfDay(for: task.nextDue))
        return task.recurrence.nextDate(after: base, calendar: calendar)
    }

    /// A 0...100 home-health score: share of active tasks that are not overdue,
    /// weighted so overdue tasks hurt more than due-soon ones. Division guarded.
    static func homeHealth(tasks: [MaintenanceTask],
                           today: Date = .now,
                           dueSoonWindow: Int = 14) -> Int {
        let active = tasks.filter { $0.isActive }
        guard !active.isEmpty else { return 100 }
        var score = 0.0
        for t in active {
            switch status(for: t, today: today, dueSoonWindow: dueSoonWindow) {
            case .overdue:  score += 0.0
            case .dueToday: score += 0.6
            case .dueSoon:  score += 0.85
            case .upcoming: score += 1.0
            case .inactive: score += 1.0
            }
        }
        let pct = (score / Double(active.count)) * 100.0
        return Int(pct.rounded())
    }

    /// Relative human label for a due date, e.g. "3 days overdue", "Due in 5 days".
    static func relativeLabel(for due: Date, today: Date = .now, calendar: Calendar = .current) -> String {
        let days = daysUntil(due, from: today, calendar: calendar)
        if days < -1 { return "\(-days) days overdue" }
        if days == -1 { return "1 day overdue" }
        if days == 0 { return "Due today" }
        if days == 1 { return "Due tomorrow" }
        return "Due in \(days) days"
    }
}
