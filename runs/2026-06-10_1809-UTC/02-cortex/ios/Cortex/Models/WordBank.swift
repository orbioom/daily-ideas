import Foundation

/// Common words for the Word Scramble game, grouped by length so difficulty can
/// pick longer words. All lowercase, no proper nouns.
enum WordBank {
    static let byLength: [Int: [String]] = {
        var d: [Int: [String]] = [:]
        for w in words {
            d[w.count, default: []].append(w)
        }
        return d
    }()

    static func words(forLength length: Int) -> [String] {
        byLength[length] ?? []
    }

    static let words: [String] = [
        // 4
        "calm", "mind", "idea", "grow", "leaf", "tide", "glow", "rest", "swim", "jump",
        "bold", "kind", "wave", "moon", "star", "rise", "open", "form", "play", "tune",
        // 5
        "brain", "focus", "logic", "spark", "quiet", "happy", "river", "cloud", "stone", "light",
        "dream", "smart", "learn", "think", "swift", "grace", "trust", "peace", "north", "ocean",
        // 6
        "memory", "puzzle", "reason", "matrix", "clever", "bright", "wisdom", "garden", "silver", "purple",
        "stream", "summit", "wonder", "branch", "enforce", "frozen", "marble", "velvet", "candle", "meadow",
        // 7
        "neurons", "balance", "harmony", "journey", "crystal", "thunder", "freedom", "compass", "lantern", "horizon",
        "diamond", "machine", "library", "gravity", "rainbow", "whisper", "blossom", "mariner", "kingdom", "quartet",
        // 8
        "patience", "strength", "synapse", "elephant", "mountain", "treasure", "infinity", "midnight", "sapphire", "daylight",
    ].filter { $0.allSatisfy { $0.isLetter } }
}
