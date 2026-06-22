import Foundation
import SwiftData

@Model
final class RitualCompletion {
    var id: UUID
    var date: Date
    var templateId: String
    var notes: String
    var moonPhaseRaw: String

    init(date: Date = .now, templateId: String, notes: String = "", moonPhaseRaw: String = "") {
        self.id = UUID()
        self.date = date
        self.templateId = templateId
        self.notes = notes
        self.moonPhaseRaw = moonPhaseRaw
    }
}
