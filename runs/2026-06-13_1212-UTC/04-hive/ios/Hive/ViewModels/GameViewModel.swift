import Foundation
import SwiftData

/// Drives one board: the current entry, the outer-ring order (for Shuffle), the
/// set of found words, scoring/ranking, and persistence into a `GameProgress`
/// record. Created fresh from a SwiftUI init, so it is intentionally *not*
/// `@MainActor`.
@Observable
final class GameViewModel {
    let puzzle: Puzzle
    let dayKey: String          // "" for practice, "yyyy-MM-dd" for daily

    /// The current letter sequence the player is building.
    var entry: String = ""
    /// The outer six letters in display order (mutated by Shuffle).
    var outerOrder: [Character]
    /// Words found so far, newest first.
    private(set) var found: [String] = []
    /// The latest toast to surface, consumed by the view.
    var toast: Toast?
    /// Set true the first time Genius is reached this session.
    private(set) var justReachedGenius = false

    private let context: ModelContext
    private var record: GameProgress?

    struct Toast: Equatable, Identifiable {
        enum Kind { case good, bad, pangram }
        let id = UUID()
        let message: String
        let kind: Kind
    }

    init(puzzle: Puzzle, dayKey: String, context: ModelContext) {
        self.puzzle = puzzle
        self.dayKey = dayKey
        self.context = context
        self.outerOrder = puzzle.outer
        loadOrCreateRecord()
    }

    // MARK: - Derived state

    var maxScore: Int { ScoreEngine.maxScore(puzzle) }
    var score: Int { ScoreEngine.currentScore(found: found, in: puzzle) }
    var rank: Rank { ScoreEngine.rank(for: score, max: maxScore) }
    var nextRank: Rank? { ScoreEngine.nextRank(for: score, max: maxScore) }
    var pointsToNext: Int { ScoreEngine.pointsToNext(score: score, max: maxScore) }
    var isGenius: Bool { ScoreEngine.isGenius(score: score, max: maxScore) }
    var pangramsFound: Int { found.filter { puzzle.isPangram($0) }.count }
    var totalPangrams: Int { puzzle.pangrams.count }

    /// Progress through the rank ladder, 0...1, for the progress bar.
    var rankProgress: Double {
        guard maxScore > 0 else { return 0 }
        return min(1.0, Double(score) / (Double(maxScore) * (ScoreEngine.ranks.last?.fraction ?? 1)))
    }

    var foundSorted: [String] { found.sorted() }

    // MARK: - Input

    func tap(_ ch: Character) {
        guard puzzle.letters.contains(ch) else { return }
        entry.append(ch)
        if UserDefaults.standard.object(forKey: "letterHaptic") as? Bool ?? true {
            Haptics.tap()
        }
    }

    func delete() {
        guard !entry.isEmpty else { return }
        entry.removeLast()
        Haptics.soft()
    }

    func clear() { entry = "" }

    /// Reorder the outer ring. Caller decides whether to animate (Reduce Motion).
    func shuffle() {
        outerOrder.shuffle()
        Haptics.soft()
    }

    /// Submit the current entry; updates state, toast, and persistence.
    func submit() {
        let result = ScoreEngine.validate(entry, puzzle: puzzle, alreadyFound: found)
        switch result {
        case .tooShort:
            toast = Toast(message: "Too short", kind: .bad); Haptics.warning()
        case .missingCenter:
            toast = Toast(message: "Missing centre letter", kind: .bad); Haptics.warning()
        case .badLetters:
            toast = Toast(message: "Bad letters", kind: .bad); Haptics.warning()
        case .notInWordList:
            toast = Toast(message: "Not in word list", kind: .bad); Haptics.warning()
        case .alreadyFound:
            toast = Toast(message: "Already found", kind: .bad); Haptics.warning()
        case let .accepted(word, points, isPangram):
            found.insert(word, at: 0)
            let wasGenius = record?.completedGenius ?? false
            persist()
            if isPangram {
                toast = Toast(message: "Pangram! +\(points)", kind: .pangram); Haptics.success()
            } else {
                toast = Toast(message: "+\(points)", kind: .good); Haptics.success()
            }
            if isGenius && !wasGenius {
                justReachedGenius = true
            }
        }
        entry = ""
    }

    func acknowledgeGenius() { justReachedGenius = false }

    // MARK: - Persistence

    private func loadOrCreateRecord() {
        let pid = puzzle.id
        let key = dayKey
        let descriptor = FetchDescriptor<GameProgress>(
            predicate: #Predicate { $0.puzzleID == pid && $0.dayKey == key })
        if let existing = try? context.fetch(descriptor).first {
            record = existing
            found = Array(existing.foundWords.reversed())   // newest first for display
        } else {
            let fresh = GameProgress(puzzleID: pid, dayKey: key)
            context.insert(fresh)
            record = fresh
            try? context.save()
        }
    }

    private func persist() {
        guard let record else { return }
        // Store oldest-first; `found` is newest-first.
        record.foundWords = Array(found.reversed())
        record.completedGenius = record.completedGenius || isGenius
        try? context.save()
    }
}
