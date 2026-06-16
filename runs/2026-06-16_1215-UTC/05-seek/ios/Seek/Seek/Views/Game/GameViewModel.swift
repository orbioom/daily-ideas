import SwiftUI
import SwiftData
import Observation

/// Drives a single puzzle session: board, selection, found words, timer, hints, persistence.
@MainActor
@Observable
final class GameViewModel {

    // MARK: Configuration
    let puzzle: Puzzle
    let packName: String
    let isDaily: Bool
    let dailyDateKey: String?

    // MARK: Generated content
    private(set) var board: WordSearchBoard
    /// Words to find, in display order (sorted longest-first then alphabetical).
    private(set) var allWords: [String]

    // MARK: Runtime state
    private(set) var foundWords: Set<String> = []
    private(set) var elapsedSec: Int = 0
    private(set) var isPaused = false
    private(set) var isComplete = false
    private(set) var bestTimeSec: Int?
    private(set) var didSetNewBest = false

    /// The live drag selection path (cells currently highlighted).
    var selectionPath: [GridPoint] = []
    /// Briefly highlighted hint cell (first letter of an unfound word).
    private(set) var hintCell: GridPoint?
    private(set) var hintsUsed = 0

    /// A short-lived flash for the most recently found word (drives a success animation).
    private(set) var lastFoundFlash: String?

    private var timer: Timer?
    private let allowHints: Bool
    private var hintLimit: Int

    var total: Int { allWords.count }
    var foundCount: Int { foundWords.count }
    var progress: Double { total == 0 ? 0 : Double(foundCount) / Double(total) }
    var hintsRemaining: Int { max(0, hintLimit - hintsUsed) }
    var canUseHint: Bool { allowHints && hintsRemaining > 0 && !isComplete }

    init(
        puzzle: Puzzle,
        packName: String,
        words: [String],
        difficulty: Difficulty,
        isDaily: Bool = false,
        dailyDateKey: String? = nil,
        allowDiagonals: Bool,
        allowReverse: Bool,
        isPro: Bool
    ) {
        self.puzzle = puzzle
        self.packName = packName
        self.isDaily = isDaily
        self.dailyDateKey = dailyDateKey

        let directions = difficulty.directions(allowDiagonals: allowDiagonals, allowReverse: allowReverse)
        let generated = WordSearchGenerator.generate(
            words: words,
            size: difficulty.gridSize,
            directions: directions,
            targetCount: difficulty.targetWordCount,
            seed: puzzle.seed
        )
        self.board = generated
        self.allWords = generated.words.sorted {
            $0.count == $1.count ? $0 < $1 : $0.count > $1.count
        }

        if isPro {
            self.allowHints = true
            self.hintLimit = Int.max
        } else {
            self.allowHints = true
            self.hintLimit = FreeTier.hintsPerPuzzle
        }
    }

    // MARK: Lifecycle

    /// Grants unlimited hints once Pro status is known (set after the view appears).
    func applyPro(_ isPro: Bool) {
        if isPro { hintLimit = Int.max }
    }

    /// Restores prior progress (found words, elapsed time, best) if a record exists.
    func restore(from progress: PuzzleProgress?) {
        guard let progress else { return }
        foundWords = Set(progress.foundWords.filter { board.placements.keys.contains($0) })
        elapsedSec = max(0, progress.elapsedSec)
        bestTimeSec = progress.bestTimeSec
        isComplete = progress.isComplete || (!allWords.isEmpty && foundWords.count >= allWords.count)
    }

    func start() {
        guard !isComplete else { return }
        startTimer()
    }

