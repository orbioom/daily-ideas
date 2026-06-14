import SwiftUI
import SwiftData

/// Drives the playable board. Owned by the Game view as a @StateObject. Not an @Observable
/// macro type (per conventions) — a final class: ObservableObject with @Published state.
@MainActor
final class GameViewModel: ObservableObject {

    // MARK: Phases
    enum Phase: Equatable {
        case loading           // generating a puzzle off the main thread
        case playing
        case won
        case lost              // mistake limit reached
        case error(String)     // generation failed irrecoverably (uses fallback in practice)
    }

    // MARK: Published state
    @Published private(set) var phase: Phase = .loading
    @Published private(set) var givens: [Int] = [Int](repeating: 0, count: 81)
    @Published private(set) var current: [Int] = [Int](repeating: 0, count: 81)
    @Published private(set) var candidates: [Int] = [Int](repeating: 0, count: 81)
    @Published private(set) var solution: [Int] = [Int](repeating: 0, count: 81)
    @Published private(set) var conflicts: Set<Int> = []
    @Published var selected: Int? = nil
    @Published var pencilMode: Bool = false
    @Published private(set) var elapsedSec: Int = 0
    @Published private(set) var mistakes: Int = 0
    @Published private(set) var hintsUsed: Int = 0
    @Published private(set) var isPaused: Bool = false
    @Published var hintMessage: String? = nil
    @Published var lastHintIndex: Int? = nil

    // MARK: Config
    private(set) var difficulty: Difficulty = .easy
    private(set) var isDaily: Bool = false
    private(set) var dateKey: String = ""

    // MARK: Collaborators
    private weak var context: ModelContext?
    private var settings: AppSettings?
    private var saved: SavedGame?

    // Undo stack of (index, previousValue, previousCandidateMask).
    private struct Move { let index: Int; let prevValue: Int; let prevMask: Int }
    private var undoStack: [Move] = []

    private var timer: Timer?

    var freeHintLimit: Int { 3 }
    var canUseHint: Bool { Pro.isUnlocked || hintsUsed < freeHintLimit }

    // MARK: - Lifecycle

    func configure(context: ModelContext, settings: AppSettings) {
        self.context = context
        self.settings = settings
    }

    /// Resume an existing saved game (no generation needed).
    func resume(_ game: SavedGame, settings: AppSettings) {
        self.settings = settings
        self.saved = game
        self.difficulty = game.difficulty
        self.isDaily = game.isDaily
        self.dateKey = game.dateKey
        self.givens = normalized(game.givens)
        self.current = normalized(game.current)
        self.candidates = normalized(game.candidates)
        self.solution = normalized(game.solution)
        self.elapsedSec = max(0, game.elapsedSec)
        self.mistakes = max(0, game.mistakes)
        self.hintsUsed = max(0, game.hintsUsed)
        recomputeConflicts()
        phase = game.completed ? .won : .playing
        if phase == .playing { startTimer() }
    }

    /// Start a brand-new game; generation runs OFF the main thread, UI shows `.loading`.
    func startNew(difficulty: Difficulty, isDaily: Bool, settings: AppSettings) {
        self.settings = settings
        self.difficulty = difficulty
        self.isDaily = isDaily
        self.dateKey = isDaily ? DailySeed.dateKey(for: Date()) : ""
        phase = .loading

        let seed: UInt64? = isDaily ? DailySeed.seed(for: Date()) : nil
        let diff = difficulty
        Task.detached(priority: .userInitiated) { [weak self] in
            // Heavy work off the main actor.
            let puzzle = SudokuGenerator.generate(difficulty: diff, seed: seed)
            await self?.applyGenerated(puzzle)
        }
    }

    private func applyGenerated(_ puzzle: Puzzle) {
        guard puzzle.givens.count == 81, puzzle.solution.count == 81 else {
            phase = .error("Could not generate a puzzle. Please try again.")
            return
        }
        givens = puzzle.givens
        current = puzzle.givens
        candidates = [Int](repeating: 0, count: 81)
        solution = puzzle.solution
        elapsedSec = 0
        mistakes = 0
        hintsUsed = 0
        undoStack.removeAll()
        selected = firstEmptyCell()
        recomputeConflicts()
        phase = .playing
        persist(creating: true)
        startTimer()
    }

    // MARK: - Input

    func select(_ index: Int) {
        guard index >= 0, index < 81 else { return }
        selected = index
        lastHintIndex = nil
        hintMessage = nil
    }

