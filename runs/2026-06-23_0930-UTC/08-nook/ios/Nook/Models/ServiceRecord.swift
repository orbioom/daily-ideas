import Foundation
import SwiftData

/// A single completion / service event for a task. Stores its own snapshot of
/// the date, cost and notes so history is stable even if the parent task changes.
@Model
final class ServiceRecord {
    @Attribute(.unique) var id: UUID
    var completedDate: Date
    var cost: Double
    var note: String
    var vendor: String

    var task: MaintenanceTask?

    init(completedDate: Date = .now,
         cost: Double = 0,
         note: String = "",
         vendor: String = "",
         task: MaintenanceTask? = nil) {
        self.id = UUID()
        self.completedDate = completedDate
        self.cost = max(0, cost)
        self.note = note
        self.vendor = vendor
        self.task = task
    }
}
