import Foundation

/// Which urgency bucket a task falls into.
enum DueBucket: String, CaseIterable, Identifiable {
    case overdue
    case dueToday
    case dueSoon
    case later

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overdue: return "Overdue"
        case .dueToday: return "Due today"
        case .dueSoon: return "Due soon"
        case .later: return "Later"
        }
    }

    var symbol: String {
        switch self {
        case .overdue: return "exclamationmark.triangle.fill"
        case .dueToday: return "clock.fill"
        case .dueSoon: return "calendar.badge.clock"
        case .later: return "checkmark.circle"
        }
    }
}

/// Pure scheduling math. No SwiftData, no UI.
enum ScheduleEngine {

    /// The next due date for a task, given the calendar and seasonal settings.
    /// Returns `nil` only when a seasonal task has no season set (treated as never due).
    static func nextDue(for task: MaintenanceTask,
                        hemisphere: Hemisphere,
                        now: Date = Date(),
                        calendar: Calendar = .current) -> Date? {
        // A task that has never been done is due now.
        let anchor = task.lastDone ?? now

        switch task.cadenceType {
        case .everyNDays:
            return calendar.date(byAdding: .day, value: max(1, task.intervalCount), to: anchor)
        case .everyNWeeks:
            return calendar.date(byAdding: .day, value: max(1, task.intervalCount) * 7, to: anchor)
        case .everyNMonths:
            return calendar.date(byAdding: .month, value: max(1, task.intervalCount), to: anchor)
        case .everyNYears:
            return calendar.date(byAdding: .year, value: max(1, task.intervalCount), to: anchor)
        case .seasonal:
            guard let season = task.season else { return nil }
            return nextSeasonStart(season: season,
                                   after: task.lastDone,
                                   hemisphere: hemisphere,
                                   now: now,
                                   calendar: calendar)
        }
    }

    /// The next start date of the given season strictly relevant to scheduling.
    /// If the task was done after this year's season start, the next occurrence is next year.
    static func nextSeasonStart(season: Season,
                                after lastDone: Date?,
                                hemisphere: Hemisphere,
                                now: Date = Date(),
                                calendar: Calendar = .current) -> Date {
        let month = hemisphere.startMonth(for: season)
        let reference = lastDone ?? now
        let refYear = calendar.component(.year, from: reference)

        var components = DateComponents()
        components.day = 1
        components.month = month

        // Candidate in the reference year.
        components.year = refYear
        let thisYear = calendar.date(from: components) ?? reference

        // If the season start in the reference year is on/before the reference date,
        // the next occurrence is next year.
        if thisYear > reference {
            return thisYear
        } else {
            components.year = refYear + 1
            return calendar.date(from: components) ?? thisYear
        }
    }

    /// Bucket a task by its next due date relative to `now` and the due-soon window (days).
    static func bucket(for task: MaintenanceTask,
                       hemisphere: Hemisphere,
                       dueSoonDays: Int,
                       now: Date = Date(),
                       calendar: Calendar = .current) -> DueBucket {
        guard let due = nextDue(for: task, hemisphere: hemisphere, now: now, calendar: calendar) else {
            return .later
        }
        let startOfToday = calendar.startOfDay(for: now)
        let dueDay = calendar.startOfDay(for: due)

        if dueDay < startOfToday { return .overdue }
        if dueDay == startOfToday { return .dueToday }

        let window = max(0, dueSoonDays)
        if let soonEdge = calendar.date(byAdding: .day, value: window, to: startOfToday),
           dueDay <= soonEdge {
            return .dueSoon
        }
        return .later
    }

    /// Days until due (negative = overdue). `nil` for unscheduled seasonal tasks.
    static func daysUntilDue(for task: MaintenanceTask,
                             hemisphere: Hemisphere,
                             now: Date = Date(),
                             calendar: Calendar = .current) -> Int? {
        guard let due = nextDue(for: task, hemisphere: hemisphere, now: now, calendar: calendar) else {
            return nil
        }
        let from = calendar.startOfDay(for: now)
        let to = calendar.startOfDay(for: due)
        return calendar.dateComponents([.day], from: from, to: to).day
    }

    /// Length of the task's interval in days, used for the freshness ratio.
    static func intervalDays(for task: MaintenanceTask) -> Int {
        switch task.cadenceType {
        case .everyNDays: return max(1, task.intervalCount)
        case .everyNWeeks: return max(1, task.intervalCount) * 7
        case .everyNMonths: return max(1, task.intervalCount) * 30
        case .everyNYears: return max(1, task.intervalCount) * 365
        case .seasonal: return 365
        }
    }

    /// 0 = just done, 1 = exactly at the interval, >1 = overdue.
    /// Clamped to 0...1 for gauges that expect a bounded value.
    static func freshness(for task: MaintenanceTask,
                          now: Date = Date(),
                          calendar: Calendar = .current) -> Double {
        guard let lastDone = task.lastDone else { return 1.0 } // never done = fully "spent"
        let interval = Double(intervalDays(for: task))
        guard interval > 0 else { return 1.0 }
        let elapsed = now.timeIntervalSince(lastDone) / 86_400.0
        let ratio = elapsed / interval
        return min(max(ratio, 0), 1)
    }

    /// Home-health score 0...100: priority-weighted share of active tasks NOT overdue.
    /// Returns 100 when there are no active tasks.
    static func homeHealth(tasks: [MaintenanceTask],
                           hemisphere: Hemisphere,
                           dueSoonDays: Int,
                           now: Date = Date(),
                           calendar: Calendar = .current) -> Double {
        let active = tasks.filter { $0.isActive }
        guard !active.isEmpty else { return 100 }

        // Higher priority (1) carries more weight.
        func weight(_ priority: Int) -> Double {
            switch priority {
            case 1: return 3
            case 3: return 1
            default: return 2
            }
        }

        var totalWeight = 0.0
        var healthyWeight = 0.0
        for task in active {
            let w = weight(task.priority)
            totalWeight += w
            let b = bucket(for: task,
                           hemisphere: hemisphere,
                           dueSoonDays: dueSoonDays,
                           now: now,
                           calendar: calendar)
            if b != .overdue { healthyWeight += w }
        }
        guard totalWeight > 0 else { return 100 }
        return (healthyWeight / totalWeight) * 100
    }
}