    func enter(_ digit: Int) {
        guard phase == .playing, let index = selected, index >= 0, index < 81 else { return }
        guard digit >= 1, digit <= 9 else { return }
        guard givens.indices.contains(index), givens[index] == 0 else { return } // can't change a given

        let h = settings?.hapticsEnabled ?? false
        let auto = settings?.autoCandidateMode ?? false

        if pencilMode && !auto {
            pushUndo(index)
            let bit = 1 << (digit - 1)
            candidates[index] ^= bit
            current[index] = 0
            persist(creating: false)
            Haptics.selection(enabled: h)
            return
        }

        pushUndo(index)
        // Toggle off if same digit already there.
        if current[index] == digit {
            current[index] = 0
        } else {
            current[index] = digit
            candidates[index] = 0
        }
        recomputeConflicts()

        // Mistake checking (if enabled).
        if current[index] != 0, solution.indices.contains(index), current[index] != solution[index] {
            mistakes += 1
            Haptics.error(enabled: h)
            if (settings?.mistakeLimitOn ?? false), mistakes >= (settings?.mistakeLimit ?? 3) {
                gameOver()
                persist(creating: false)
                return
            }
        } else if current[index] != 0 {
            Haptics.place(enabled: h)
        }

        if auto { recomputeAutoCandidates() }
        persist(creating: false)
        checkWin()
    }

    func erase() {
        guard phase == .playing, let index = selected, index >= 0, index < 81 else { return }
        guard givens.indices.contains(index), givens[index] == 0 else { return }
        pushUndo(index)
        current[index] = 0
        candidates[index] = 0
        recomputeConflicts()
        if settings?.autoCandidateMode ?? false { recomputeAutoCandidates() }
        persist(creating: false)
    }

    func togglePencil() { pencilMode.toggle() }

    func undo() {
        guard phase == .playing, let move = undoStack.popLast() else { return }
        guard move.index >= 0, move.index < 81 else { return }
        current[move.index] = move.prevValue
        candidates[move.index] = move.prevMask
        recomputeConflicts()
        if settings?.autoCandidateMode ?? false { recomputeAutoCandidates() }
        persist(creating: false)
    }

    private func pushUndo(_ index: Int) {
        guard index >= 0, index < 81 else { return }
        undoStack.append(Move(index: index, prevValue: current[index], prevMask: candidates[index]))
        if undoStack.count > 200 { undoStack.removeFirst(undoStack.count - 200) }
    }

    // MARK: - Hint

    /// Reveal the next logical step. Returns false if blocked by the free-hint paywall.
    @discardableResult
    func hint() -> Bool {
        guard phase == .playing else { return true }
        guard canUseHint else { return false }

        if let d = SudokuSolver.nextDeduction(current), d.index >= 0, d.index < 81 {
            pushUndo(d.index)
            current[d.index] = d.value
            candidates[d.index] = 0
            hintsUsed += 1
            selected = d.index
            lastHintIndex = d.index
            hintMessage = d.explanation
            recomputeConflicts()
            if settings?.autoCandidateMode ?? false { recomputeAutoCandidates() }
            Haptics.place(enabled: settings?.hapticsEnabled ?? false)
            persist(creating: false)
            checkWin()
            return true
        }

        // No logical step found — fill the selected cell from the solution as a safe net.
        if let index = selected, index >= 0, index < 81, givens.indices.contains(index),
           givens[index] == 0, solution.indices.contains(index) {
            pushUndo(index)
            current[index] = solution[index]
            candidates[index] = 0
            hintsUsed += 1
            lastHintIndex = index
            hintMessage = "Filled from the solution."
            recomputeConflicts()
            Haptics.place(enabled: settings?.hapticsEnabled ?? false)
            persist(creating: false)
            checkWin()
        } else {
            hintMessage = "Select an empty cell for a hint."
        }
        return true
    }

    // MARK: - Pause / timer

    func togglePause() {
        guard phase == .playing else { return }
        isPaused.toggle()
        if isPaused { stopTimer() } else { startTimer() }
    }

    func pauseForBackground() {
        stopTimer()
        persist(creating: false)
    }

    func resumeFromForeground() {
        if phase == .playing, !isPaused { startTimer() }
    }

    private func startTimer() {
        stopTimer()
        let t = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard phase == .playing, !isPaused else { return }
        elapsedSec += 1
        // Persist time roughly every 5 seconds to limit write churn.
        if elapsedSec % 5 == 0 { persist(creating: false) }
    }

    // MARK: - Win / loss

