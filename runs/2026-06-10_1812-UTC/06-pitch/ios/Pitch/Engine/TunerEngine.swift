import Foundation

/// A musical note resolved from a frequency: name, octave, exact reference
/// frequency, and cents offset from that reference.
struct ResolvedNote: Equatable {
    let name: String        // e.g. "A"
    let octave: Int
    let midi: Int
    let referenceFrequency: Double
    let cents: Double       // signed offset from reference, -50...+50 typically

    var displayName: String { "\(name)\(octave)" }
    var isInTune: Bool { abs(cents) <= 5 }
}

/// Pure music-theory math: maps frequencies to notes and notes to frequencies,
/// relative to a configurable A4 reference.
enum TunerEngine {
    static let sharpNames = ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]
    static let flatNames  = ["C","Db","D","Eb","E","F","Gb","G","Ab","A","Bb","B"]

    /// Frequency of a MIDI note number for a given A4 reference (A4 = midi 69).
    static func frequency(forMidi midi: Int, a4: Double = 440) -> Double {
        a4 * pow(2.0, Double(midi - 69) / 12.0)
    }

    /// Parse a note name like "A4", "C#3", "Bb2" to a MIDI number.
    static func midi(forName name: String) -> Int? {
        var letters = ""
        var accidental = 0
        var octaveString = ""
        for ch in name {
            if ch.isLetter { letters.append(ch) }
            else if ch == "#" { accidental += 1 }
            else if ch == "b" { accidental -= 1 }
            else if ch == "-" || ch.isNumber { octaveString.append(ch) }
        }
        guard let octave = Int(octaveString) else { return nil }
        let base: [String: Int] = ["C":0,"D":2,"E":4,"F":5,"G":7,"A":9,"B":11]
        guard let semis = base[letters.uppercased()] else { return nil }
        return (octave + 1) * 12 + semis + accidental
    }

    static func frequency(forName name: String, a4: Double = 440) -> Double? {
        guard let m = midi(forName: name) else { return nil }
        return frequency(forMidi: m, a4: a4)
    }

    /// Resolve an arbitrary frequency to the nearest note + cents offset.
    static func resolve(frequency: Double, a4: Double = 440, useFlats: Bool = false) -> ResolvedNote? {
        guard frequency > 0 else { return nil }
        let midiFloat = 69 + 12 * log2(frequency / a4)
        guard midiFloat.isFinite else { return nil }
        let midi = Int(midiFloat.rounded())
        let ref = self.frequency(forMidi: midi, a4: a4)
        let cents = 1200 * log2(frequency / ref)
        let names = useFlats ? flatNames : sharpNames
        let nameIndex = ((midi % 12) + 12) % 12
        let octave = midi / 12 - 1
        return ResolvedNote(name: names[nameIndex], octave: octave, midi: midi,
                            referenceFrequency: ref, cents: cents)
    }

    /// Given a tuning's target note names, find the closest target to a frequency.
    static func nearestTarget(to frequency: Double, in noteNames: [String], a4: Double = 440)
        -> (name: String, frequency: Double, cents: Double)? {
        guard frequency > 0, !noteNames.isEmpty else { return nil }
        var best: (name: String, frequency: Double, cents: Double)?
        var bestAbs = Double.greatestFiniteMagnitude
        for name in noteNames {
            guard let target = self.frequency(forName: name, a4: a4) else { continue }
            let cents = 1200 * log2(frequency / target)
            if abs(cents) < bestAbs {
                best = (name, target, cents)
                bestAbs = abs(cents)
            }
        }
        return best
    }
}
