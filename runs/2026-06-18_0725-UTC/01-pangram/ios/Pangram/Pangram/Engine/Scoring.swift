import Foundation

/// Pangram scoring rules: 4-letter word = 1 point; longer words score their length;
/// a pangram (uses all 7 distinct letters) earns a +7 bonus on top of its length.
enum Scoring {
    static let pangramBonus = 7

    static func points(for word: String, isPangram: Bool) -> Int {
        let len = word.count
        guard len >= 4 else { return 0 }
        let base = len == 4 ? 1 : len
        return base + (isPangram ? pangramBonus : 0)
    }

    /// Whether a word uses every one of the seven distinct letters.
    static func isPangram(_ word: String, letterSet: Set<Character>) -> Bool {
        Set(word) == letterSet
    }
}
