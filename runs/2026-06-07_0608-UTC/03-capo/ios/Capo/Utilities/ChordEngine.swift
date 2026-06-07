import Foundation

/// Music-theory engine for transposing chord charts, choosing enharmonic
/// spelling by key, generating Nashville numbers, and capo math.
///
/// Charts use inline ChordPro-style brackets, e.g. `[G]Amazing [G/B]grace how
/// [C]sweet`. Only the text inside brackets is treated as a chord.
enum ChordEngine {

    static let sharpNames = ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]
    static let flatNames  = ["C","Db","D","Eb","E","F","Gb","G","Ab","A","Bb","B"]

    /// Keys conventionally written with flats (used to pick spelling).
    private static let flatKeys: Set<String> = [
        "F","Bb","Eb","Ab","Db","Gb","Cb",
        "Dm","Gm","Cm","Fm","Bbm","Ebm","Abm"
    ]

    // MARK: - Note parsing

    /// Returns the pitch class (0–11) for a note name like "C#", "Db", "G".
    static func pitchClass(_ note: String) -> Int? {
        guard let first = note.first else { return nil }
        let letter = String(first).uppercased()
        let base: Int
        switch letter {
        case "C": base = 0
        case "D": base = 2
        case "E": base = 4
        case "F": base = 5
        case "G": base = 7
        case "A": base = 9
        case "B": base = 11
        default: return nil
        }
        var pc = base
        for ch in note.dropFirst() {
            if ch == "#" || ch == "♯" { pc += 1 }
            else if ch == "b" || ch == "♭" { pc -= 1 }
            else { break }
        }
        return ((pc % 12) + 12) % 12
    }

    /// Names a pitch class, choosing sharps or flats.
    static func noteName(_ pc: Int, preferFlats: Bool) -> String {
        let i = ((pc % 12) + 12) % 12
        return preferFlats ? flatNames[i] : sharpNames[i]
    }

    static func preferFlats(forKey key: String) -> Bool {
        flatKeys.contains(normalizedKey(key))
    }

    /// Cleans a key string ("g " -> "G", "f#m" -> "F#m").
    static func normalizedKey(_ key: String) -> String {
        let trimmed = key.trimmingCharacters(in: .whitespaces)
        guard let first = trimmed.first else { return "" }
        var result = String(first).uppercased()
        var sawMinor = false
        for ch in trimmed.dropFirst() {
            if ch == "#" || ch == "b" { result.append(ch) }
            else if ch == "m" || ch == "M" { sawMinor = true; break }
        }
        if sawMinor { result.append("m") }
        return result
    }

    // MARK: - Chord transposition

    /// Splits a chord token into (root, suffix, optional bass).
    /// Handles slash chords and any trailing quality text.
    static func parseChord(_ token: String) -> (root: String, suffix: String, bass: String?)? {
        let t = token.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty, let f = t.first, "ABCDEFG".contains(f.uppercased()) else { return nil }
        // split off bass
        var main = t
        var bass: String? = nil
        if let slash = t.firstIndex(of: "/") {
            main = String(t[t.startIndex..<slash])
            bass = String(t[t.index(after: slash)...])
        }
        // root = letter + accidentals
        var root = String(main.first!)
        var idx = main.index(after: main.startIndex)
        while idx < main.endIndex, (main[idx] == "#" || main[idx] == "b") {
            root.append(main[idx]); idx = main.index(after: idx)
        }
        let suffix = String(main[idx...])
        return (root, suffix, bass)
    }

    /// Transposes a single chord token by `semitones`.
    static func transposeChord(_ token: String, semitones: Int, preferFlats: Bool) -> String {
        guard let (root, suffix, bass) = parseChord(token),
              let pc = pitchClass(root) else { return token }
        let newRoot = noteName(pc + semitones, preferFlats: preferFlats)
        var result = newRoot + suffix
        if let bass, let bpc = pitchClass(bass) {
            result += "/" + noteName(bpc + semitones, preferFlats: preferFlats)
        } else if let bass {
            result += "/" + bass
        }
        return result
    }

    /// Transposes every `[chord]` in a chart line, leaving lyrics untouched.
    static func transposeContent(_ content: String, semitones: Int, preferFlats: Bool) -> String {
        guard semitones % 12 != 0 || semitones != 0 else { return content }
        var out = ""
        var i = content.startIndex
        while i < content.endIndex {
            let ch = content[i]
            if ch == "[" {
                if let close = content[i...].firstIndex(of: "]") {
                    let inner = String(content[content.index(after: i)..<close])
                    out += "[" + transposeChord(inner, semitones: semitones, preferFlats: preferFlats) + "]"
                    i = content.index(after: close)
                    continue
                }
            }
            out.append(ch)
            i = content.index(after: i)
        }
        return out
    }

    /// Extracts the distinct chords used in a chart, in order of appearance.
    static func chords(in content: String) -> [String] {
        var result: [String] = []
        var seen = Set<String>()
        var i = content.startIndex
        while i < content.endIndex {
            if content[i] == "[", let close = content[i...].firstIndex(of: "]") {
                let inner = String(content[content.index(after: i)..<close]).trimmingCharacters(in: .whitespaces)
                if !inner.isEmpty, !seen.contains(inner) { seen.insert(inner); result.append(inner) }
                i = content.index(after: close)
            } else {
                i = content.index(after: i)
            }
        }
        return result
    }

    // MARK: - Keys

    /// The 12 chromatic key names from an original key + semitone shift.
    static func transposedKey(_ key: String, semitones: Int) -> String {
        let norm = normalizedKey(key)
        let isMinor = norm.hasSuffix("m")
        let rootStr = isMinor ? String(norm.dropLast()) : norm
        guard let pc = pitchClass(rootStr) else { return key }
        let newKey = noteName(pc + semitones, preferFlats: preferFlats(forKey: norm))
        return newKey + (isMinor ? "m" : "")
    }

    /// Semitone distance from one key to another (-11...11, shortest).
    static func semitones(from: String, to: String) -> Int {
        let a = normalizedKey(from), b = normalizedKey(to)
        let ar = a.hasSuffix("m") ? String(a.dropLast()) : a
        let br = b.hasSuffix("m") ? String(b.dropLast()) : b
        guard let pa = pitchClass(ar), let pb = pitchClass(br) else { return 0 }
        var d = (pb - pa) % 12
        if d > 6 { d -= 12 }
        if d < -6 { d += 12 }
        return d
    }

    // MARK: - Nashville numbers

    private static let majorDegreeOffsets = [0,2,4,5,7,9,11]   // 1..7

    /// Converts a chord token to a Nashville number string relative to `key`.
    static func nashville(for token: String, key: String) -> String {
        guard let (root, suffix, bass) = parseChord(token),
              let pc = pitchClass(root) else { return token }
        let norm = normalizedKey(key)
        let isMinor = norm.hasSuffix("m")
        let keyRootStr = isMinor ? String(norm.dropLast()) : norm
        guard let keyPC = pitchClass(keyRootStr) else { return token }
        // For minor keys, number from the relative scale's tonic (use natural minor degrees).
        let offsets = isMinor ? [0,2,3,5,7,8,10] : majorDegreeOffsets
        let interval = ((pc - keyPC) % 12 + 12) % 12
        var number = ""
        if let degree = offsets.firstIndex(of: interval) {
            number = "\(degree + 1)"
        } else {
            // accidental degree: find nearest lower degree and add #
            for d in stride(from: 6, through: 0, by: -1) where offsets[d] < interval {
                number = "♯\(d + 1)"; break
            }
            if number.isEmpty { number = "♭2" }
        }
        var result = number + suffix
        if let bass { result += "/" + nashvilleNote(bass, keyPC: keyPC, offsets: offsets) }
        return result
    }

    private static func nashvilleNote(_ note: String, keyPC: Int, offsets: [Int]) -> String {
        guard let pc = pitchClass(note) else { return note }
        let interval = ((pc - keyPC) % 12 + 12) % 12
        if let degree = offsets.firstIndex(of: interval) { return "\(degree + 1)" }
        return note
    }

    // MARK: - Capo

    /// With a capo on `fret`, the shapes you play are `fret` semitones below the
    /// sounding key. Returns the chord shapes to read for a chart in `soundingKey`.
    static func shapesKey(soundingKey: String, capo: Int) -> String {
        transposedKey(soundingKey, semitones: -capo)
    }

    /// Suggests a capo position (0–7) and the resulting open-friendly shape key
    /// to play a song that should sound in `targetKey`.
    struct CapoSuggestion: Identifiable {
        var id: Int { capo }
        let capo: Int
        let shapeKey: String
        let isOpenFriendly: Bool
    }

    /// Keys with the most open-string-friendly shapes on guitar.
    private static let openKeys: Set<String> = ["C","A","G","E","D","Am","Em","Dm"]

    static func capoSuggestions(forSoundingKey key: String) -> [CapoSuggestion] {
        (0...7).map { capo in
            let shape = shapesKey(soundingKey: key, capo: capo)
            return CapoSuggestion(capo: capo, shapeKey: shape,
                                  isOpenFriendly: openKeys.contains(normalizedKey(shape)))
        }
    }
}
