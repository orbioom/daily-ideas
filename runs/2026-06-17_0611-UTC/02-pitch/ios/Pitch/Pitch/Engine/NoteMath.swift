import Foundation

/// Pure 12-TET (twelve-tone equal temperament) note math with a configurable A4
/// reference. No force-unwrap, no unguarded division — all callers are guarded.
enum NoteMath {

    /// Allowed A4 reference range (Hz). Standard concert pitch is 440.
    static let minA4: Double = 415
    static let maxA4: Double = 446
    static let defaultA4: Double = 440

    /// Note names using sharps. Index 0 == C.
    static let noteNames: [String] = ["C", "C♯", "D", "D♯", "E", "F",
                                      "F♯", "G", "G♯", "A", "A♯", "B"]

    /// Clamp an A4 reference into the supported range.
    static func clampA4(_ value: Double) -> Double {
        min(max(value, minA4), maxA4)
    }

    /// A fully resolved pitch description.
    struct Reading: Equatable {
        /// Note name, e.g. "A", "C♯".
        let name: String
        /// Octave number in scientific pitch notation (A4 == 440 Hz octave 4).
        let octave: Int
        /// Signed cents offset from the in-tune target (−50…+50 by construction).
        let cents: Double
        /// The exact target frequency of the nearest note (Hz).
        let targetFrequency: Double
        /// MIDI note number of the nearest note (A4 == 69).
        let midi: Int

        /// e.g. "A4". Useful for compact labels.
        var label: String { "\(name)\(octave)" }
    }

    /// Convert a frequency to its nearest 12-TET note and cents offset.
    /// Returns nil for non-positive / non-finite input.
    static func reading(forFrequency frequency: Double, a4: Double = defaultA4) -> Reading? {
        guard frequency > 0, frequency.isFinite else { return nil }
        let reference = clampA4(a4)
        guard reference > 0 else { return nil }

        // MIDI number as a real value: 69 + 12*log2(f / A4).
        let midiReal = 69.0 + 12.0 * log2(frequency / reference)
        guard midiReal.isFinite else { return nil }

        let nearestMidi = Int(midiReal.rounded())
        let cents = (midiReal - Double(nearestMidi)) * 100.0

        // Pitch class & octave. Use floor division so negatives behave.
        let pitchClass = ((nearestMidi % 12) + 12) % 12
        guard let name = noteNames[safe: pitchClass] else { return nil }
        let octave = (nearestMidi / 12) - 1

        let target = frequency(forMidi: nearestMidi, a4: reference)

        return Reading(name: name,
                       octave: octave,
                       cents: cents,
                       targetFrequency: target,
                       midi: nearestMidi)
    }

    /// Frequency of a MIDI note for a given A4 reference.
    static func frequency(forMidi midi: Int, a4: Double = defaultA4) -> Double {
        let reference = clampA4(a4)
        return reference * pow(2.0, (Double(midi) - 69.0) / 12.0)
    }

    /// MIDI note number for a note name + octave, e.g. ("A", 4) -> 69.
    /// Returns nil if the name isn't a recognized pitch class.
    static func midi(forName name: String, octave: Int) -> Int? {
        guard let pitchClass = pitchClass(forName: name) else { return nil }
        return (octave + 1) * 12 + pitchClass
    }

    /// Frequency for a named note + octave. Returns nil for unknown names.
    static func frequency(forName name: String, octave: Int, a4: Double = defaultA4) -> Double? {
        guard let m = midi(forName: name, octave: octave) else { return nil }
        return frequency(forMidi: m, a4: a4)
    }

    /// Resolve a pitch-class index for a note name, accepting both sharps and flats.
    static func pitchClass(forName raw: String) -> Int? {
        let name = normalize(raw)
        if let idx = noteNames.firstIndex(of: name) { return idx }
        // Flat equivalents.
        let flats: [String: Int] = [
            "D♭": 1, "E♭": 3, "G♭": 6, "A♭": 8, "B♭": 10
        ]
        return flats[name]
    }

    /// Normalize ASCII accidentals (#, b) to the symbols used internally.
    static func normalize(_ raw: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespaces)
        s = s.replacingOccurrences(of: "#", with: "♯")
        // Only treat a trailing lowercase b as a flat (avoid turning "B" into a flat).
        if s.count >= 2, s.hasSuffix("b") {
            s = String(s.dropLast()) + "♭"
        }
        return s
    }

    /// Parse a target-string token like "E2", "A♯3", "C#4" into (name, octave).
    /// Returns nil if it can't be parsed.
    static func parseTarget(_ token: String) -> (name: String, octave: Int)? {
        let s = token.trimmingCharacters(in: .whitespaces)
        guard let last = s.last, let octave = Int(String(last)) else { return nil }
        let namePart = normalize(String(s.dropLast()))
        guard pitchClass(forName: namePart) != nil else { return nil }
        return (namePart, octave)
    }

    /// Full chromatic note list across the playable range, for pickers.
    static func chromaticTargets(fromOctave: Int = 1, toOctave: Int = 6) -> [(name: String, octave: Int)] {
        guard toOctave >= fromOctave else { return [] }
        var out: [(String, Int)] = []
        for octave in fromOctave...toOctave {
            for name in noteNames {
                out.append((name, octave))
            }
        }
        return out
    }
}
