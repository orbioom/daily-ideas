import Foundation

/// Pure music-theory helpers: pitch-class arithmetic and fretboard note lookup.
/// All math is modulo-12 over the chromatic scale so it never crashes.
enum Music {
    /// Twelve pitch-class names using sharps (the convention guitarists read).
    static let noteNames = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]

    /// Flat spellings, offered as alternates in the trainer.
    static let flatNames = ["C", "D♭", "D", "E♭", "E", "F", "G♭", "G", "A♭", "A", "B♭", "B"]

    /// Name of a pitch class (0...11), safe for any integer input.
    static func name(_ pitchClass: Int) -> String {
        noteNames[((pitchClass % 12) + 12) % 12]
    }

    /// Whether two pitch classes are the same note regardless of input range.
    static func samePitchClass(_ a: Int, _ b: Int) -> Bool {
        (((a % 12) + 12) % 12) == (((b % 12) + 12) % 12)
    }
}

/// A guitar/bass tuning: open-string pitch classes from the *lowest* string
/// (index 0) to the highest. Standard guitar is E A D G B E.
struct Tuning: Identifiable, Hashable {
    let id: String
    let name: String
    /// Pitch class of each open string, low → high.
    let openPitchClasses: [Int]
    /// Display names of each open string, low → high.
    let openNames: [String]

    var stringCount: Int { openPitchClasses.count }

    /// Pitch class sounding at `fret` on `string` (string 0 = lowest).
    /// Guarded against out-of-range input so it can never crash.
    func pitchClass(string: Int, fret: Int) -> Int {
        guard openPitchClasses.indices.contains(string) else { return 0 }
        let f = max(0, fret)
        return (openPitchClasses[string] + f) % 12
    }

    func noteName(string: Int, fret: Int) -> String {
        Music.name(pitchClass(string: string, fret: fret))
    }

    static let standardGuitar = Tuning(
        id: "guitar-standard", name: "Guitar · Standard",
        openPitchClasses: [4, 9, 2, 7, 11, 4],          // E A D G B E
        openNames: ["E", "A", "D", "G", "B", "E"])

    static let dropD = Tuning(
        id: "guitar-dropd", name: "Guitar · Drop D",
        openPitchClasses: [2, 9, 2, 7, 11, 4],          // D A D G B E
        openNames: ["D", "A", "D", "G", "B", "E"])

    static let standardBass = Tuning(
        id: "bass-standard", name: "Bass · Standard",
        openPitchClasses: [4, 9, 2, 7],                 // E A D G
        openNames: ["E", "A", "D", "G"])

    static let ukulele = Tuning(
        id: "uke-standard", name: "Ukulele · Standard",
        openPitchClasses: [7, 0, 4, 9],                 // G C E A
        openNames: ["G", "C", "E", "A"])

    static let all: [Tuning] = [standardGuitar, dropD, standardBass, ukulele]

    static func byID(_ id: String) -> Tuning {
        all.first { $0.id == id } ?? standardGuitar
    }
}
