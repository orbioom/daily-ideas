import Foundation
import SwiftUI
import SwiftData

/// Pure, static cleaning-rotation engine. No SwiftData or UIKit dependencies —
/// just date math over the model so it's trivially testable and never throws.
enum HearthEngine {

    // MARK: - Due status

    /// Where a task sits relative to its cadence. Ordered by urgency.
    enum DueStatus: Int, CaseIterable {
        case overdue
        case today
        case soon
        case ok

        var label: String {
            switch self {
            case .overdue: return "Overdue"
            case .today:   return "Due today"
            case .soon:    return "Due soon"
            case .ok:      return "Fresh"
            }
        }

        var color: Color {
            switch self {
            case .overdue: return Brand.danger
            case .today:   return Brand.warn
            case .soon:    return Brand.info
            case .ok:      return Brand.live
            }
        }

        /// Lower sorts first (more urgent).
        var sortRank: Int { rawValue }
    }

    // MARK: - Calendar helpers

    /// Whole calendar days between two dates (can be negative).
    static func daysBetween(_ from: Date, _ to: Date, calendar: Calendar = .current) -> Int {
        let a = calendar.startOfDay(for: from)
        let b = calendar.startOfDay(for: to)
        return calendar.dateComponents([.day], from: a, to: b).day ?? 0
    }

    // MARK: - Due dates

    /// The date a task is next due. Never-done tasks use `distantPast` as a base
    /// so they always read as overdue/today.
    static func nextDue(for task: CleaningTask, calendar: Calendar = .current) -> Date {
        let base = task.lastDone ?? Date.distantPast
        return calendar.date(byAdding: .day, value: max(1, task.frequencyDays), to: base) ?? base
    }

    /// Days a task is overdue (0 if not overdue). Never-done counts as overdue
    /// by its full cadence so it bubbles up.
    static func daysOverdue(for task: CleaningTask, now: Date = .now, calendar: Calendar = .current) -> Int {
        guard task.lastDone != nil else { return max(1, task.frequencyDays) }
        let due = nextDue(for: task, calendar: calendar)
        let diff = daysBetween(due, now, calendar: calendar)
        return max(0, diff)
    }

    /// The bucket a task falls into. `soon` = due within `soonWindowDays` days.
    static func status(for task: CleaningTask,
                       soonWindowDays: Int,
                       now: Date = .now,
                       calendar: Calendar = .current) -> DueStatus {
        // Never done → at least due today.
        if task.lastDone == nil { return .today }
        let due = nextDue(for: task, calendar: calendar)
        let days = daysBetween(now, due, calendar: calendar) // +ve = in the future
        if days < 0 { return .overdue }
        if days == 0 { return .today }
        if days <= max(1, soonWindowDays) { return .soon }
        return .ok
    }

    // MARK: - Freshness

    /// A task's freshness in 0…1. 1 = just done, decays linearly to 0 at one full
    /// cadence overdue. Never-done = 0.
    static func freshness(for task: CleaningTask, now: Date = .now, calendar: Calendar = .current) -> Double {
        guard let last = task.lastDone else { return 0 }
        let cadence = Double(max(1, task.frequencyDays))
        let elapsed = Double(max(0, daysBetween(last, now, calendar: calendar)))
        let value = 1.0 - (elapsed / cadence)
        return min(1, max(0, value))
    }

    /// A room's freshness = average over its active tasks. Empty (nothing to do)
    /// reads as perfectly fresh (1.0) rather than dividing by zero.
    static func roomFreshness(_ room: Room, now: Date = .now, calendar: Calendar = .current) -> Double {
        let active = room.activeTasks
        guard !active.isEmpty else { return 1.0 }
        let total = active.reduce(0.0) { $0 + freshness(for: $1, now: now, calendar: calendar) }
        return total / Double(active.count)
    }

    /// Whole-home cleanliness = average freshness across every active task in
    /// every room. No active tasks anywhere → 1.0.
    static func homeCleanliness(_ rooms: [Room], now: Date = .now, calendar: Calendar = .current) -> Double {
        let tasks = rooms.flatMap { $0.activeTasks }
        guard !tasks.isEmpty else { return 1.0 }
        let total = tasks.reduce(0.0) { $0 + freshness(for: $1, now: now, calendar: calendar) }
        return total / Double(tasks.count)
    }

    /// Count of active tasks in a room that are overdue or due today.
    static func dueCount(for room: Room, soonWindowDays: Int, now: Date = .now, calendar: Calendar = .current) -> Int {
        room.activeTasks.filter {
            let s = status(for: $0, soonWindowDays: soonWindowDays, now: now, calendar: calendar)
            return s == .overdue || s == .today
        }.count
    }

    // MARK: - Today

    /// An active task paired with its computed status, for the Today screen.
    struct DueItem: Identifiable {
        let task: CleaningTask
        let status: DueStatus
        var id: PersistentIdentifier { task.persistentModelID }
    }

    /// Overdue + due-today tasks (and "soon" if `includeSoon`), sorted by severity
    /// then by how overdue they are.
    static func todaysTasks(_ rooms: [Room],
                            soonWindowDays: Int,
                            includeSoon: Bool,
                            now: Date = .now,
                            calendar: Calendar = .current) -> [DueItem] {
        var items: [DueItem] = []
        for room in rooms {
            for task in room.activeTasks {
                let s = status(for: task, soonWindowDays: soonWindowDays, now: now, calendar: calendar)
                switch s {
                case .overdue, .today:
                    items.append(DueItem(task: task, status: s))
                case .soon where includeSoon:
                    items.append(DueItem(task: task, status: s))
                default:
                    break
                }
            }
        }
        return items.sorted { lhs, rhs in
            if lhs.status.sortRank != rhs.status.sortRank {
                return lhs.status.sortRank < rhs.status.sortRank
            }
            let lo = daysOverdue(for: lhs.task, now: now, calendar: calendar)
            let ro = daysOverdue(for: rhs.task, now: now, calendar: calendar)
            if lo != ro { return lo > ro }
            return lhs.task.name < rhs.task.name
        }
    }
}
