import SwiftUI
import Observation

/// The result of submitting a candidate word.
enum SubmitOutcome: Equatable {
    case foundTarget(String)   // matched a placed grid word, now revealed
    case bonus(String)         // valid word not on the grid → bonus collection
    case alreadyFound          // already discovered (grid or bonus)
    case invalid               // not a valid word for this level
}

/// Drives a single level of play. Pure-ish game state on top of a precomputed
/// `CrosswordLayout`; persistence is handled by the view via callbacks.
@MainActor
@Observable
final class GameModel {
    let level: Level
    let layout: CrosswordLayout

    /// Letters shown on the wheel (a shuffleable arrangement of the base letters).
    private(set) var wheelLetters: [WheelLetter]

    /// Words placed on the grid that the player has already found.
    private(set) var foundGridWords: Set<String> = []
    /// Bonus words discovered this session (valid, not on the grid).
    private(set) var bonusWords: [String] = []
    /// Cells currently revealed (player found the word containing them).
    private(set) var revealedCells: Set<GridCoord> = []
    /// Cells revealed specifically by a hint (shown even before the word is found).
    private(set) var hintedCells: Set<GridCoord> = []

    /// The in-progress selection (indices into `wheelLetters`).
    private(set) var selection: [Int] = []

    private(set) var hintsRemaining: Int

    /// All valid words for this level (grid targets + curated extras), uppercased.
    private let validWords: Set<String>

    init(level: Level, isPro: Bool, hardMode: Bool) {
        self.level = level
        let built = CrosswordPacker.pack(words: level.targetWords, levelID: level.id)
        self.layout = built

        // Build the wheel from the base letters, shuffled deterministically by id.
        var rng = SeededRandom(seedString: level.id + "-wheel")
        var letters = level.letterMultiset.allLetters
        letters.shuffle(using: &rng)
        self.wheelLetters = letters.enumerated().map { WheelLetter(slot: $0.offset, letter: $0.element) }

        // Valid words: any target word that is formable plus curated extras.
        let bag = level.letterMultiset
        var valid = Set<String>()
        for w in level.targetWords where bag.canForm(w) { valid.insert(w.uppercased()) }
        for w in level.extraBonusWords where bag.canForm(w) { valid.insert(w.uppercased()) }
        self.validWords = valid

        let cap = isPro ? Int.max : Pro.freeHintCap
        let start = hardMode ? max(1, cap == Int.max ? 99 : cap - 2) : (cap == Int.max ? 99 : cap)
        self.hintsRemaining = start
    }

    // MARK: - Derived state

    /// All placed (grid) target words, uppercased.
    var placedWords: [String] { layout.placed.map { $0.word.uppercased() } }

    var totalGridWords: Int { Set(placedWords).count }

    var foundGridCount: Int { foundGridWords.count }

    var isComplete: Bool {
        totalGridWords > 0 && foundGridCount >= totalGridWords
    }

    var hasUnlimitedHints: Bool { hintsRemaining >= 99 }

    /// The string currently being spelled out by the selection.
    var currentCandidate: String {
        String(selection.compactMap { idx in
            wheelLetters.indices.contains(idx) ? wheelLetters[idx].letter : nil
        })
    }

    // MARK: - Selection

    func beginSelection(at slot: Int) {
        selection = wheelLetters.indices.contains(slot) ? [slot] : []
    }

    func extendSelection(to slot: Int) {
        guard wheelLetters.indices.contains(slot) else { return }
        if let last = selection.last, last == slot { return }
        // Allow back-tracking: if user returns to the previous letter, pop.
        if selection.count >= 2, selection[selection.count - 2] == slot {
            selection.removeLast()
            return
        }
        if !selection.contains(slot) {
            selection.append(slot)
        }
    }

    func toggleTap(_ slot: Int) {
        guard wheelLetters.indices.contains(slot) else { return }
        if let pos = selection.firstIndex(of: slot) {
            // Tapping a selected letter removes it and anything after it.
            selection.removeSubrange(pos...)
        } else {
            selection.append(slot)
        }
    }

    func clearSelection() {
        selection.removeAll()
    }

    // MARK: - Submission

    func submit() -> SubmitOutcome {
        let word = currentCandidate.uppercased()
        defer { clearSelection() }
        guard word.count >= 2 else { return .invalid }

        // Must be formable from the base letters (count-aware safety net).
        guard level.letterMultiset.canForm(word) else { return .invalid }

        if placedWords.contains(word) {
            if foundGridWords.contains(word) { return .alreadyFound }
            revealWord(word)
            foundGridWords.insert(word)
            return .foundTarget(word)
        }

        if validWords.contains(word) {
            if bonusWords.contains(word) { return .alreadyFound }
            bonusWords.append(word)
            return .bonus(word)
        }

        return .invalid
    }

    private func revealWord(_ word: String) {
        for placed in layout.placed where placed.word.uppercased() == word {
            for cell in placed.cells { revealedCells.insert(cell) }
        }
    }

    // MARK: - Shuffle & Hint

    func shuffle() {
        var rng = SystemRandomNumberGenerator()
        wheelLetters.shuffle(using: &rng)
        // Re-slot so positions remain stable for the layout ring.
        wheelLetters = wheelLetters.enumerated().map { WheelLetter(slot: $0.offset, letter: $0.element.letter) }
        clearSelection()
    }

    /// Reveal a single unrevealed letter of an unfound grid word.
    /// Returns the coordinate revealed, or nil if no hint could be applied.
    @discardableResult
    func useHint() -> GridCoord? {
        guard hintsRemaining > 0 else { return nil }
        // Prefer the shortest unfound word so a hint feels impactful.
        let unfound = layout.placed
            .filter { !foundGridWords.contains($0.word.uppercased()) }
            .sorted { $0.word.count < $1.word.count }
        for placed in unfound {
            for cell in placed.cells where !revealedCells.contains(cell) && !hintedCells.contains(cell) {
                hintedCells.insert(cell)
                if !hasUnlimitedHints { hintsRemaining -= 1 }
                return cell
            }
        }
        return nil
    }

    /// Whether a cell's letter should currently be shown.
    func isVisible(_ coord: GridCoord) -> Bool {
        revealedCells.contains(coord) || hintedCells.contains(coord)
    }

    // MARK: - Scoring

    /// Stars 1–3 based on bonus discovery and hints used (or Relaxed always 3).
    func computeStars(relaxed: Bool) -> Int {
        guard isComplete else { return 0 }
        if relaxed { return 3 }
        var stars = 1
        if bonusWords.count >= 2 { stars += 1 }
        if hintedCells.isEmpty { stars += 1 }
        return min(3, max(1, stars))
    }
}

/// A single tile on the letter wheel.
struct WheelLetter: Identifiable, Equatable {
    let slot: Int
    let letter: Character
    var id: Int { slot }
}
