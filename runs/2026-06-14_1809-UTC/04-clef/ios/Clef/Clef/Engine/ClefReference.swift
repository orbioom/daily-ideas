import Foundation

/// Reference data for the Learn screen: mnemonics and the staff notes of each clef.
struct ClefReference {
    let lineLetters: [String]   // bottom → top, the 5 line notes
    let spaceLetters: [String]  // bottom → top, the 4 space notes
    let lineMnemonic: String
    let spaceMnemonic: String
    let referenceMIDIs: [Int]   // staff notes bottom → top (lines + spaces interleaved)

    static func forClef(_ clef: Clef) -> ClefReference {
        switch clef {
        case .treble, .grand:
            // Treble: lines E G B D F, spaces F A C E. Bottom line E4 = 64.
            return ClefReference(
                lineLetters: ["E", "G", "B", "D", "F"],
                spaceLetters: ["F", "A", "C", "E"],
                lineMnemonic: "Every Good Boy Does Fine",
                spaceMnemonic: "FACE",
                referenceMIDIs: staffMIDIs(bottomLineMIDI: 64))
        case .bass:
            // Bass: lines G B D F A, spaces A C E G. Bottom line G2 = 43.
            return ClefReference(
                lineLetters: ["G", "B", "D", "F", "A"],
                spaceLetters: ["A", "C", "E", "G"],
                lineMnemonic: "Good Boys Do Fine Always",
                spaceMnemonic: "All Cows Eat Grass",
                referenceMIDIs: staffMIDIs(bottomLineMIDI: 43))
        case .alto:
            // Alto: lines F A C E G, spaces G B D F. Bottom line F3 = 53.
            return ClefReference(
                lineLetters: ["F", "A", "C", "E", "G"],
                spaceLetters: ["G", "B", "D", "F"],
                lineMnemonic: "Fat Alley Cats Eat Garbage",
                spaceMnemonic: "Green Boats Drift Far",
                referenceMIDIs: staffMIDIs(bottomLineMIDI: 53))
        }
    }

    /// The 9 natural notes on the staff (5 lines + 4 spaces), bottom → top.
    private static func staffMIDIs(bottomLineMIDI: Int) -> [Int] {
        // Diatonic steps 0...8 cover the staff; map each to its natural MIDI.
        var result: [Int] = []
        for step in 0...8 {
            result.append(midi(forDiatonicStep: step, bottomLineMIDI: bottomLineMIDI))
        }
        return result
    }

    private static func midi(forDiatonicStep step: Int, bottomLineMIDI: Int) -> Int {
        let targetIndex = StaffLayout.diatonicIndex(bottomLineMIDI) + step
        let octave = Int((Double(targetIndex) / 7.0).rounded(.down))
        var within = targetIndex - octave * 7
        if within < 0 { within += 7 }
        let semitoneByStep = [0, 2, 4, 5, 7, 9, 11]
        let semitone = semitoneByStep[min(max(within, 0), 6)]
        // `octave` matches StaffLayout.diatonicIndex's raw octave (floor(midi/12)).
        return octave * 12 + semitone
    }
}
