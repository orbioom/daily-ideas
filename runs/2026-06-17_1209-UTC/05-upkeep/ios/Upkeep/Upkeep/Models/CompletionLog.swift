import Foundation
import SwiftData

/// A record that a task was completed on a given date.
@Model
final class CompletionLog {
    @Attribute(.unique) var id: UUID
    var date: Date
    var costActual: Double?
    var minutesSpent: Int?
    var note: String

    var task: MaintenanceTask?

    init(date: Date = Date(),
         costActual: Double? = nil,
         minutesSpent: Int? = nil,
         note: String = "") {
        self.id = UUID()
        self.date = date
        self.costActual = costActual
        self.minutesSpent = minutesSpent
        self.note = note
    }
}
