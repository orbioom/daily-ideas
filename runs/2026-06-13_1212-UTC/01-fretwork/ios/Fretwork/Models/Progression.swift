import Foundation

/// A common chord progression learners practice along to. Chord IDs reference
/// `ChordLibrary`. The "feel" string gives songwriting context.
struct Progression: Identifiable, Hashable {
    let id: String
    let name: String
    let numerals: String          // e.g. "I–V–vi–IV"
    let chordIDs: [String]
    let feel: String
    let pro: Bool                 // gated behind Pro unlock

    func chords() -> [Chord] { chordIDs.compactMap(ChordLibrary.byID) }
}

enum ProgressionLibrary {
    static let all: [Progression] = [
        Progression(id: "pop",   name: "The Pop Anthem", numerals: "I–V–vi–IV",
                    chordIDs: ["G", "D", "Em", "C"],
                    feel: "Uplifting, used in hundreds of hits. The four-chord song.", pro: false),
        Progression(id: "50s",   name: "Doo-Wop / 50s", numerals: "I–vi–IV–V",
                    chordIDs: ["C", "Am", "F", "G"],
                    feel: "Nostalgic, warm. Stand By Me lives here.", pro: false),
        Progression(id: "blues", name: "12-Bar Blues (quick)", numerals: "I–IV–V",
                    chordIDs: ["A7", "D7", "E7"],
                    feel: "The backbone of blues and rock & roll.", pro: false),
        Progression(id: "folk",  name: "Folk Strummer", numerals: "G–C–D",
                    chordIDs: ["G", "C", "D"],
                    feel: "Three open chords, endless campfire songs.", pro: false),
        Progression(id: "sad",   name: "The Sensitive One", numerals: "vi–IV–I–V",
                    chordIDs: ["Em", "C", "G", "D"],
                    feel: "Wistful, cinematic. Same chords, darker start.", pro: false),
        Progression(id: "jazz",  name: "Jazz ii–V–I", numerals: "ii–V–I",
                    chordIDs: ["Dm", "G7", "Cmaj7"],
                    feel: "The most important cadence in jazz.", pro: true),
        Progression(id: "canon", name: "Pachelbel Canon", numerals: "I–V–vi–iii–IV",
                    chordIDs: ["G", "D", "Em", "Bm", "C"],
                    feel: "Endlessly satisfying descending line.", pro: true),
        Progression(id: "andalu", name: "Andalusian Cadence", numerals: "i–♭VII–♭VI–V",
                    chordIDs: ["Am", "G", "F", "E"],
                    feel: "Flamenco fire, descending and dramatic.", pro: true),
    ]
}
