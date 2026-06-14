import Foundation

/// Builds human-readable descriptions of a note's staff position for accessibility.
enum NoteDescription {
    /// e.g. "Note E, bottom line of the treble staff" or "Note C, one ledger line below".
    static func describe(midi: Int, clef: Clef, useFlats: Bool) -> String {
        let pitch = Pitch(midi)
        let name = pitch.spokenName(useFlats: useFlats)
        let bottom = clef.bottomLineMIDI
        let step = StaffLayout.diatonicStep(midi: midi, bottomLineMIDI: bottom)
        let position = positionPhrase(step: step)
        return "Note \(name), \(position) of the \(clef.displayName.lowercased()) staff"
    }

    private static func positionPhrase(step: Int) -> String {
        // On-staff: steps 0...8. Lines are even (0,2,4,6,8), spaces odd (1,3,5,7).
        if step >= 0 && step <= 8 {
            if StaffLayout.isOnLine(diatonicStep: step) {
                let lineNumber = step / 2 + 1
                return "\(ordinal(lineNumber)) line"
            } else {
                let spaceNumber = (step + 1) / 2
                return "\(ordinal(spaceNumber)) space"
            }
        }
        if step < 0 {
            let count = (abs(step) + 1) / 2
            return "\(count) ledger \(count == 1 ? "line" : "lines") below"
        }
        let count = (step - 8 + 1) / 2
        return "\(count) ledger \(count == 1 ? "line" : "lines") above"
    }

    private static func ordinal(_ n: Int) -> String {
        switch n {
        case 1: return "first"
        case 2: return "second"
        case 3: return "third"
        case 4: return "fourth"
        case 5: return "fifth"
        default: return "\(n)th"
        }
    }
}
