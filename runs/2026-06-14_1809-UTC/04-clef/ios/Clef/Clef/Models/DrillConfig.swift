import Foundation

/// The chosen settings for a drill, assembled on the Setup screen.
struct DrillConfig: Equatable {
    var clef: Clef
    var range: NoteRange
    var accidentals: Bool
    var mode: DrillMode
    /// For fixedCount mode, how many notes. Ignored for timed.
    var length: Int

    static let timedDurationSec = 60

    /// The MIDI pool the drill draws targets from.
    func notePool() -> [Int] {
        let midiRange = range.midiRange(for: clef)
        if accidentals {
            return MusicTheory.chromaticMIDIs(in: midiRange)
        }
        return MusicTheory.naturalMIDIs(in: midiRange)
    }

    /// Default config for a clef.
    static func `default`(clef: Clef) -> DrillConfig {
        DrillConfig(clef: clef, range: .staffOnly, accidentals: false, mode: .fixedCount, length: 20)
    }
}
