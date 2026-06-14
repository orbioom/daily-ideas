import CoreGraphics
import Foundation

/// Pure staff geometry: maps a pitch (by MIDI) onto a 5-line staff for a given clef.
///
/// Vertical model: the bottom staff line sits at diatonic step 0. Each successive
/// diatonic letter step (C→D→E…) moves up by **half** a staff space. A full staff
/// space (line→next line) is two diatonic steps. The staff has 5 lines / 4 spaces.
enum StaffLayout {

    /// Diatonic step index of a MIDI note relative to the clef's bottom staff line.
    /// 0 = bottom line, 1 = first space, 2 = second line, … Negative = below the staff.
    /// Uses natural letter ordering so accidentals share their natural's line/space.
    static func diatonicStep(midi: Int, bottomLineMIDI: Int) -> Int {
        diatonicIndex(midi) - diatonicIndex(bottomLineMIDI)
    }

    /// A monotonic diatonic index across octaves: counts only natural letter positions.
    /// C maps to 0 within its octave; the index increases by 7 per octave.
    static func diatonicIndex(_ midi: Int) -> Int {
        let pc = ((midi % 12) + 12) % 12
        let octave = Int((Double(midi) / 12.0).rounded(.down)) // floor division
        // Map pitch class to diatonic position within the octave (C=0 … B=6).
        // Accidentals collapse onto the natural below.
        let stepWithinOctave: Int
        switch pc {
        case 0: stepWithinOctave = 0        // C
        case 1: stepWithinOctave = 0        // C#
        case 2: stepWithinOctave = 1        // D
        case 3: stepWithinOctave = 1        // D#
        case 4: stepWithinOctave = 2        // E
        case 5: stepWithinOctave = 3        // F
        case 6: stepWithinOctave = 3        // F#
        case 7: stepWithinOctave = 4        // G
        case 8: stepWithinOctave = 4        // G#
        case 9: stepWithinOctave = 5        // A
        case 10: stepWithinOctave = 5       // A#
        default: stepWithinOctave = 6       // B
        }
        return octave * 7 + stepWithinOctave
    }

    /// Vertical offset in points from the **bottom line** for a note, given the spacing
    /// between adjacent staff lines (`lineGap`). Positive = upward on screen.
    /// One diatonic step = half a line gap.
    static func verticalOffset(diatonicStep: Int, lineGap: CGFloat) -> CGFloat {
        CGFloat(diatonicStep) * (lineGap / 2)
    }

    /// Diatonic steps a note lies above the top line (step 8) — used for ledger lines above.
    /// Returns the line numbers (in step units, even numbers) that need a ledger drawn.
    static func ledgerSteps(diatonicStep step: Int) -> [Int] {
        var steps: [Int] = []
        if step > 8 {
            // Lines above the staff are at even steps 10, 12, …
            var s = 10
            while s <= step { steps.append(s); s += 2 }
        } else if step < 0 {
            // Lines below the staff are at even steps -2, -4, …
            var s = -2
            while s >= step { steps.append(s); s -= 2 }
        }
        return steps
    }

    /// True when the note head sits exactly on a staff line (even step) vs in a space.
    static func isOnLine(diatonicStep step: Int) -> Bool {
        step % 2 == 0
    }
}