    func startTimer() {
        guard timer == nil, !isPaused, !isComplete else { return }
        let t = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                if !self.isPaused && !self.isComplete {
                    self.elapsedSec += 1
                }
            }
        }
        timer = t
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    func togglePause() {
        isPaused.toggle()
        if isPaused {
            stopTimer()
        } else {
            startTimer()
        }
    }

    // MARK: Selection

    /// Updates the live highlight band as the finger moves.
    func updateSelection(start: GridPoint, current: GridPoint) {
        guard !isPaused, !isComplete else { return }
        if let path = SelectionValidator.path(from: start, to: current, size: board.size) {
            selectionPath = path
        } else {
            // Not on a straight line: keep just the origin cell highlighted.
            selectionPath = [start]
        }
    }

    /// Validates the current selection on release. Returns the matched word, if any.
    @discardableResult
    func commitSelection(hapticsEnabled: Bool) -> String? {
        defer { selectionPath = [] }
        guard !selectionPath.isEmpty, !isComplete else { return nil }
        if let matched = SelectionValidator.match(
            path: selectionPath,
            board: board,
            alreadyFound: foundWords
        ) {
            registerFound(matched, hapticsEnabled: hapticsEnabled)
            return matched
        }
        return nil
    }

    private func registerFound(_ word: String, hapticsEnabled: Bool) {
        guard !foundWords.contains(word) else { return }
        foundWords.insert(word)
        lastFoundFlash = word
        Haptics.notify(.success, enabled: hapticsEnabled)

        if !allWords.isEmpty && foundWords.count >= allWords.count {
            finish(hapticsEnabled: hapticsEnabled)
        }

        // Clear the flash shortly after for re-trigger on next find.
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 700_000_000)
            if lastFoundFlash == word { lastFoundFlash = nil }
        }
    }

    private func finish(hapticsEnabled: Bool) {
        isComplete = true
        stopTimer()
        if let best = bestTimeSec {
            if elapsedSec < best {
                bestTimeSec = elapsedSec
                didSetNewBest = true
            }
        } else {
            bestTimeSec = elapsedSec
            didSetNewBest = true
        }
        Haptics.notify(.success, enabled: hapticsEnabled)
    }

    // MARK: Hints

    /// Briefly reveals the first letter of a random unfound word.
    func useHint(hapticsEnabled: Bool) {
        guard canUseHint else { return }
        let unfound = allWords.filter { !foundWords.contains($0) }
        guard !unfound.isEmpty else { return }
        var rng = SeededRNG(seed: puzzle.seed &+ UInt64(hintsUsed) &+ 1)
        guard let word = rng.pick(unfound), let path = board.placements[word], let first = path.first else {
            return
        }
        hintsUsed += 1
        hintCell = first
        Haptics.impact(.light, enabled: hapticsEnabled)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            if hintCell == first { hintCell = nil }
        }
    }

    // MARK: Cell helpers

    func letter(row: Int, col: Int) -> Character {
        board.letter(at: GridPoint(row, col))
    }

    /// Whether a cell belongs to an already-found word (drawn permanently).
    func isFoundCell(_ point: GridPoint) -> Bool {
        for word in foundWords {
            if let path = board.placements[word], path.contains(point) {
                return true
            }
        }
        return false
    }

    func isSelected(_ point: GridPoint) -> Bool {
        selectionPath.contains(point)
    }

    // MARK: Persistence

    /// Writes the current session into SwiftData, creating the record if needed.
    func persist(context: ModelContext) {
        let key = puzzle.key
        let descriptor = FetchDescriptor<PuzzleProgress>(
            predicate: #Predicate { $0.puzzleKey == key }
        )
        let existing = (try? context.fetch(descriptor))?.first

        let seedInt = Int(bitPattern: UInt(truncatingIfNeeded: puzzle.seed))
        let completedDate: Date? = isComplete ? .now : nil

        if let record = existing {
            record.foundWords = Array(foundWords)
            record.isComplete = isComplete
            record.elapsedSec = elapsedSec
            record.gridSize = board.size
            if isComplete {
                record.completedDate = record.completedDate ?? completedDate
                if let best = bestTimeSec {
                    record.bestTimeSec = best
                }
            }
        } else {
            let record = PuzzleProgress(
                puzzleKey: key,
                packName: packName,
                difficultyRaw: puzzle.difficulty.rawValue,
                seed: seedInt,
                gridSize: board.size,
                foundWords: Array(foundWords),
                isComplete: isComplete,
                elapsedSec: elapsedSec,
                bestTimeSec: isComplete ? bestTimeSec : nil,
                startedDate: .now,
                completedDate: completedDate
            )
            context.insert(record)
        }

        if isDaily, let dayKey = dailyDateKey {
            persistDaily(context: context, dayKey: dayKey, seedInt: seedInt)
        }

        try? context.save()
    }

    private func persistDaily(context: ModelContext, dayKey: String, seedInt: Int) {
        let descriptor = FetchDescriptor<DailyResult>(
            predicate: #Predicate { $0.dateKey == dayKey }
        )
        let existing = (try? context.fetch(descriptor))?.first
        if let record = existing {
            record.foundCount = foundCount
            record.total = total
            record.timeSec = elapsedSec
            record.completed = isComplete
        } else {
            let record = DailyResult(
                dateKey: dayKey,
                seed: seedInt,
                timeSec: elapsedSec,
                foundCount: foundCount,
                total: total,
                completed: isComplete
            )
            context.insert(record)
        }
    }
}
