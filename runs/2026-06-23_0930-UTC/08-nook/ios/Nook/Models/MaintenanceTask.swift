import Foundation
import SwiftData

@Model
final class MaintenanceTask {
    @Attribute(.unique) var id: UUID
    var title: String
    var detail: String
    var recurrenceRaw: String
    var nextDue: Date
    var lastCompleted: Date?
    var isActive: Bool
    var createdAt: Date
    var estimatedMinutes: Int

    var room: Room?
    var appliance: Appliance?

    /// History of completions. Cascade so logs are cleaned up with the task,
    /// but each log keeps its own copy of the date/cost so it survives edits.
    @Relationship(deleteRule: .cascade, inverse: \ServiceRecord.task)
    var records: [ServiceRecord]

    init(title: String,
         detail: String = "",
         recurrence: Recurrence,
         nextDue: Date,
         estimatedMinutes: Int = 15,
         isActive: Bool = true,
         room: Room? = nil,
         appliance: Appliance? = nil,
         createdAt: Date = .now) {
        self.id = UUID()
        self.title = title
        self.detail = detail
        self.recurrenceRaw = recurrence.rawValue
        self.nextDue = nextDue
        self.estimatedMinutes = max(0, estimatedMinutes)
        self.isActive = isActive
        self.lastCompleted = nil
        self.room = room
        self.appliance = appliance
        self.createdAt = createdAt
        self.records = []
    }

    var recurrence: Recurrence {
        get { Recurrence(rawValue: recurrenceRaw) ?? .annual }
        set { recurrenceRaw = newValue.rawValue }
    }

    /// Total amount logged across all service records for this task.
    var totalCost: Double {
        records.reduce(0) { $0 + $1.cost }
    }
}
