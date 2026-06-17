import Foundation

/// A family of instrument a tuning belongs to. Used for grouping & icons.
enum InstrumentKind: String, CaseIterable, Codable, Identifiable {
    case guitar = "Guitar"
    case bass = "Bass"
    case ukulele = "Ukulele"
    case violin = "Violin"
    case cello = "Cello"
    case chromatic = "Chromatic"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .guitar:    return "guitars"
        case .bass:      return "guitars.fill"
        case .ukulele:   return "music.note"
        case .violin:    return "music.quarternote.3"
        case .cello:     return "music.quarternote.3"
        case .chromatic: return "pianokeys"
        }
    }
}

/// A tuning: an ordered list of target notes (low → high). For chromatic tuning
/// the target list is empty and the tuner free-detects the nearest note.
struct Tuning: Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let instrument: InstrumentKind
    /// Ordered note tokens, e.g. ["E2","A2","D3","G3","B3","E4"]. Empty == chromatic.
    let targets: [String]
    /// True for user-created custom tunings.
    let isCustom: Bool

    init(id: String, name: String, instrument: InstrumentKind, targets: [String], isCustom: Bool = false) {
        self.id = id
        self.name = name
        self.instrument = instrument
        self.targets = targets
        self.isCustom = isCustom
    }

    var isChromatic: Bool { targets.isEmpty }
}

/// Built-in tuning presets. Pure data, available on the free tier.
enum TuningCatalog {
    static let all: [Tuning] = [
        Tuning(id: "guitar-standard", name: "Guitar · Standard", instrument: .guitar,
               targets: ["E2", "A2", "D3", "G3", "B3", "E4"]),
        Tuning(id: "guitar-dropd", name: "Guitar · Drop D", instrument: .guitar,
               targets: ["D2", "A2", "D3", "G3", "B3", "E4"]),
        Tuning(id: "guitar-dadgad", name: "Guitar · DADGAD", instrument: .guitar,
               targets: ["D2", "A2", "D3", "G3", "A3", "D4"]),
        Tuning(id: "guitar-halfstep", name: "Guitar · Half-step Down", instrument: .guitar,
               targets: ["D♯2", "G♯2", "C♯3", "F♯3", "A♯3", "D♯4"]),
        Tuning(id: "bass-4", name: "Bass · 4-string", instrument: .bass,
               targets: ["E1", "A1", "D2", "G2"]),
        Tuning(id: "bass-5", name: "Bass · 5-string", instrument: .bass,
               targets: ["B0", "E1", "A1", "D2", "G2"]),
        Tuning(id: "ukulele-gcea", name: "Ukulele · GCEA", instrument: .ukulele,
               targets: ["G4", "C4", "E4", "A4"]),
        Tuning(id: "violin-gdae", name: "Violin · GDAE", instrument: .violin,
               targets: ["G3", "D4", "A4", "E5"]),
        Tuning(id: "cello-cgda", name: "Cello · CGDA", instrument: .cello,
               targets: ["C2", "G2", "D3", "A3"]),
        Tuning(id: "chromatic", name: "Chromatic", instrument: .chromatic,
               targets: [])
    ]

    /// The default active tuning on first launch.
    static let defaultID = "guitar-standard"

    static func byID(_ id: String) -> Tuning? {
        all.first { $0.id == id }
    }
}
