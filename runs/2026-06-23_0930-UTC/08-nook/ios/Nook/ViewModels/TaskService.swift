import Foundation
import SwiftData

/// Mutating operations on tasks. Centralised so the mark-done recurrence logic
/// lives in exactly one place.
@MainActor
enum TaskService {

    /// Marks a task complete: logs a ServiceRecord and advances the next-due
    /// date (or deactivates a one-time task). Returns the new record so the
    /// caller can offer to edit cost/notes.
    @discardableResult
    static func complete(_ task: MaintenanceTask,
                         on date: Date = .now,
                         cost: Double = 0,
                         note: String = "",
                         vendor: String = "",
                         context: ModelContext) -> ServiceRecord {
        let record = ServiceRecord(completedDate: date,
                                   cost: max(0, cost),
                                   note: note,
                                   vendor: vendor,
                                   task: task)
        context.insert(record)
        task.lastCompleted = date

        if let next = ScheduleEngine.advancedDueDate(for: task, completedOn: date) {
            task.nextDue = next
        } else {
            // One-time task: nothing more to do, mark inactive.
            task.isActive = false
        }
        try? context.save()
        return record
    }

    /// Snooze a task by a number of days from its current due date.
    static func snooze(_ task: MaintenanceTask, days: Int, context: ModelContext) {
        let cal = Calendar.current
        let base = max(cal.startOfDay(for: .now), cal.startOfDay(for: task.nextDue))
        if let newDate = cal.date(byAdding: .day, value: max(1, days), to: base) {
            task.nextDue = newDate
            try? context.save()
        }
    }

    static func delete(_ task: MaintenanceTask, context: ModelContext) {
        context.delete(task)
        try? context.save()
    }

    static func delete(_ record: ServiceRecord, context: ModelContext) {
        context.delete(record)
        try? context.save()
    }
}
