import Foundation
import SwiftData

/// A saved metronome configuration. Persisted in SwiftData.
@Model
final class MetronomePreset {
    var uuid: String
    var name: String
    var bpm: Int
    var timeSigTop: Int
    var timeSigBottom: Int
    /// Subdivision stored as its rawValue Int.
    var subdivisionRaw: Int
    var accentFirst: Bool
    var createdAt: Date

    init(name: String,
         bpm: Int,
         timeSigTop: Int,
         timeSigBottom: Int,
         subdivision: Subdivision,
         accentFirst: Bool,
         createdAt: Date = .now) {
        self.uuid = UUID().uuidString
        self.name = name
        self.bpm = bpm
        self.timeSigTop = timeSigTop
        self.timeSigBottom = timeSigBottom
        self.subdivisionRaw = subdivision.rawValue
        self.accentFirst = accentFirst
        self.createdAt = createdAt
    }

    var subdivision: Subdivision { Subdivision(rawValue: subdivisionRaw) ?? .quarter }
    var timeSignature: TimeSignature { TimeSignature(top: timeSigTop, bottom: timeSigBottom) }
}
