import Foundation
import SwiftData

/// Per-note running accuracy used for mastery-weighted selection and the heatmap.
/// `key` is "clefRaw:midi", e.g. "treble:64".
@Model
final class NoteStat {
    @Attribute(.unique) var key: String
    var seen: Int
    var correct: Int
    var lastSeen: Date

    init(key: String, seen: Int = 0, correct: Int = 0, lastSeen: Date = Date()) {
        self.key = key
        self.seen = max(0, seen)
        self.correct = max(0, correct)
        self.lastSeen = lastSeen
    }

    /// Mastery 0...1 (accuracy), guarded against divide-by-zero.
    var mastery: Double {
        guard seen > 0 else { return 0 }
        return Double(correct) / Double(seen)
    }

    /// Build the stable key for a clef + MIDI pair.
    static func makeKey(clef: Clef, midi: Int) -> String {
        "\(clef.rawValue):\(midi)"
    }

    /// Parse the MIDI back out of a key (nil if malformed).
    static func midi(fromKey key: String) -> Int? {
        guard let last = key.split(separator: ":").last else { return nil }
        return Int(last)
    }
}
