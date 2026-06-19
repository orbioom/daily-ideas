import SwiftData
import Foundation

enum MusicalKey: String, CaseIterable, Codable {
    case cMajor = "C"
    case dMajor = "D"
    case eMajor = "E"
    case fMajor = "F"
    case gMajor = "G"
    case aMajor = "A"
    case bMajor = "B"
    case dbMajor = "Db"
    case ebMajor = "Eb"
    case abMajor = "Ab"
    case bbMajor = "Bb"
    case fsMajor = "F#"
    case aMinor = "Am"
    case dMinor = "Dm"
    case eMinor = "Em"
    case bMinor = "Bm"

    var displayName: String { rawValue }
    var isMinor: Bool { rawValue.hasSuffix("m") }
}

enum ProgressionGenre: String, CaseIterable, Codable {
    case pop = "Pop"
    case rock = "Rock"
    case folk = "Folk"
    case jazz = "Jazz"
    case blues = "Blues"
    case country = "Country"
    case rnb = "R&B"
    case other = "Other"

    var icon: String {
        switch self {
        case .pop: return "music.note"
        case .rock: return "guitars.fill"
        case .folk: return "leaf.fill"
        case .jazz: return "music.quarternote.3"
        case .blues: return "cloud.rain.fill"
        case .country: return "star.fill"
        case .rnb: return "waveform"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

@Model
final class Progression {
    var id: UUID
    var title: String
    var keyName: String
    var genre: ProgressionGenre
    var tempo: Int
    var notes: String
    var isFavorite: Bool
    var createdDate: Date
    var modifiedDate: Date
    @Relationship(deleteRule: .cascade) var chords: [ChordSlot]

    init(title: String, keyName: String = "C", genre: ProgressionGenre = .pop,
         tempo: Int = 120, notes: String = "", isFavorite: Bool = false) {
        self.id = UUID()
        self.title = title
        self.keyName = keyName
        self.genre = genre
        self.tempo = tempo
        self.notes = notes
        self.isFavorite = isFavorite
        self.createdDate = Date()
        self.modifiedDate = Date()
        self.chords = []
    }

    var sortedChords: [ChordSlot] {
        chords.sorted { $0.position < $1.position }
    }

    var chordSummary: String {
        sortedChords.map { $0.chordName }.joined(separator: " → ")
    }
}
