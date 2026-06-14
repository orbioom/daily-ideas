import Foundation

/// A note-range preset for a drill, expressed relative to a clef's staff.
enum NoteRange: String, CaseIterable, Identifiable {
    case staffOnly          // the five lines & four spaces only
    case oneLedger          // staff +/- one ledger line each way
    case full               // a generous expandable range

    var id: String { rawValue }

    var label: String {
        switch self {
        case .staffOnly: return "Staff only"
        case .oneLedger: return "+1 ledger"
        case .full: return "Full"
        }
    }

    var subtitle: String {
        switch self {
        case .staffOnly: return "The notes on the five lines and four spaces"
        case .oneLedger: return "One ledger line above and below"
        case .full: return "A wide range with several ledger lines"
        }
    }

    /// Only the full range is gated (it requires Pro for the extra reach).
    var requiresPro: Bool { self == .full }

    /// The inclusive MIDI range for this preset within a clef.
    /// The staff spans diatonic steps 0...8 (bottom line to top line).
    func midiRange(for clef: Clef) -> ClosedRange<Int> {
        let bottom = clef.bottomLineMIDI
        // Diatonic span beyond the staff, in diatonic steps (each = a line or space).
        let below: Int
        let above: Int
        switch self {
        case .staffOnly: below = 0;  above = 8
        case .oneLedger: below = -3; above = 11   // a ledger line is +/-2 steps; allow a space beyond
        case .full:      below = -7; above = 15
        }
        let lowMidi = midi(forDiatonicStep: below, bottomLineMIDI: bottom)
        let highMidi = midi(forDiatonicStep: above, bottomLineMIDI: bottom)
        let lo = min(lowMidi, highMidi)
        let hi = max(lowMidi, highMidi)
        return lo...hi
    }

    /// Inverse of StaffLayout.diatonicStep: find a natural MIDI at a given diatonic step.
    private func midi(forDiatonicStep step: Int, bottomLineMIDI: Int) -> Int {
        let targetIndex = StaffLayout.diatonicIndex(bottomLineMIDI) + step
        // Convert a diatonic index back to the MIDI of that natural note.
        let octave = Int((Double(targetIndex) / 7.0).rounded(.down))
        var within = targetIndex - octave * 7
        if within < 0 { within += 7 }
        let semitoneByStep = [0, 2, 4, 5, 7, 9, 11] // C D E F G A B
        let semitone = semitoneByStep[min(max(within, 0), 6)]
        // `octave` here is the raw 12-tone octave used by StaffLayout.diatonicIndex
        // (floor(midi/12)), so the MIDI is octave*12 + semitone.
        return octave * 12 + semitone
    }
}
