import Foundation
import SwiftData

/// A roll of film (or a digital session): the owning entity for an ordered set of Frames.
/// Carries the stock, rated ISO, format, and camera that contextualize every frame on it.
@Model
final class Roll {
    var id: UUID
    /// Film stock name, e.g. "Kodak Portra 400".
    var filmStock: String
    /// Rated ISO the roll is shot at. Always > 0 (guarded at the edit boundary).
    var iso: Double
    /// Raw value of FilmFormat for tolerant decoding.
    var formatRaw: String
    /// Camera body, e.g. "Nikon FE2".
    var camera: String
    var notes: String
    var createdAt: Date
    /// Whether the roll has been developed/finished.
    var isFinished: Bool

    /// Ordered frames. Cascade delete: removing the roll removes its frames.
    @Relationship(deleteRule: .cascade, inverse: \Frame.roll)
    var frames: [Frame]

    init(id: UUID = UUID(),
         filmStock: String,
         iso: Double = 400,
         format: FilmFormat = .format35mm,
         camera: String = "",
         notes: String = "",
         createdAt: Date = .now,
         isFinished: Bool = false) {
        self.id = id
        self.filmStock = filmStock
        self.iso = max(1, iso)
        self.formatRaw = format.rawValue
        self.camera = camera
        self.notes = notes
        self.createdAt = createdAt
        self.isFinished = isFinished
        self.frames = []
    }

    /// Tolerant accessor — falls back to 35mm for any unknown raw value.
    var format: FilmFormat {
        get { FilmFormat(rawValue: formatRaw) ?? .format35mm }
        set { formatRaw = newValue.rawValue }
    }

    /// Frames in shooting order (by frame number, then creation).
    var orderedFrames: [Frame] {
        frames.sorted {
            if $0.number != $1.number { return $0.number < $1.number }
            return $0.createdAt < $1.createdAt
        }
    }

    /// The next frame number to assign (1-based, contiguous against the max used).
    var nextFrameNumber: Int {
        (frames.map(\.number).max() ?? 0) + 1
    }
}
