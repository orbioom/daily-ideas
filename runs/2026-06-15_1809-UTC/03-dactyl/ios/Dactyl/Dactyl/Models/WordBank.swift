import Foundation

/// A bundled common-English word bank used to stream random words into timed tests.
enum WordBank {
    /// ~200 of the most frequent English words (lowercase, no punctuation) — plenty of
    /// variety for timed tests while staying easy to type.
    static let words: [String] = [
        "the", "of", "and", "a", "to", "in", "is", "you", "that", "it",
        "he", "was", "for", "on", "are", "as", "with", "his", "they", "at",
        "be", "this", "have", "from", "or", "one", "had", "by", "word", "but",
        "not", "what", "all", "were", "we", "when", "your", "can", "said", "there",
        "use", "an", "each", "which", "she", "do", "how", "their", "if", "will",
        "up", "other", "about", "out", "many", "then", "them", "these", "so", "some",
        "her", "would", "make", "like", "him", "into", "time", "has", "look", "two",
        "more", "write", "go", "see", "number", "no", "way", "could", "people", "my",
        "than", "first", "water", "been", "call", "who", "oil", "now", "find", "long",
        "down", "day", "did", "get", "come", "made", "may", "part", "over", "new",
        "sound", "take", "only", "little", "work", "know", "place", "year", "live", "me",
        "back", "give", "most", "very", "after", "thing", "our", "just", "name", "good",
        "sentence", "man", "think", "say", "great", "where", "help", "through", "much", "before",
        "line", "right", "too", "mean", "old", "any", "same", "tell", "boy", "follow",
        "came", "want", "show", "also", "around", "form", "three", "small", "set", "put",
        "end", "does", "another", "well", "large", "must", "big", "even", "such", "because",
        "turn", "here", "why", "ask", "went", "men", "read", "need", "land", "different",
        "home", "us", "move", "try", "kind", "hand", "picture", "again", "change", "off",
        "play", "spell", "air", "away", "animal", "house", "point", "page", "letter", "mother",
        "answer", "found", "study", "still", "learn", "should", "world", "high", "every", "near"
    ]

    /// A reproducible-ish stream of random words. Uses a seeded generator so the same
    /// `seed` yields the same sequence (useful for previews); pass a fresh seed for variety.
    static func stream(count: Int, seed: UInt64) -> [String] {
        guard count > 0, !words.isEmpty else { return [] }
        var rng = SeededGenerator(seed: seed)
        var out: [String] = []
        out.reserveCapacity(count)
        for _ in 0..<count {
            let idx = Int(rng.next() % UInt64(words.count))
            out.append(words[idx])
        }
        return out
    }
}

/// A small deterministic SplitMix64 generator (no force-unwrap, no Foundation randomness needed).
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        // Avoid an all-zero state.
        self.state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
