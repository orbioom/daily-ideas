import Foundation

/// One Spelling-Bee-style puzzle: seven distinct letters with one required
/// centre, the full curated list of accepted words, and the pangram subset.
///
/// Every puzzle is hand-authored and self-checked: `letters` holds exactly
/// seven distinct lowercase letters, `center` is one of them, every `answers`
/// entry is ≥4 letters, contains `center`, and uses only the seven letters,
/// and at least one `pangrams` entry uses all seven.
struct Puzzle: Identifiable, Hashable {
    let id: Int
    let letters: [Character]      // 7 unique, lowercased
    let center: Character          // one of `letters`
    let answers: [String]          // every accepted word for this puzzle
    let pangrams: [String]         // subset of answers using all 7 letters

    /// The six non-centre letters, for the outer ring of the honeycomb.
    var outer: [Character] { letters.filter { $0 != center } }

    /// A stable display string of the letter set (centre first).
    var letterSummary: String {
        ([center] + outer.sorted()).map { String($0).uppercased() }.joined(separator: " ")
    }

    /// True when `word` uses all seven letters at least once.
    func isPangram(_ word: String) -> Bool {
        Set(word) == Set(letters)
    }
}
