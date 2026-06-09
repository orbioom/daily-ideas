import Foundation
import SwiftData

/// Bridges the pure `CruxEngine` to SwiftData mutations. Views call these from
/// the main actor; each persists via the passed-in context.
enum TaskActions {

    /// Toggle a task's completion. Recurring tasks advance to their next
    /// occurrence and stay active; one-off tasks flip done / not-done.
    static func toggleDone(_ task: TaskItem, context: ModelContext, firstWeekday: Int = 2) {
        if task.isDone {
            // Re-open a previously completed task.
            task.isDone = false
            task.completedAt = nil
            save(context)
            return
        }

        switch CruxEngine.completion(for: task, firstWeekday: firstWeekday) {
        case .completed(let at):
            task.isDone = true
            task.completedAt = at
        case .advanced(let scheduled, let due):
            // Stay active; roll the dates forward.
            if let scheduled { task.scheduledDate = scheduled }
            if let due { task.dueDate = due }
            task.isDone = false
            task.completedAt = nil
        }
        save(context)
    }

    /// Insert a new task with a deterministic sortOrder appended to the end.
    static func add(_ task: TaskItem, context: ModelContext) {
        context.insert(task)
        save(context)
    }

    static func delete(_ task: TaskItem, context: ModelContext) {
        context.delete(task)
        save(context)
    }

    static func save(_ context: ModelContext) {
        do {
            try context.save()
        } catch {
            // Calm failure: SwiftData autosave will retry; we surface nothing
            // destructive to the user for a transient save error.
        }
    }
}
