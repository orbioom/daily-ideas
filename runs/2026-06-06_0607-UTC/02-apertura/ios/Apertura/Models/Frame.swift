import Foundation
import SwiftData

/// A single exposure on a roll. Stores the chosen settings and computes EV from them
/// (using the roll's ISO via the owning relationship) on demand.
@Model
final class Frame {
    var id: UUID
    /// Frame number on the roll (1-based).
    var number: Int
    /// Aperture f-number. Always > 0 (guarded at the edit boundary).
    var aperture: Double
    /// Shutter time in seconds. Always > 0 (guarded at the edit boundary).
    var shutterSeconds: Double
    /// Focal length in millimetres. Always > 0.
    var focalLengthMM: Double
    var subject: String
    var location: String
    var notes: String
    var createdAt: Date

    var roll: Roll?

    init(id: UUID = UUID(),
         number: Int,
         aperture: Double = 8,
         shutterSeconds: Double = 1.0/250,
         focalLengthMM: Double = 50,
         subject: String = "",
         location: String = "",
         notes: String = "",
         createdAt: Date = .now) {
        self.id = id
        self.number = number
        self.aperture = max(0.5, aperture)
        self.shutterSeconds = max(1.0/16000, shutterSeconds)
        self.focalLengthMM = max(1, focalLengthMM)
        self.subject = subject
        self.location = location
        self.notes = notes
        self.createdAt = createdAt
    }

    /// ISO inherited from the owning roll (defaults to 100 if somehow detached).
    var effectiveISO: Double {
        let iso = roll?.iso ?? 100
        return iso > 0 ? iso : 100
    }

    /// Computed EV (at this roll's ISO). Nil only if inputs are degenerate.
    var ev: Double? {
        Exposure.ev(aperture: aperture, shutterSeconds: shutterSeconds, iso: effectiveISO)
    }

    /// EV normalized to ISO 100 (comparable across rolls of differing speed).
    var ev100: Double? {
        Exposure.ev100(aperture: aperture, shutterSeconds: shutterSeconds)
    }
}
