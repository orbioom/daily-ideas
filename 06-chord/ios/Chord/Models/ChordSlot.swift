import SwiftData
import Foundation

enum ChordQuality: String, CaseIterable, Codable {
    case major = "maj"
    case minor = "m"
    case dominant7 = "7"
    case major7 = "maj7"
    case minor7 = "m7"
    case diminished = "dim"
    case augmented = "aug"
    case sus2 = "sus2"
    case sus4 = "sus4"
    case add9 = "add9"
    case power = "5"

    var displayName: String {
        switch self {
        case .major: return "Major"
        case .minor: return "Minor"
        case .dominant7: return "Dom 7"
        case .major7: return "Major 7"
        case .minor7: return "Minor 7"
        case .diminished: return "Diminished"
        case .augmented: return "Augmented"
        case .sus2: return "Sus 2"
        case .sus4: return "Sus 4"
        case .add9: return "Add 9"
        case .power: return "Power"
        }
    }
}

enum BeatDuration: String, CaseIterable, Codable {
    case one = "1"
    case two = "2"
    case three = "3"
    case four = "4"

    var beats: Int {
        switch self {
        case .one: return 1
        case .two: return 2
        case .three: return 3
        case .four: return 4
        }
    }

    var displayName: String { "\(beats) beat\(beats == 1 ? "" : "s")" }
}

@Model
final class ChordSlot {
    var id: UUID
    var rootNote: String
    var quality: ChordQuality
    var duration: BeatDuration
    var position: Int
    var lyricHint: String

    init(rootNote: String, quality: ChordQuality = .major,
         duration: BeatDuration = .four, position: Int, lyricHint: String = "") {
        self.id = UUID()
        self.rootNote = rootNote
        self.quality = quality
        self.duration = duration
        self.position = position
        self.lyricHint = lyricHint
    }

    var chordName: String {
        quality == .major ? rootNote : "\(rootNote)\(quality.rawValue)"
    }

    var fullName: String {
        "\(rootNote) \(quality.displayName)"
    }
}
