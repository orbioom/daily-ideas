import Foundation
import SwiftData

/// A single scheduled block on the day's timeline. `start` is a concrete
/// date+time; `durationMinutes` gives the length. Completion and an optional
/// checklist are owned here.
@Model
final class TimeBlock {
    var title: String
    var notes: String
    var start: Date
    var durationMinutes: Int
    var categoryRaw: String
    var isDone: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \ChecklistItem.block)
    var checklist: [ChecklistItem]

    init(title: String,
         start: Date,
         durationMinutes: Int = 60,
         category: BlockCategory = .work,
         notes: String = "",
         isDone: Bool = false) {
        self.title = title
        self.start = start
        self.durationMinutes = max(5, durationMinutes)
        self.categoryRaw = category.rawValue
        self.notes = notes
        self.isDone = isDone
        self.createdAt = .now
        self.checklist = []
    }

    var category: BlockCategory {
        get { BlockCategory(rawValue: categoryRaw) ?? .work }
        set { categoryRaw = newValue.rawValue }
    }

    var end: Date { start.addingTimeInterval(Double(durationMinutes) * 60) }

    var startMinuteOfDay: Int {
        let c = Calendar.current.dateComponents([.hour, .minute], from: start)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }

    var endMinuteOfDay: Int { startMinuteOfDay + durationMinutes }

    /// Fraction of the checklist that is complete (1 if there is no checklist).
    var checklistProgress: Double {
        guard !checklist.isEmpty else { return isDone ? 1 : 0 }
        let done = checklist.filter { $0.isDone }.count
        return Double(done) / Double(checklist.count)
    }
}
