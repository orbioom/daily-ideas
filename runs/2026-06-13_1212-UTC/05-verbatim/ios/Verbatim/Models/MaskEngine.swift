import Foundation

/// A deterministic 64-bit RNG (SplitMix64) so masking is stable for a given
/// passage + level + seed but still spreads blanks across the text.
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

/// The escalating study levels. `masteryLevel` (0...5) maps 1:1 to a case.
enum StudyLevel: Int, CaseIterable, Identifiable {
    case read = 0
    case firstLetters
    case blanks25
    case blanks50
    case blanks75
    case recall

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .read:         return "Read"
        case .firstLetters: return "First letters"
        case .blanks25:     return "Light blanks"
        case .blanks50:     return "Half blanks"
        case .blanks75:     return "Heavy blanks"
        case .recall:       return "Full recall"
        }
    }

    var subtitle: String {
        switch self {
        case .read:         return "Read it through, soak it in."
        case .firstLetters: return "Only first letters remain."
        case .blanks25:     return "A quarter of the words are hidden."
        case .blanks50:     return "Half the words are hidden."
        case .blanks75:     return "Most words are hidden."
        case .recall:       return "From memory — reveal to check."
        }
    }

    /// Fraction of words hidden for the blank levels (0 where not applicable).
    var blankFraction: Double {
        switch self {
        case .blanks25: return 0.25
        case .blanks50: return 0.50
        case .blanks75: return 0.75
        default:        return 0
        }
    }

    static func forMastery(_ level: Int) -> StudyLevel {
        StudyLevel(rawValue: min(max(level, 0), 5)) ?? .read
    }
}

/// One unit of a tokenized passage. Whitespace/newlines are preserved verbatim
/// so the original layout (line breaks, stanza spacing) can be rebuilt exactly.
struct Token: Identifiable {
    enum Kind { case word, space }
    let id: Int
    let kind: Kind
    /// The original text of the token.
    let text: String
    /// For words: leading punctuation, the core letters, and trailing punctuation.
    let leading: String
    let core: String
    let trailing: String

    var isWord: Bool { kind == .word }
}

/// Pure passage transformer: tokenization, first-letter reduction, and seeded
/// blanking. All math is guarded so it can never crash on user input.
enum MaskEngine {

    /// A character set treated as "core" letters of a word.
    private static func isWordChar(_ c: Character) -> Bool {
        c.isLetter || c.isNumber || c == "'" || c == "’" || c == "-"
    }

    /// Split text into ordered tokens, preserving whitespace runs verbatim.
    static func tokenize(_ text: String) -> [Token] {
        var tokens: [Token] = []
        var index = 0
        var current = ""
        var currentIsSpace: Bool? = nil

        func flush() {
            guard !current.isEmpty, let isSpace = currentIsSpace else { return }
            if isSpace {
                tokens.append(Token(id: index, kind: .space, text: current,
                                    leading: "", core: "", trailing: ""))
            } else {
                let (lead, core, trail) = splitWord(current)
                tokens.append(Token(id: index, kind: .word, text: current,
                                    leading: lead, core: core, trailing: trail))
            }
            index += 1
            current = ""
        }

        for c in text {
            let space = c.isWhitespace
            if currentIsSpace == nil { currentIsSpace = space }
            if space == currentIsSpace {
                current.append(c)
            } else {
                flush()
                currentIsSpace = space
                current.append(c)
            }
        }
        flush()
        return tokens
    }

    /// Separate a raw token into leading punctuation, core letters, trailing
    /// punctuation — e.g. "(Shall," → ("(", "Shall", ",").
    private static func splitWord(_ raw: String) -> (String, String, String) {
        let chars = Array(raw)
        var start = 0
        var end = chars.count
        while start < end, !isWordChar(chars[start]) { start += 1 }
        while end > start, !isWordChar(chars[end - 1]) { end -= 1 }
        // All punctuation (e.g. a lone em-dash): keep it verbatim as leading
        // with an empty core so it is never treated as a maskable word.
        guard start < end else { return (raw, "", "") }
        let leading = String(chars[0..<start])
        let core = String(chars[start..<end])
        let trailing = String(chars[end..<chars.count])
        // A "word" must contain at least one letter or number; a lone "-" or
        // "'" is punctuation, not a maskable word.
        guard core.contains(where: { $0.isLetter || $0.isNumber }) else {
            return (raw, "", "")
        }
        return (leading, core, trailing)
    }

    /// Reduce each word to its first letter plus underscores, keeping the
    /// surrounding punctuation and spacing intact.
    static func firstLetters(_ text: String) -> String {
        tokenize(text).map { token in
            guard token.isWord, !token.core.isEmpty else { return token.text }
            let first = token.core.first.map(String.init) ?? ""
            let restCount = max(0, token.core.count - 1)
            let blanks = String(repeating: "_", count: restCount)
            return token.leading + first + blanks + token.trailing
        }.joined()
    }

    /// A blank glyph string matching a word's length (visual cue, not letters).
    static func blank(for core: String) -> String {
        String(repeating: "_", count: max(1, core.count))
    }

    /// Deterministically choose which word-token ids to hide for a blank level.
    /// Uses a seeded shuffle so blanks are spread out yet stable per (text+seed).
    static func maskedWordIDs(_ text: String, fraction: Double, seed: UInt64) -> Set<Int> {
        let words = tokenize(text).filter { $0.isWord && !$0.core.isEmpty }
        guard !words.isEmpty else { return [] }
        let clamped = min(max(fraction, 0), 1)
        let hideCount = Int((Double(words.count) * clamped).rounded())
        guard hideCount > 0 else { return [] }
        if hideCount >= words.count { return Set(words.map(\.id)) }

        var rng = SplitMix64(seed: seed &+ UInt64(words.count))
        let shuffled = words.shuffled(using: &rng)
        return Set(shuffled.prefix(hideCount).map(\.id))
    }

    // MARK: - Helpers

    static func wordCount(_ text: String) -> Int {
        tokenize(text).filter { $0.isWord && !$0.core.isEmpty }.count
    }

    /// Reading time in minutes, rounded up, assuming ~200 wpm.
    static func readingMinutes(_ text: String) -> Int {
        max(1, Int((Double(wordCount(text)) / 200.0).rounded(.up)))
    }
}
