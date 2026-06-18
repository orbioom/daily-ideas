import Foundation

/// Result of validating a typed word against a puzzle and the words already found.
enum ValidationResult: Equatable {
    case tooShort
    case missingCenter
    case badLetters
    case notInList
    case alreadyFound
    case accepted(points: Int, isPangram: Bool)

    var isAccepted: Bool {
        if case .accepted = self { return true }
        return false
    }

    /// Short user-facing message for rejected words.
    var message: String {
        switch self {
        case .tooShort: return "Too short"
        case .missingCenter: return "Missing center letter"
        case .badLetters: return "Bad letters"
        case .notInList: return "Not in word list"
        case .alreadyFound: return "Already found"
        case .accepted(_, let isPangram): return isPangram ? "Pangram!" : "Nice!"
        }
    }
}

enum WordValidator {
    /// Validate a typed word. Order of checks matches the player's likely intent
    /// (length → center → letters → membership → duplicate).
    static func validate(
        _ raw: String,
        puzzle: Puzzle,
        foundWords: Set<String>
    ) -> ValidationResult {
        let word = raw.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        guard word.count >= 4 else { return .tooShort }
        guard word.contains(puzzle.center) else { return .missingCenter }

        let letterSet = puzzle.letterSet
        guard Set(word).isSubset(of: letterSet) else { return .badLetters }

        guard WordData.wordSet.contains(word) else { return .notInList }
        guard !foundWords.contains(word) else { return .alreadyFound }

        let isP = Scoring.isPangram(word, letterSet: letterSet)
        let pts = Scoring.points(for: word, isPangram: isP)
        return .accepted(points: pts, isPangram: isP)
    }
}
