import SwiftUI
import SwiftData

@Observable
class PuzzleViewModel {
    private(set) var puzzle: Puzzle
    private(set) var attempt: PuzzleAttempt?
    private(set) var displayWords: [String]
    private(set) var selectedWords: Set<String> = []
    private(set) var solvedGroups: [PuzzleGroup] = []
    private(set) var gameState: GameState = .playing
    private(set) var mistakesRemaining: Int = 4
    private(set) var shakeTrigger: Int = 0
    private(set) var oneAwayGroup: String? = nil
    private(set) var revealedGroups: [PuzzleGroup] = []

    enum GameState: Equatable { case playing, won, lost }

    init(puzzle: Puzzle, attempt: PuzzleAttempt?) {
        self.puzzle = puzzle
        self.attempt = attempt
        self.displayWords = puzzle.shuffledWords
        if let a = attempt {
            let solvedIds = Set(a.solvedGroupIds)
            self.solvedGroups = puzzle.groups.filter { solvedIds.contains($0.id) }
            self.mistakesRemaining = 4 - a.mistakesUsed
            if a.solved { self.gameState = .won }
            else if a.gaveUp { self.gameState = .lost }
        }
    }

    var canSubmit: Bool { selectedWords.count == 4 }
    var unsolvedWords: [String] {
        let solvedWordSet = Set(solvedGroups.flatMap(\.words))
        return displayWords.filter { !solvedWordSet.contains($0) }
    }

    func toggleWord(_ word: String) {
        guard gameState == .playing else { return }
        oneAwayGroup = nil
        if selectedWords.contains(word) {
            selectedWords.remove(word)
        } else if selectedWords.count < 4 {
            selectedWords.insert(word)
        }
    }

    func shuffleRemaining() {
        guard gameState == .playing else { return }
        let solvedWordSet = Set(solvedGroups.flatMap(\.words))
        var unsolved = displayWords.filter { !solvedWordSet.contains($0) }
        var rng = SeededRNG(seed: UInt64(Date().timeIntervalSince1970 * 1000))
        for i in stride(from: unsolved.count - 1, through: 1, by: -1) {
            let j = Int(rng.next() % UInt64(i + 1))
            unsolved.swapAt(i, j)
        }
        let solved = displayWords.filter { solvedWordSet.contains($0) }
        displayWords = solved + unsolved
    }

    func deselectAll() {
        selectedWords.removeAll()
    }

    func submitGuess(modelContext: ModelContext) {
        guard canSubmit, gameState == .playing else { return }
        let sel = selectedWords
        oneAwayGroup = nil

        if let match = puzzle.groups.first(where: {
            Set($0.words) == sel && !solvedGroups.contains($0)
        }) {
            // Correct
            solvedGroups.append(match)
            selectedWords.removeAll()
            let solvedWordSet = Set(solvedGroups.flatMap(\.words))
            displayWords = displayWords.filter { !solvedWordSet.contains($0) }

            updateAttempt(modelContext: modelContext, correct: true, groupId: match.id)

            if solvedGroups.count == 4 {
                gameState = .won
                saveAttempt(modelContext: modelContext, solved: true)
            }
        } else {
            // Wrong — check "one away"
            let threePlusMatch = puzzle.groups.first { group in
                !solvedGroups.contains(group) &&
                sel.intersection(group.words).count == 3
            }
            if let m = threePlusMatch {
                oneAwayGroup = m.category
            }
            mistakesRemaining -= 1
            shakeTrigger += 1
            updateAttempt(modelContext: modelContext, correct: false, groupId: nil)

            if mistakesRemaining == 0 {
                gameState = .lost
                revealedGroups = puzzle.groups.filter { !solvedGroups.contains($0) }
                saveAttempt(modelContext: modelContext, solved: false)
            }
        }
    }

    // MARK: - Persistence helpers

    private func updateAttempt(modelContext: ModelContext, correct: Bool, groupId: Int?) {
        let a = ensureAttempt(modelContext: modelContext)
        if !correct { a.mistakesUsed += 1 }
        if let gid = groupId, !a.solvedGroupIds.contains(gid) {
            a.solvedGroupIds.append(gid)
        }
    }

    private func saveAttempt(modelContext: ModelContext, solved: Bool) {
        let a = ensureAttempt(modelContext: modelContext)
        a.solved = solved
        a.gaveUp = !solved
    }

    private func ensureAttempt(modelContext: ModelContext) -> PuzzleAttempt {
        if let a = attempt { return a }
        let a = PuzzleAttempt(puzzleId: puzzle.id)
        modelContext.insert(a)
        attempt = a
        return a
    }
}
