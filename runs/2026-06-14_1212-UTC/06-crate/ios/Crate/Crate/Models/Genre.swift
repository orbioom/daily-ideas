import SwiftUI

/// Musical genre. Stored as rawValue (`genreRaw`) on the model.
enum Genre: String, Codable, CaseIterable, Identifiable {
    case rock = "Rock"
    case jazz = "Jazz"
    case soul = "Soul"
    case funk = "Funk"
    case hiphop = "Hip-Hop"
    case electronic = "Electronic"
    case pop = "Pop"
    case folk = "Folk"
    case classical = "Classical"
    case blues = "Blues"
    case reggae = "Reggae"
    case country = "Country"
    case metal = "Metal"
    case punk = "Punk"
    case world = "World"
    case soundtrack = "Soundtrack"
    case other = "Other"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .rock: return "guitars"
        case .jazz: return "music.quarternote.3"
        case .soul: return "heart"
        case .funk: return "waveform.path"
        case .hiphop: return "mic"
        case .electronic: return "waveform"
        case .pop: return "star"
        case .folk: return "leaf"
        case .classical: return "pianokeys"
        case .blues: return "drop"
        case .reggae: return "sun.max"
        case .country: return "hare"
        case .metal: return "bolt"
        case .punk: return "flame"
        case .world: return "globe"
        case .soundtrack: return "film"
        case .other: return "music.note"
        }
    }

    /// Hue used for chips and chart series. Returns a dynamic color.
    var hue: Color {
        switch self {
        case .rock: return Color.dyn(0xB23A2E, 0xE07A6C)
        case .jazz: return Color.dyn(0x6C4A8C, 0xA988C9)
        case .soul: return Color.dyn(0xB5302E, 0xE36F6C)
        case .funk: return Color.dyn(0xC9701B, 0xE6A45A)
        case .hiphop: return Color.dyn(0x3A6EA5, 0x7BA7D8)
        case .electronic: return Color.dyn(0x2E8C8C, 0x6CC6C6)
        case .pop: return Color.dyn(0xB56A86, 0xDD9CB2)
        case .folk: return Color.dyn(0x3E8E5A, 0x73C794)
        case .classical: return Color.dyn(0x8A6A2B, 0xC7A361)
        case .blues: return Color.dyn(0x2F77A8, 0x6FAAD6)
        case .reggae: return Color.dyn(0x3F8E72, 0x77C5AC)
        case .country: return Color.dyn(0xB07A1E, 0xD9AC52)
        case .metal: return Color.dyn(0x4A4A52, 0x9A9AA6)
        case .punk: return Color.dyn(0xC23E2A, 0xE57C6A)
        case .world: return Color.dyn(0x2E8C8C, 0x6CC6C6)
        case .soundtrack: return Color.dyn(0x9A4458, 0xD98AA0)
        case .other: return Color.dyn(0x6E5A50, 0xB29C90)
        }
    }

    /// A deterministic 0...1 cover hue seed for this genre, used when none stored.
    var coverHueSeed: Double {
        guard let idx = Genre.allCases.firstIndex(of: self) else { return 0.08 }
        return Double(idx) / Double(max(Genre.allCases.count, 1))
    }
}
