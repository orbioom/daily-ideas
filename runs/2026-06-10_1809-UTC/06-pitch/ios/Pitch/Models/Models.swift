import Foundation
import SwiftData
import SwiftUI

enum Instrument: String, CaseIterable, Identifiable, Codable {
    case guitar, bass, ukulele, violin, other
    var id: String { rawValue }
    var title: String {
        switch self {
        case .guitar: "Guitar"; case .bass: "Bass"; case .ukulele: "Ukulele"
        case .violin: "Violin"; case .other: "Other"
        }
    }
    var icon: String {
        switch self {
        case .guitar: "guitars"; case .bass: "guitars"; case .ukulele: "guitars"
        case .violin: "pianokeys"; case .other: "music.note"
        }
    }
}

/// A named tuning: an ordered list of string notes (low → high).
@Model
final class Tuning {
    var id: UUID
    var name: String
    var instrumentRaw: String
    var notesJoined: String     // e.g. "E2,A2,D3,G3,B3,E4"
    var isBuiltIn: Bool
    var createdAt: Date

    init(name: String, instrument: Instrument, notes: [String], isBuiltIn: Bool = false) {
        self.id = UUID()
        self.name = name
        self.instrumentRaw = instrument.rawValue
        self.notesJoined = notes.joined(separator: ",")
        self.isBuiltIn = isBuiltIn
        self.createdAt = .now
    }

    var instrument: Instrument { Instrument(rawValue: instrumentRaw) ?? .other }
    var notes: [String] {
        get { notesJoined.isEmpty ? [] : notesJoined.split(separator: ",").map(String.init) }
        set { notesJoined = newValue.joined(separator: ",") }
    }
}

/// A saved metronome setting.
@Model
final class MetronomePreset {
    var id: UUID
    var name: String
    var bpm: Int
    var beatsPerBar: Int
    var accentFirst: Bool
    var createdAt: Date

    init(name: String, bpm: Int, beatsPerBar: Int = 4, accentFirst: Bool = true) {
        self.id = UUID()
        self.name = name
        self.bpm = bpm
        self.beatsPerBar = beatsPerBar
        self.accentFirst = accentFirst
        self.createdAt = .now
    }

    /// Italian tempo marking for the bpm.
    var marking: String {
        switch bpm {
        case ..<60: "Largo"
        case 60..<76: "Adagio"
        case 76..<108: "Andante"
        case 108..<120: "Moderato"
        case 120..<156: "Allegro"
        case 156..<176: "Vivace"
        default: "Presto"
        }
    }
}

enum Seeder {
    static func seedIfNeeded(_ context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: "seeded.v1") else { return }
        let tunings: [Tuning] = [
            Tuning(name: "Standard", instrument: .guitar, notes: ["E2","A2","D3","G3","B3","E4"], isBuiltIn: true),
            Tuning(name: "Drop D", instrument: .guitar, notes: ["D2","A2","D3","G3","B3","E4"], isBuiltIn: true),
            Tuning(name: "DADGAD", instrument: .guitar, notes: ["D2","A2","D3","G3","A3","D4"], isBuiltIn: true),
            Tuning(name: "Half-step down", instrument: .guitar, notes: ["D#2","G#2","C#3","F#3","A#3","D#4"], isBuiltIn: true),
            Tuning(name: "Open G", instrument: .guitar, notes: ["D2","G2","D3","G3","B3","D4"], isBuiltIn: true),
            Tuning(name: "Standard", instrument: .bass, notes: ["E1","A1","D2","G2"], isBuiltIn: true),
            Tuning(name: "5-string", instrument: .bass, notes: ["B0","E1","A1","D2","G2"], isBuiltIn: true),
            Tuning(name: "Standard (GCEA)", instrument: .ukulele, notes: ["G4","C4","E4","A4"], isBuiltIn: true),
            Tuning(name: "Standard (GDAE)", instrument: .violin, notes: ["G3","D4","A4","E5"], isBuiltIn: true),
        ]
        for t in tunings { context.insert(t) }
        let presets: [MetronomePreset] = [
            MetronomePreset(name: "Practice", bpm: 80),
            MetronomePreset(name: "Waltz", bpm: 120, beatsPerBar: 3),
            MetronomePreset(name: "Up-tempo", bpm: 144),
        ]
        for p in presets { context.insert(p) }
        try? context.save()
        UserDefaults.standard.set(true, forKey: "seeded.v1")
    }
}
