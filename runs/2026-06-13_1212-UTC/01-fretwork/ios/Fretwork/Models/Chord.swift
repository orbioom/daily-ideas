import Foundation

/// A fingered chord shape. `frets` and `fingers` are ordered from the lowest
/// (6th) string to the highest (1st) string for a 6-string guitar.
///   fret  = -1 muted (×), 0 open (○), n = fret number
///   finger = 0 none, 1 index … 4 pinky
struct Chord: Identifiable, Hashable {
    let id: String
    let root: String          // e.g. "C"
    let quality: String       // e.g. "Major", "Minor 7"
    let symbol: String        // e.g. "C", "Am7"
    let frets: [Int]          // low → high, length == string count
    let fingers: [Int]        // low → high
    let baseFret: Int         // first fret drawn in the diagram (1 for open shapes)
    let difficulty: Difficulty

    enum Difficulty: String, CaseIterable, Identifiable {
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
        var id: String { rawValue }
    }

    /// Whether this shape requires a barre (a finger pressing multiple strings).
    var isBarre: Bool {
        var counts: [Int: Int] = [:]
        for f in fingers where f > 0 { counts[f, default: 0] += 1 }
        return counts.values.contains { $0 >= 2 }
    }

    /// The notes sounded, low → high, given the tuning (open/fretted only).
    func notes(tuning: Tuning) -> [String] {
        var out: [String] = []
        for (i, f) in frets.enumerated() where f >= 0 {
            out.append(tuning.noteName(string: i, fret: f))
        }
        return out
    }
}

/// Curated catalog of the chords a learner actually needs first, grouped from
/// open beginner shapes up to barre chords. Hand-verified standard fingerings.
enum ChordLibrary {
    static let all: [Chord] = [
        // —— Open major (beginner) ——
        Chord(id: "C",  root: "C", quality: "Major",  symbol: "C",
              frets: [-1,3,2,0,1,0], fingers: [0,3,2,0,1,0], baseFret: 1, difficulty: .beginner),
        Chord(id: "A",  root: "A", quality: "Major",  symbol: "A",
              frets: [-1,0,2,2,2,0], fingers: [0,0,1,2,3,0], baseFret: 1, difficulty: .beginner),
        Chord(id: "G",  root: "G", quality: "Major",  symbol: "G",
              frets: [3,2,0,0,0,3], fingers: [2,1,0,0,0,3], baseFret: 1, difficulty: .beginner),
        Chord(id: "E",  root: "E", quality: "Major",  symbol: "E",
              frets: [0,2,2,1,0,0], fingers: [0,2,3,1,0,0], baseFret: 1, difficulty: .beginner),
        Chord(id: "D",  root: "D", quality: "Major",  symbol: "D",
              frets: [-1,-1,0,2,3,2], fingers: [0,0,0,1,3,2], baseFret: 1, difficulty: .beginner),
        // —— Open minor (beginner) ——
        Chord(id: "Am", root: "A", quality: "Minor",  symbol: "Am",
              frets: [-1,0,2,2,1,0], fingers: [0,0,2,3,1,0], baseFret: 1, difficulty: .beginner),
        Chord(id: "Em", root: "E", quality: "Minor",  symbol: "Em",
              frets: [0,2,2,0,0,0], fingers: [0,2,3,0,0,0], baseFret: 1, difficulty: .beginner),
        Chord(id: "Dm", root: "D", quality: "Minor",  symbol: "Dm",
              frets: [-1,-1,0,2,3,1], fingers: [0,0,0,2,3,1], baseFret: 1, difficulty: .beginner),
        // —— Open sevenths (intermediate) ——
        Chord(id: "A7", root: "A", quality: "Dominant 7", symbol: "A7",
              frets: [-1,0,2,0,2,0], fingers: [0,0,2,0,3,0], baseFret: 1, difficulty: .intermediate),
        Chord(id: "E7", root: "E", quality: "Dominant 7", symbol: "E7",
              frets: [0,2,0,1,0,0], fingers: [0,2,0,1,0,0], baseFret: 1, difficulty: .intermediate),
        Chord(id: "D7", root: "D", quality: "Dominant 7", symbol: "D7",
              frets: [-1,-1,0,2,1,2], fingers: [0,0,0,2,1,3], baseFret: 1, difficulty: .intermediate),
        Chord(id: "G7", root: "G", quality: "Dominant 7", symbol: "G7",
              frets: [3,2,0,0,0,1], fingers: [3,2,0,0,0,1], baseFret: 1, difficulty: .intermediate),
        Chord(id: "Cmaj7", root: "C", quality: "Major 7", symbol: "Cmaj7",
              frets: [-1,3,2,0,0,0], fingers: [0,3,2,0,0,0], baseFret: 1, difficulty: .intermediate),
        Chord(id: "Am7", root: "A", quality: "Minor 7", symbol: "Am7",
              frets: [-1,0,2,0,1,0], fingers: [0,0,2,0,1,0], baseFret: 1, difficulty: .intermediate),
        Chord(id: "Em7", root: "E", quality: "Minor 7", symbol: "Em7",
              frets: [0,2,0,0,0,0], fingers: [0,2,0,0,0,0], baseFret: 1, difficulty: .intermediate),
        Chord(id: "Dmaj7", root: "D", quality: "Major 7", symbol: "Dmaj7",
              frets: [-1,-1,0,2,2,2], fingers: [0,0,0,1,1,1], baseFret: 1, difficulty: .intermediate),
        // —— Sus / add (intermediate) ——
        Chord(id: "Asus2", root: "A", quality: "Sus2", symbol: "Asus2",
              frets: [-1,0,2,2,0,0], fingers: [0,0,1,2,0,0], baseFret: 1, difficulty: .intermediate),
        Chord(id: "Dsus4", root: "D", quality: "Sus4", symbol: "Dsus4",
              frets: [-1,-1,0,2,3,3], fingers: [0,0,0,1,2,3], baseFret: 1, difficulty: .intermediate),
        Chord(id: "Cadd9", root: "C", quality: "Add9", symbol: "Cadd9",
              frets: [-1,3,2,0,3,0], fingers: [0,2,1,0,3,0], baseFret: 1, difficulty: .intermediate),
        // —— Barre chords (advanced) ——
        Chord(id: "F",  root: "F", quality: "Major (barre)", symbol: "F",
              frets: [1,3,3,2,1,1], fingers: [1,3,4,2,1,1], baseFret: 1, difficulty: .advanced),
        Chord(id: "Bm", root: "B", quality: "Minor (barre)", symbol: "Bm",
              frets: [-1,2,4,4,3,2], fingers: [0,1,3,4,2,1], baseFret: 1, difficulty: .advanced),
        Chord(id: "Bb", root: "B♭", quality: "Major (barre)", symbol: "B♭",
              frets: [-1,1,3,3,3,1], fingers: [0,1,2,3,4,1], baseFret: 1, difficulty: .advanced),
        Chord(id: "F#m", root: "F♯", quality: "Minor (barre)", symbol: "F♯m",
              frets: [2,4,4,2,2,2], fingers: [1,3,4,1,1,1], baseFret: 2, difficulty: .advanced),
        Chord(id: "Cm", root: "C", quality: "Minor (barre)", symbol: "Cm",
              frets: [-1,3,5,5,4,3], fingers: [0,1,3,4,2,1], baseFret: 3, difficulty: .advanced),
    ]

    static func byID(_ id: String) -> Chord? { all.first { $0.id == id } }

    static func grouped() -> [(Chord.Difficulty, [Chord])] {
        Chord.Difficulty.allCases.map { d in (d, all.filter { $0.difficulty == d }) }
    }
}
