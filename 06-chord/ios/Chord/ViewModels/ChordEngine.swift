import Foundation
import Observation
import SwiftData

enum ChordSettings {
    static let onboardingDone = "chord_onboarding_v1"
    static let defaultKey = "chord_default_key"
    static let defaultTempo = "chord_default_tempo"
    static let defaultGenre = "chord_default_genre"
    static let hapticFeedback = "chord_haptic_feedback"
    static let showRomanNumerals = "chord_show_roman_numerals"
}

struct WeeklyActivity: Identifiable {
    var id: String { day }
    let day: String
    let count: Int
}

struct GenreCount: Identifiable {
    var id: String { genre }
    let genre: String
    let count: Int
}

@Observable
class ChordEngine {

    // Roman numeral analysis
    func romanNumeral(for chord: ChordSlot, inKey keyName: String) -> String {
        let notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let rootKey = keyName.replacingOccurrences(of: "m", with: "")
            .replacingOccurrences(of: "b", with: "#")
        guard let keyIndex = notes.firstIndex(of: rootKey),
              let chordIndex = notes.firstIndex(of: chord.rootNote) else { return "" }
        let interval = (chordIndex - keyIndex + 12) % 12
        let numerals = ["I", "II", "III", "IV", "V", "VI", "VII"]
        let semitoneToNumeral: [Int: (String, Bool)] = [
            0: ("I", false), 2: ("II", false), 4: ("III", false),
            5: ("IV", false), 7: ("V", false), 9: ("VI", false), 11: ("VII", false),
            1: ("I", false), 3: ("II", false), 6: ("IV", false), 8: ("V", false), 10: ("VI", false)
        ]
        _ = numerals
        guard let (numeral, _) = semitoneToNumeral[interval] else { return "" }
        let isMinor = chord.quality == .minor || chord.quality == .minor7 || chord.quality == .diminished
        return isMinor ? numeral.lowercased() : numeral
    }

    // Suggest chords common in a key
    func suggestedChords(forKey keyName: String) -> [(root: String, quality: ChordQuality)] {
        let majorPatterns: [ChordQuality] = [.major, .minor, .minor, .major, .major, .minor, .diminished]
        let notes = ["C", "D", "E", "F", "G", "A", "B"]
        let sharpNotes = ["C", "D", "E", "F", "G", "A", "B"]
        let majorRoots: [String: [String]] = [
            "C": ["C", "D", "E", "F", "G", "A", "B"],
            "G": ["G", "A", "B", "C", "D", "E", "F#"],
            "D": ["D", "E", "F#", "G", "A", "B", "C#"],
            "A": ["A", "B", "C#", "D", "E", "F#", "G#"],
            "E": ["E", "F#", "G#", "A", "B", "C#", "D#"],
            "F": ["F", "G", "A", "Bb", "C", "D", "E"],
            "Bb": ["Bb", "C", "D", "Eb", "F", "G", "A"],
            "Eb": ["Eb", "F", "G", "Ab", "Bb", "C", "D"],
            "Ab": ["Ab", "Bb", "C", "Db", "Eb", "F", "G"],
            "F#": ["F#", "G#", "A#", "B", "C#", "D#", "E#"],
            "B": ["B", "C#", "D#", "E", "F#", "G#", "A#"],
            "Db": ["Db", "Eb", "F", "Gb", "Ab", "Bb", "C"],
        ]
        _ = notes; _ = sharpNotes
        let roots = majorRoots[keyName.replacingOccurrences(of: "m", with: "")] ?? ["C", "D", "E", "F", "G", "A", "B"]
        return zip(roots, majorPatterns).map { ($0.0, $0.1) }
    }

    // Popular progressions
    func popularProgressions() -> [(name: String, numerals: String, example: String)] {
        [
            ("I–V–vi–IV", "I–V–vi–IV", "C–G–Am–F"),
            ("I–IV–V", "I–IV–V", "C–F–G"),
            ("I–vi–IV–V", "I–vi–IV–V", "C–Am–F–G"),
            ("ii–V–I", "ii–V–I", "Dm–G–C"),
            ("I–V–IV", "I–V–IV", "C–G–F"),
            ("vi–IV–I–V", "vi–IV–I–V", "Am–F–C–G"),
            ("I–IV–vi–V", "I–IV–vi–V", "C–F–Am–G"),
            ("I–iii–IV–V", "I–iii–IV–V", "C–Em–F–G"),
            ("I–vi–ii–V", "I–vi–ii–V", "C–Am–Dm–G"),
            ("blues (I–IV–I–V–IV–I)", "I–IV–I–V–IV–I", "A–D–A–E–D–A"),
        ]
    }

    // Stats
    func totalProgressions(_ progressions: [Progression]) -> Int {
        progressions.count
    }

    func favoriteCount(_ progressions: [Progression]) -> Int {
        progressions.filter { $0.isFavorite }.count
    }

    func weeklyActivity(_ progressions: [Progression]) -> [WeeklyActivity] {
        let calendar = Calendar.current
        let today = Date()
        return (0..<7).reversed().map { offset -> WeeklyActivity in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else {
                return WeeklyActivity(day: "", count: 0)
            }
            let dayStr = day.formatted(.dateTime.weekday(.abbreviated))
            let count = progressions.filter { calendar.isDate($0.createdDate, inSameDayAs: day) }.count
            return WeeklyActivity(day: dayStr, count: count)
        }
    }

    func genreBreakdown(_ progressions: [Progression]) -> [GenreCount] {
        var counts: [String: Int] = [:]
        for p in progressions { counts[p.genre.rawValue, default: 0] += 1 }
        return counts.map { GenreCount(genre: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    func averageChordsPerProgression(_ progressions: [Progression]) -> Double {
        guard !progressions.isEmpty else { return 0 }
        let total = progressions.reduce(0) { $0 + $1.chords.count }
        return Double(total) / Double(progressions.count)
    }
}
