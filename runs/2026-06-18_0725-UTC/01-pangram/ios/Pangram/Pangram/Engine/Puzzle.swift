import Foundation

/// A fully-resolved puzzle: the letters, the computed solution set, and derived scoring data.
struct Puzzle: Identifiable, Hashable {
    let id: String
    let dateKey: String
    let isDaily: Bool
    let seedIndex: Int
    let center: Character
    let outer: [Character]

    /// All valid solution words (length ≥ 4, only the seven letters, contains center).
    let solutions: [String]
    /// The subset of solutions that are pangrams.
    let pangrams: [String]
    /// Maximum achievable score for this puzzle.
    let totalPossibleScore: Int

    var letterSet: Set<Character> {
        var s = Set(outer)
        s.insert(center)
        return s
    }

    /// Outer letters plus center, used when shuffling the board display.
    var allLetters: [Character] { outer + [center] }

    static func == (lhs: Puzzle, rhs: Puzzle) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
