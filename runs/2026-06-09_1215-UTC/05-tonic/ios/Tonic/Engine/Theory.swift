import Foundation

/// Equal-temperament music theory primitives: MIDI-to-frequency conversion,
/// note naming, and the interval / chord / scale catalogs the ear trainer drills.
/// All values are computed — there are no audio files anywhere in Tonic.
enum Theory {

    // MARK: - Pitch

    /// Frequency in Hz for a MIDI note number (A4 = 69 = 440 Hz, 12-TET).
    static func frequency(forMidi midi: Int) -> Double {
        440.0 * pow(2.0, Double(midi - 69) / 12.0)
    }

    /// Pitch-class names using sharps.
    static let pitchClasses = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

    /// A name like "C4" for a MIDI note (C4 = 60, the octave numbering Apple uses).
    static func name(forMidi midi: Int) -> String {
        let pc = ((midi % 12) + 12) % 12
        let octave = midi / 12 - 1
        return "\(pitchClasses[pc])\(octave)"
    }

    /// Just the pitch-class name (no octave), e.g. "C#".
    static func pitchClassName(forMidi midi: Int) -> String {
        pitchClasses[((midi % 12) + 12) % 12]
    }
}

// MARK: - Intervals

/// Every interval from minor 2nd to octave, plus unison. `rawValue` doubles as a
/// stable identifier persisted in `enabledKeys` and `ItemStat.key`.
enum Interval: String, CaseIterable, Identifiable, Codable {
    case unison, m2, M2, m3, M3, P4, TT, P5, m6, M6, m7, M7, P8

    var id: String { rawValue }

    var semitones: Int {
        switch self {
        case .unison: return 0
        case .m2: return 1
        case .M2: return 2
        case .m3: return 3
        case .M3: return 4
        case .P4: return 5
        case .TT: return 6
        case .P5: return 7
        case .m6: return 8
        case .M6: return 9
        case .m7: return 10
        case .M7: return 11
        case .P8: return 12
        }
    }

    var label: String {
        switch self {
        case .unison: return "Unison"
        case .m2: return "Minor 2nd"
        case .M2: return "Major 2nd"
        case .m3: return "Minor 3rd"
        case .M3: return "Major 3rd"
        case .P4: return "Perfect 4th"
        case .TT: return "Tritone"
        case .P5: return "Perfect 5th"
        case .m6: return "Minor 6th"
        case .M6: return "Major 6th"
        case .m7: return "Minor 7th"
        case .M7: return "Major 7th"
        case .P8: return "Octave"
        }
    }

    /// Short label for compact buttons, e.g. "P5", "m3", "TT".
    var short: String {
        switch self {
        case .unison: return "U"
        case .TT: return "TT"
        case .P8: return "P8"
        default: return rawValue
        }
    }
}

// MARK: - Chords

enum ChordType: String, CaseIterable, Identifiable, Codable {
    case major, minor, diminished, augmented, major7, dominant7, minor7

    var id: String { rawValue }

    /// Semitone offsets from the root.
    var intervals: [Int] {
        switch self {
        case .major:      return [0, 4, 7]
        case .minor:      return [0, 3, 7]
        case .diminished: return [0, 3, 6]
        case .augmented:  return [0, 4, 8]
        case .major7:     return [0, 4, 7, 11]
        case .dominant7:  return [0, 4, 7, 10]
        case .minor7:     return [0, 3, 7, 10]
        }
    }

    var label: String {
        switch self {
        case .major:      return "Major"
        case .minor:      return "Minor"
        case .diminished: return "Diminished"
        case .augmented:  return "Augmented"
        case .major7:     return "Major 7th"
        case .dominant7:  return "Dominant 7th"
        case .minor7:     return "Minor 7th"
        }
    }

    var short: String {
        switch self {
        case .major:      return "maj"
        case .minor:      return "min"
        case .diminished: return "dim"
        case .augmented:  return "aug"
        case .major7:     return "maj7"
        case .dominant7:  return "dom7"
        case .minor7:     return "min7"
        }
    }
}

// MARK: - Scales

enum ScaleType: String, CaseIterable, Identifiable, Codable {
    case major, naturalMinor, dorian, mixolydian, majorPentatonic, harmonicMinor

    var id: String { rawValue }

    /// Semitone offsets from the root, including the closing octave where natural.
    var steps: [Int] {
        switch self {
        case .major:           return [0, 2, 4, 5, 7, 9, 11, 12]
        case .naturalMinor:    return [0, 2, 3, 5, 7, 8, 10, 12]
        case .dorian:          return [0, 2, 3, 5, 7, 9, 10, 12]
        case .mixolydian:      return [0, 2, 4, 5, 7, 9, 10, 12]
        case .majorPentatonic: return [0, 2, 4, 7, 9, 12]
        case .harmonicMinor:   return [0, 2, 3, 5, 7, 8, 11, 12]
        }
    }

    var label: String {
        switch self {
        case .major:           return "Major"
        case .naturalMinor:    return "Natural Minor"
        case .dorian:          return "Dorian"
        case .mixolydian:      return "Mixolydian"
        case .majorPentatonic: return "Major Pentatonic"
        case .harmonicMinor:   return "Harmonic Minor"
        }
    }

    var short: String {
        switch self {
        case .major:           return "maj"
        case .naturalMinor:    return "min"
        case .dorian:          return "dor"
        case .mixolydian:      return "mix"
        case .majorPentatonic: return "pent"
        case .harmonicMinor:   return "h.min"
        }
    }
}
