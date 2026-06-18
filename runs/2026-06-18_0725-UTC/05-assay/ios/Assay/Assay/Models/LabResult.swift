import Foundation
import SwiftData

/// A single recorded lab value. Results sharing a `panelId` came from the
/// same blood draw / panel. Stored in SwiftData and survives relaunch.
@Model
final class LabResult {
    @Attribute(.unique) var id: UUID
    var markerId: String
    var value: Double
    var unitRaw: String
    var drawDate: Date
    var panelId: String
    var labName: String
    var note: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        markerId: String,
        value: Double,
        unitRaw: String,
        drawDate: Date,
        panelId: String,
        labName: String,
        note: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.markerId = markerId
        self.value = value
        self.unitRaw = unitRaw
        self.drawDate = drawDate
        self.panelId = panelId
        self.labName = labName
        self.note = note
        self.createdAt = createdAt
    }

    /// The catalog marker this result refers to, if known.
    var marker: Biomarker? { BiomarkerCatalog.marker(markerId) }
}
