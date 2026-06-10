import Foundation

/// Equal-temperament note math, parameterized by the A4 calibration frequency.
struct NoteReading {
    let frequency: Double
    let midi: Int
    let name: String        // e.g. "A"
    let octave: Int         // scientific pitch notation
    let cents: Double       // -50...+50 offset from the nearest note

    var displayName: String { "\(name)\(octave)" }
}

enum NoteMath {
    static let names = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
    /// ASCII names used for parsing/storage (so "C#" and "C♯" both work).
    static let asciiNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

    static func reading(frequency: Double, a4: Double) -> NoteReading? {
        guard frequency > 0, a4 > 0 else { return nil }
        let midiFloat = 69.0 + 12.0 * log2(frequency / a4)
        guard midiFloat.isFinite else { return nil }
        let midi = Int(midiFloat.rounded())
        let cents = (midiFloat - Double(midi)) * 100.0
        let idx = ((midi % 12) + 12) % 12
        let octave = midi / 12 - 1
        return NoteReading(frequency: frequency, midi: midi, name: names[idx], octave: octave, cents: cents)
    }

    /// Frequency for a MIDI note number under the given calibration.
    static func frequency(midi: Int, a4: Double) -> Double {
        a4 * pow(2.0, Double(midi - 69) / 12.0)
    }

    /// Parse a note name like "E2", "F#3", "Bb1" → MIDI number.
    static func midi(forName raw: String) -> Int? {
        let s = raw.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "♯", with: "#")
            .replacingOccurrences(of: "♭", with: "b")
        guard let first = s.first else { return nil }
        let letter = String(first).uppercased()
        var rest = String(s.dropFirst())
        var semis = 0
        if rest.first == "#" { semis = 1; rest.removeFirst() }
        else if rest.first == "b" { semis = -1; rest.removeFirst() }
        guard let octave = Int(rest) else { return nil }
        let baseMap = ["C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11]
        guard let base = baseMap[letter] else { return nil }
        return (octave + 1) * 12 + base + semis
    }

    static func frequency(forName name: String, a4: Double) -> Double? {
        guard let m = midi(forName: name) else { return nil }
        return frequency(midi: m, a4: a4)
    }

    static func displayName(forMidi midi: Int) -> String {
        let idx = ((midi % 12) + 12) % 12
        let octave = midi / 12 - 1
        return "\(names[idx])\(octave)"
    }
}
