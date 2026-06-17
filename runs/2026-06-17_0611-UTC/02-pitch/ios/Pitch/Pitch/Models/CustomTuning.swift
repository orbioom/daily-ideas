import Foundation
import SwiftData

/// A user-created custom tuning (Pro feature). Persisted in SwiftData.
@Model
final class CustomTuning {
    /// Stable identifier used by the picker.
    var uuid: String
    var name: String
    /// Instrument family, stored as its rawValue string.
    var instrumentRaw: String
    /// Ordered note tokens, low → high, e.g. ["D2","A2",...].
    var notes: [String]
    var createdAt: Date

    init(name: String,
         instrument: InstrumentKind,
         notes: [String],
         createdAt: Date = .now) {
        self.uuid = UUID().uuidString
        self.name = name
        self.instrumentRaw = instrument.rawValue
        self.notes = notes
        self.createdAt = createdAt
    }

    /// Resolved instrument family (falls back to chromatic for unknown values).
    var instrument: InstrumentKind {
        InstrumentKind(rawValue: instrumentRaw) ?? .chromatic
    }

    /// Convert to the value-type `Tuning` used by the tuner engine.
    var asTuning: Tuning {
        Tuning(id: "custom-\(uuid)",
               name: name,
               instrument: instrument,
               targets: notes,
               isCustom: true)
    }
}
