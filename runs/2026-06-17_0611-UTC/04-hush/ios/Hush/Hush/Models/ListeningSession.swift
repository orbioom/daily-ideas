import Foundation
import SwiftData

/// A logged listening session, written when playback ends (manually or by the
/// sleep timer). Powers the Sessions / Stats screen.
@Model
final class ListeningSession {
    @Attribute(.unique) var id: UUID
    var startedAt: Date
    var durationSeconds: Int
    /// The name of the mix that was playing (a saved/preset name, or "Custom mix").
    var mixName: String
    /// The sound raw values that were active, for the "most-used sounds" stat.
    var soundRaws: [String]

    init(id: UUID = UUID(),
         startedAt: Date,
         durationSeconds: Int,
         mixName: String,
         soundRaws: [String]) {
        self.id = id
        self.startedAt = startedAt
        self.durationSeconds = max(0, durationSeconds)
        self.mixName = mixName
        self.soundRaws = soundRaws
    }

    /// The session's resolved sound types (skips any unknown raw values).
    var resolvedSounds: [SoundType] {
        soundRaws.compactMap { SoundType(rawValue: $0) }
    }
}
