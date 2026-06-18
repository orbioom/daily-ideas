import Foundation
import SwiftData

/// A user-defined marker (Pro feature). Lets people track labs Assay's
/// built-in catalog doesn't include. Ranges are user-supplied and optional.
@Model
final class CustomMarker {
    @Attribute(.unique) var id: UUID
    var name: String
    var unit: String
    var rangeLow: Double?
    var rangeHigh: Double?
    var note: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        unit: String,
        rangeLow: Double? = nil,
        rangeHigh: Double? = nil,
        note: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.unit = unit
        self.rangeLow = rangeLow
        self.rangeHigh = rangeHigh
        self.note = note
        self.createdAt = createdAt
    }

    /// Catalog id used to link `LabResult`s to a custom marker.
    var catalogId: String { "custom:\(id.uuidString)" }
}
