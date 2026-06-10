import Foundation
import SwiftData

/// A custom tuning the user defined (instrument + ordered target notes).
@Model
final class CustomTuning {
    var id: UUID
    var name: String
    var instrumentRaw: String
    var noteNames: [String]     // e.g. ["E2","A2","D3","G3","B3","E4"]
    var createdAt: Date

    init(name: String, instrument: InstrumentKind, noteNames: [String]) {
        self.id = UUID()
        self.name = name
        self.instrumentRaw = instrument.rawValue
        self.noteNames = noteNames
        self.createdAt = .now
    }

    var instrument: InstrumentKind { InstrumentKind(rawValue: instrumentRaw) ?? .guitar }
}

/// A saved metronome configuration.
@Model
final class MetronomePreset {
    var id: UUID
    var name: String
    var bpm: Int
    var beatsPerBar: Int
    var subdivision: Int        // 1 = quarter, 2 = eighths, 3 = triplets, 4 = sixteenths
    var accentFirst: Bool
    var createdAt: Date

    init(name: String, bpm: Int, beatsPerBar: Int = 4, subdivision: Int = 1, accentFirst: Bool = true) {
        self.id = UUID()
        self.name = name
        self.bpm = bpm
        self.beatsPerBar = beatsPerBar
        self.subdivision = subdivision
        self.accentFirst = accentFirst
        self.createdAt = .now
    }
}

enum InstrumentKind: String, CaseIterable, Identifiable, Codable {
    case guitar = "Guitar"
    case bass = "Bass"
    case ukulele = "Ukulele"
    case violin = "Violin"
    case cello = "Cello"
    case chromatic = "Chromatic"

    var id: String { rawValue }
    var icon: String {
        switch self {
        case .guitar, .bass: return "guitars.fill"
        case .ukulele: return "guitars"
        case .violin, .cello: return "music.quarternote.3"
        case .chromatic: return "tuningfork"
        }
    }
}

/// A built-in tuning preset (instrument + ordered notes), used as defaults.
struct TuningPreset: Identifiable, Hashable {
    let id: String
    let name: String
    let instrument: InstrumentKind
    let notes: [String]   // empty for chromatic (free)

    static let all: [TuningPreset] = [
        TuningPreset(id: "guitar-standard", name: "Standard", instrument: .guitar,
                     notes: ["E2","A2","D3","G3","B3","E4"]),
        TuningPreset(id: "guitar-dropd", name: "Drop D", instrument: .guitar,
                     notes: ["D2","A2","D3","G3","B3","E4"]),
        TuningPreset(id: "guitar-dadgad", name: "DADGAD", instrument: .guitar,
                     notes: ["D2","A2","D3","G3","A3","D4"]),
        TuningPreset(id: "bass-standard", name: "Standard", instrument: .bass,
                     notes: ["E1","A1","D2","G2"]),
        TuningPreset(id: "bass-5", name: "5-String", instrument: .bass,
                     notes: ["B0","E1","A1","D2","G2"]),
        TuningPreset(id: "uke-standard", name: "Standard (GCEA)", instrument: .ukulele,
                     notes: ["G4","C4","E4","A4"]),
        TuningPreset(id: "violin", name: "Standard", instrument: .violin,
                     notes: ["G3","D4","A4","E5"]),
        TuningPreset(id: "cello", name: "Standard", instrument: .cello,
                     notes: ["C2","G2","D3","A3"]),
        TuningPreset(id: "chromatic", name: "Chromatic", instrument: .chromatic, notes: [])
    ]

    static func presets(for instrument: InstrumentKind) -> [TuningPreset] {
        all.filter { $0.instrument == instrument }
    }
}
