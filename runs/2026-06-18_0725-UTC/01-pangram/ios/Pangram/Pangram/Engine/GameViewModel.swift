import Foundation
import SwiftData
import Observation

/// Drives a single puzzle session: current word, found words, score, rank, and persistence.
@MainActor
@Observable
final class GameViewModel {
    let puzzle: Puzzle

    private(set) var typed: String = ""
    private(set) var foundWords: [String] = []
    private(set) var score: Int = 0
    private(set) var displayOrder: [Character]

    /// Transient feedback for the last submit.
    var lastResult: ValidationResult?
    var lastResultToken: Int = 0
    /// Rank toast payload when the player crosses into a new rank.
    var pendingRankToast: Rank?

    private let context: ModelContext
    private var saved: SavedPuzzle?

    init(puzzle: Puzzle, context: ModelContext) {
        self.puzzle = puzzle
        self.context = context
        self.displayOrder = puzzle.outer
        loadOrCreateSaved()
    }

    var foundSet: Set<String> { Set(foundWords) }

    var rank: Rank { RankLadder.rank(score: score, max: puzzle.totalPossibleScore) }

    var progressFraction: Double {
        guard puzzle.totalPossibleScore > 0 else { return 0 }
        return min(1, Double(score) / Double(puzzle.totalPossibleScore))
    }

    var foundPangrams: [String] {
        foundWords.filter { Scoring.isPangram($0, letterSet: puzzle.letterSet) }
    }

    var isComplete: Bool { foundWords.count >= puzzle.solutions.count }

    // MARK: - Input

    func append(_ letter: Character) {
        guard typed.count < 24 else { return }
        typed.append(letter)
    }

    func deleteLast() {
        if !typed.isEmpty { typed.removeLast() }
    }

    func clearTyped() { typed = "" }

    func shuffleOuter() {
        var rng = SplitMix64(seed: UInt64(Date().timeIntervalSince1970 * 1000))
        displayOrder.shuffle(using: &rng)
    }

    // MARK: - Submit

    @discardableResult
    func submit() -> ValidationResult {
        let candidate = typed
        let result = WordValidator.validate(candidate, puzzle: puzzle, foundWords: foundSet)
        lastResult = result
        lastResultToken &+= 1

        if case .accepted(let points, _) = result {
            let previousRank = rank
            foundWords.append(candidate.lowercased())
            foundWords.sort()
            score += points
            persist()
            let newRank = rank
            if newRank.rawValue > previousRank.rawValue {
                pendingRankToast = newRank
            }
        }
        typed = ""
        return result
    }

    /// Clears the transient feedback toast (called after a short delay by the view).
    func clearFeedback() {
        lastResult = nil
    }

    // MARK: - Persistence

    private func loadOrCreateSaved() {
        let targetID = puzzle.id
        let descriptor = FetchDescriptor<SavedPuzzle>(
            predicate: #Predicate { $0.id == targetID }
        )
        if let existing = try? context.fetch(descriptor).first {
            saved = existing
            foundWords = existing.foundWords.sorted()
            recomputeScore()
        } else {
            let new = SavedPuzzle(
                id: puzzle.id,
                dateKey: puzzle.dateKey,
                isDaily: puzzle.isDaily,
                centerLetter: String(puzzle.center),
                outerLetters: puzzle.outer.map { String($0) },
                seedIndex: puzzle.seedIndex,
                foundWords: [],
                createdAt: Date()
            )
            context.insert(new)
            saved = new
            try? context.save()
        }
    }

    private func recomputeScore() {
        var total = 0
        for word in foundWords {
            let isP = Scoring.isPangram(word, letterSet: puzzle.letterSet)
            total += Scoring.points(for: word, isPangram: isP)
        }
        score = total
    }

    private func persist() {
        guard let saved else { return }
        saved.foundWords = foundWords
        try? context.save()
        if puzzle.isDaily {
            DailyResultStore.upsert(
                context: context,
                puzzle: puzzle,
                score: score,
                wordsFound: foundWords.count,
                pangrams: foundPangrams.count,
                reachedGenius: rank.isGeniusOrAbove
            )
        }
    }
}
