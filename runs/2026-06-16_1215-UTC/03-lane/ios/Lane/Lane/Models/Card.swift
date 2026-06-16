import Foundation
import SwiftData

@Model
final class Card {
    @Attribute(.unique) var id: UUID
    var title: String
    var notes: String
    var sortIndex: Int
    var dueDate: Date?
    var priorityRaw: String
    var createdDate: Date
    var completedDate: Date?

    var column: BoardColumn?

    @Relationship(deleteRule: .cascade, inverse: \ChecklistItem.card)
    var checklist: [ChecklistItem]

    @Relationship(inverse: \Label.cards)
    var labels: [Label]

    init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        sortIndex: Int,
        dueDate: Date? = nil,
        priority: Priority = .none,
        createdDate: Date = Date(),
        completedDate: Date? = nil,
        column: BoardColumn? = nil,
        checklist: [ChecklistItem] = [],
        labels: [Label] = []
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.sortIndex = sortIndex
        self.dueDate = dueDate
        self.priorityRaw = priority.rawValue
        self.createdDate = createdDate
        self.completedDate = completedDate
        self.column = column
        self.checklist = checklist
        self.labels = labels
    }

    var priority: Priority {
        get { Priority(rawValue: priorityRaw) ?? .none }
        set { priorityRaw = newValue.rawValue }
    }

    var orderedChecklist: [ChecklistItem] {
        checklist.sorted { $0.sortIndex < $1.sortIndex }
    }

    var isCompleted: Bool { completedDate != nil }

    /// Checklist completion fraction in 0...1. Guarded against division by zero.
    var checklistProgress: Double {
        guard !checklist.isEmpty else { return 0 }
        let done = checklist.filter { $0.isDone }.count
        return Double(done) / Double(checklist.count)
    }

    var checklistDoneCount: Int {
        checklist.filter { $0.isDone }.count
    }

    var isOverdue: Bool {
        guard let due = dueDate, !isCompleted else { return false }
        return DateUtils.isOverdue(due)
    }

    var isDueToday: Bool {
        guard let due = dueDate, !isCompleted else { return false }
        return DateUtils.isToday(due)
    }
}
