import Foundation

/// The four clefs Clef can drill. Each knows the MIDI number of its bottom staff line.
enum Clef: String, CaseIterable, Identifiable, Codable {
    case treble
    case bass
    case alto
    case grand

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .treble: return "Treble"
        case .bass: return "Bass"
        case .alto: return "Alto"
        case .grand: return "Grand"
        }
    }

    /// SF Symbol used as a lightweight clef glyph label.
    var symbolName: String { "music.note" }

    /// A short descriptive subtitle.
    var subtitle: String {
        switch self {
        case .treble: return "G clef — melody & right hand"
        case .bass: return "F clef — low notes & left hand"
        case .alto: return "C clef — viola range"
        case .grand: return "Both staves together"
        }
    }

    /// Whether this clef requires Pro (only treble is free).
    var requiresPro: Bool { self != .treble }

    /// MIDI number of the BOTTOM line of this clef's staff.
    /// Treble: E4 = 64. Bass: G2 = 43. Alto: F3 = 53 (bottom line of the C clef staff).
    /// Grand is rendered as the treble staff for single-note drilling but draws a brace.
    var bottomLineMIDI: Int {
        switch self {
        case .treble: return 64   // E4
        case .bass:   return 43   // G2
        case .alto:   return 53   // F3
        case .grand:  return 64   // shares treble staff geometry for the upper staff
        }
    }

    /// For the grand staff, the bass sub-staff bottom line (G2 = 43).
    var grandBassBottomLineMIDI: Int { 43 }
}

/// A musical pitch identified by its MIDI number (C4 = 60).
struct Pitch: Equatable, Hashable {
    let midi: Int

    init(_ midi: Int) { self.midi = midi }

    /// The seven natural letter names indexed by pitch class for naturals only.
    private static let letterByPitchClass: [Int: String] = [
        0: "C", 2: "D", 4: "E", 5: "F", 7: "G", 9: "A", 11: "B"
    ]

    private static let sharpNames = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
    private static let flatNames  = ["C", "D♭", "D", "E♭", "E", "F", "G♭", "G", "A♭", "A", "B♭", "B"]
    private static let solfege    = ["Do", "Re", "Mi", "Fa", "Sol", "La", "Ti"]
    private static let letterOrder = ["C", "D", "E", "F", "G", "A", "B"]

    /// Pitch class 0...11.
    var pitchClass: Int {
        let m = midi % 12
        return m < 0 ? m + 12 : m
    }

    /// Octave in scientific pitch notation (C4 = MIDI 60).
    var octave: Int { midi / 12 - 1 }

    /// True if this pitch is a natural (no sharp/flat).
    var isNatural: Bool { Self.letterByPitchClass[pitchClass] != nil }

    /// The base letter (A–G) for this pitch, choosing the natural below for accidentals.
    var letterName: String {
        if let n = Self.letterByPitchClass[pitchClass] { return n }
        // Accidental: name from the natural a semitone below (sharp spelling).
        let below = Pitch(midi - 1)
        return Self.letterByPitchClass[below.pitchClass] ?? "C"
    }

    /// Full display name. `useFlats` chooses flat spellings for accidentals.
    /// `solfege` renders Do/Re/Mi for the letter component.
    func name(useFlats: Bool, solfege useSolfege: Bool = false) -> String {
        let table = useFlats ? Self.flatNames : Self.sharpNames
        let raw = table[safe: pitchClass] ?? "C"
        guard useSolfege else { return raw }
        return Self.solfegeName(forSpelling: raw)
    }

    /// Convert a letter-based spelling (e.g. "F♯") to solfège ("Fa♯").
    private static func solfegeName(forSpelling raw: String) -> String {
        guard let first = raw.first else { return raw }
        let letter = String(first)
        let suffix = String(raw.dropFirst())   // "", "♯" or "♭"
        guard let idx = letterOrder.firstIndex(of: letter), idx < solfege.count else { return raw }
        return solfege[idx] + suffix
    }

    /// Map a bare answer letter (A–G) to its display per the note-name style.
    static func displayLetter(_ letter: String, solfege useSolfege: Bool) -> String {
        guard useSolfege, let idx = letterOrder.firstIndex(of: letter), idx < solfege.count else {
            return letter
        }
        return solfege[idx]
    }

    /// Accessibility-friendly spoken name, e.g. "E", "F sharp", "B flat".
    func spokenName(useFlats: Bool) -> String {
        let raw = name(useFlats: useFlats)
        return raw
            .replacingOccurrences(of: "♯", with: " sharp")
            .replacingOccurrences(of: "♭", with: " flat")
    }
}

/// Pure music-theory helpers: building drill note pools and checking answers.
enum MusicTheory {

    /// Diatonic letter sequence used for staff positioning.
    static let diatonicLetters = ["C", "D", "E", "F", "G", "A", "B"]

    /// The natural-note MIDIs within an inclusive MIDI range.
    static func naturalMIDIs(in range: ClosedRange<Int>) -> [Int] {
        guard range.lowerBound <= range.upperBound else { return [] }
        return range.filter { Pitch($0).isNatural }
    }

    /// All MIDIs (chromatic) within an inclusive range.
    static func chromaticMIDIs(in range: ClosedRange<Int>) -> [Int] {
        guard range.lowerBound <= range.upperBound else { return [] }
        return Array(range)
    }

    /// The expected answer letter (A–G) for a MIDI value.
    static func answerLetter(for midi: Int) -> String {
        Pitch(midi).letterName
    }

    /// Whether a given answer (letter, optional accidental) is correct for a target MIDI.
    /// `useFlats` controls the accidental spelling the user is being asked to match.
    static func isCorrect(answerLetter: String, accidental: Accidental, target midi: Int, useFlats: Bool) -> Bool {
        let pitch = Pitch(midi)
        // Naturals: letter must match and accidental must be natural.
        if pitch.isNatural {
            return answerLetter == pitch.letterName && accidental == .natural
        }
        // Accidental target: compare against the canonical spelling.
        let expected = pitch.name(useFlats: useFlats)
        let composed = answerLetter + accidental.symbol
        return composed == expected
    }
}

/// Accidental modifier the user can attach to a letter answer.
enum Accidental: String, CaseIterable, Identifiable {
    case natural
    case sharp
    case flat

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .natural: return ""
        case .sharp: return "♯"
        case .flat: return "♭"
        }
    }

    var spokenName: String {
        switch self {
        case .natural: return "natural"
        case .sharp: return "sharp"
        case .flat: return "flat"
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