    private func checkWin() {
        guard phase == .playing else { return }
        guard current.count == 81, solution.count == 81 else { return }
        for i in 0..<81 where current[i] != solution[i] { return }
        win()
    }

    private func win() {
        phase = .won
        stopTimer()
        Haptics.win(enabled: settings?.hapticsEnabled ?? false)
        if let saved {
            saved.completed = true
            saved.isActive = false
            saved.lastPlayed = Date()
            saved.current = current
            saved.elapsedSec = elapsedSec
            saved.mistakes = mistakes
            saved.hintsUsed = hintsUsed
        }
        let record = GameRecord(difficulty: difficulty, timeSec: elapsedSec, won: true,
                                isDaily: isDaily, mistakes: mistakes, hintsUsed: hintsUsed,
                                dateKey: DailySeed.dateKey(for: Date()))
        context?.insert(record)
        if isDaily { StreakStore.recordDailySolved() }
        try? context?.save()
    }

    private func gameOver() {
        phase = .lost
        stopTimer()
        Haptics.error(enabled: settings?.hapticsEnabled ?? false)
        if let saved {
            saved.completed = true
            saved.isActive = false
            saved.lastPlayed = Date()
        }
        let record = GameRecord(difficulty: difficulty, timeSec: elapsedSec, won: false,
                                isDaily: isDaily, mistakes: mistakes, hintsUsed: hintsUsed,
                                dateKey: DailySeed.dateKey(for: Date()))
        context?.insert(record)
        try? context?.save()
    }

    // MARK: - Persistence

    private func persist(creating: Bool) {
        guard let context else { return }
        if creating || saved == nil {
            // Deactivate any prior active saved game for this slot (daily vs casual).
            deactivatePriorSlot()
            let game = SavedGame(givens: givens, current: current, candidates: candidates,
                                 solution: solution, difficulty: difficulty, isDaily: isDaily,
                                 dateKey: dateKey, elapsedSec: elapsedSec, mistakes: mistakes,
                                 hintsUsed: hintsUsed, completed: false, isActive: true)
            context.insert(game)
            saved = game
        } else if let saved {
            saved.current = current
            saved.candidates = candidates
            saved.elapsedSec = elapsedSec
            saved.mistakes = mistakes
            saved.hintsUsed = hintsUsed
            saved.lastPlayed = Date()
        }
        try? context.save()
    }

    private func deactivatePriorSlot() {
        guard let context else { return }
        let wantDaily = isDaily
        let descriptor = FetchDescriptor<SavedGame>(predicate: #Predicate { $0.isActive == true })
        if let active = try? context.fetch(descriptor) {
            for g in active where g.isDaily == wantDaily && !g.completed {
                g.isActive = false
            }
        }
    }

    // MARK: - Helpers

    private func recomputeConflicts() {
        guard settings?.conflictHighlight ?? true else { conflicts = []; return }
        conflicts = SudokuSolver.conflicts(in: current)
    }

    private func recomputeAutoCandidates() {
        let masks = SudokuSolver.candidateMasks(current)
        var out = [Int](repeating: 0, count: 81)
        for i in 0..<81 where current[i] == 0 && givens[i] == 0 {
            out[i] = masks[i]
        }
        candidates = out
    }

    private func firstEmptyCell() -> Int? {
        for i in 0..<81 where current[i] == 0 { return i }
        return nil
    }

    /// Ensure an `[Int]` is exactly length 81 (defensive against malformed persistence).
    private func normalized(_ arr: [Int]) -> [Int] {
        if arr.count == 81 { return arr }
        var out = [Int](repeating: 0, count: 81)
        for i in 0..<min(81, arr.count) { out[i] = arr[i] }
        return out
    }

    // MARK: - Read helpers for the View

    func value(at index: Int) -> Int {
        guard index >= 0, index < 81 else { return 0 }
        return current[index]
    }

    func isGiven(_ index: Int) -> Bool {
        guard index >= 0, index < 81 else { return false }
        return givens[index] != 0
    }

    func candidateMask(at index: Int) -> Int {
        guard index >= 0, index < 81 else { return 0 }
        return candidates[index]
    }

    /// True when all 9 of `digit` are correctly placed (used to dim the pad).
    func isComplete(_ digit: Int) -> Bool {
        guard digit >= 1, digit <= 9 else { return false }
        var count = 0
        for i in 0..<81 where current[i] == digit { count += 1 }
        return count >= 9
    }

    var elapsedFormatted: String {
        let m = elapsedSec / 60, s = elapsedSec % 60
        return String(format: "%02d:%02d", m, s)
    }
}
