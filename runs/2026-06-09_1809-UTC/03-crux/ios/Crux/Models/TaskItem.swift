import Foundation
import SwiftData

/// A single task. The heart of Crux. A task can be scheduled (when it surfaces
/// in Today), have a due date (a hard deadline), repeat on a recurrence rule,
/// belong to a project, carry tags, and own an ordered list of subtasks.
@Model
final class TaskItem {
    var title: String
    var notes: String
    var isDone: Bool
    var completedAt: Date?
    var dueDate: Date?
    var scheduledDate: Date?
    var priorityRaw: String
    var recurrenceRaw: String
    var recurrenceInterval: Int     // used by `.everyN`; always >= 1
    var isSomeday: Bool
    var sortOrder: Int
    var createdAt: Date

    // A task belongs to at most one project; deleting the project nullifies this.
    var project: Project?

    // Many-to-many with tags (inverse declared here so SwiftData links cleanly).
    @Relationship(inverse: \Tag.tasks) var tags: [Tag] = []

    // Subtasks are owned by the task and removed with it.
    @Relationship(deleteRule: .cascade, inverse: \Subtask.task) var subtasks: [Subtask] = []

    init(title: String,
         notes: String = "",
         isDone: Bool = false,
         completedAt: Date? = nil,
         dueDate: Date? = nil,
         scheduledDate: Date? = nil,
         priority: Priority = .none,
         recurrence: Recurrence = .none,
         recurrenceInterval: Int = 1,
         isSomeday: Bool = false,
         sortOrder: Int = 0,
         createdAt: Date = .now) {
        self.title = title
        self.notes = notes
        self.isDone = isDone
        self.completedAt = completedAt
        self.dueDate = dueDate
        self.scheduledDate = scheduledDate
        self.priorityRaw = priority.rawValue
        self.recurrenceRaw = recurrence.rawValue
        self.recurrenceInterval = max(1, recurrenceInterval)
        self.isSomeday = isSomeday
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }

    var priority: Priority {
        get { Priority(rawValue: priorityRaw) ?? .none }
        set { priorityRaw = newValue.rawValue }
    }

    var recurrence: Recurrence {
        get { Recurrence(rawValue: recurrenceRaw) ?? .none }
        set { recurrenceRaw = newValue.rawValue }
    }

    /// Anchor date used by the recurrence engine and Upcoming grouping:
    /// scheduled first, then due.
    var anchorDate: Date? { scheduledDate ?? dueDate }

    var subtaskProgress: (done: Int, total: Int) {
        let total = subtasks.count
        let done = subtasks.filter { $0.isDone }.count
        return (done, total)
    }
}
