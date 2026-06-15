import SwiftUI
import Combine

/// Drives a single game session: board state, selection, timer, hints, shuffle,
/// undo, win/dead-end detection. Pure of SwiftData; persistence is handled by
/// the View layer via `snapshot()`.
@MainActor
final class GameViewModel: ObservableObject {

    enum Phase: Equatable {
        case generating
        case playing
        case paused
        case won
        case deadEnd
    }

    // Board / state
    @Published private(set) var board: Board
    @Published private(set) var phase: Phase = .generating
    @Published private(set) var selectedID: Int?
    @Published private(set) var freeIDs: Set<Int> = []
    @Published private(set) var hintPair: (Int, Int)?

    // Counters
    @Published private(set) var moves: Int = 0
    @Published private(set) var elapsedSec: Int = 0
    @Published private(set) var hintsUsed: Int = 0
    @Published private(set) var shufflesUsed: Int = 0

    // Context
    let isDaily: Bool
    let dailyDateKey: String?
    private(set) var undoStack: [SavedGameState.UndoEntry] = []

    private var rng: SeededRNG
    private var timer: AnyCancellable?

    var layout: LayoutKind { board.layout }
    var remainingCount: Int { board.remainingCount }
    var totalTiles: Int { board.tiles.count }

    // MARK: Init

    /// Create a session and (synchronously, cheaply) hold a generating board.
    /// Call `generate()` to fill it, or `restore(from:)` to resume.
    init(layout: LayoutKind, seed: UInt64, isDaily: Bool = false, dailyDateKey: String? = nil) {
        self.isDaily = isDaily
        self.dailyDateKey = dailyDateKey
        self.rng = SeededRNG(seed: seed)
        // Start with an empty (all-removed) board; the real one is assembled in
        // generate() off the main thread.
        let slots = layout.slots
        let emptyTiles = slots.indices.map { i in
            PlacedTile(id: i, face: .bamboo(1), slotIndex: i, removed: true)
        }
        self.board = Board(layout: layout, slots: slots, tiles: emptyTiles)
    }

    // MARK: Generation / restore

    /// Generate a fresh solvable board off the main thread, then publish.
    func generate() {
        phase = .generating
        let layout = board.layout
        let seed = rng.next()   // advance & snapshot a seed for this generation
        Task.detached(priority: .userInitiated) {
            var gen = SeededRNG(seed: seed)
            let fresh = SolvableDealer.deal(layout: layout, rng: &gen)
            await MainActor.run {
                self.board = fresh
                self.rng = gen
                self.beginPlay(resetCounters: true)
            }
        }
    }

    /// Restore a previously saved game state.
    func restore(from state: SavedGameState) {
        self.board = state.board
        self.moves = state.moves
        self.elapsedSec = state.elapsedSec
        self.hintsUsed = state.hintsUsed
        self.shufflesUsed = state.shufflesUsed
        self.undoStack = state.undoStack
        beginPlay(resetCounters: false)
    }

    private func beginPlay(resetCounters: Bool) {
        if resetCounters {
            moves = 0
            elapsedSec = 0
            hintsUsed = 0
            shufflesUsed = 0
            undoStack = []
        }
        selectedID = nil
        hintPair = nil
        recomputeFree()
        evaluatePhase(startTimerIfPlaying: true)
    }

    // MARK: Timer

    private func startTimer() {
        timer?.cancel()
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                if self.phase == .playing { self.elapsedSec += 1 }
            }
    }
    private func stopTimer() { timer?.cancel(); timer = nil }

    // MARK: Selection / matching

    /// Tap a tile. Returns a `TapOutcome` describing what happened (for haptics).
    enum TapOutcome { case ignored, selected, deselected, matched, mismatch }

    @discardableResult
    func tap(_ id: Int) -> TapOutcome {
        guard phase == .playing else { return .ignored }
        guard freeIDs.contains(id) else { return .ignored }
        hintPair = nil

        if selectedID == id {
            selectedID = nil
            return .deselected
        }
        guard let first = selectedID else {
            selectedID = id
            return .selected
        }
        // Attempt match
        if board.canMatch(first, id) {
            board.remove(first, id)
            undoStack.append(.init(idA: first, idB: id))
            moves += 1
            selectedID = nil
            recomputeFree()
            evaluatePhase(startTimerIfPlaying: false)
            return .matched
        } else {
            // Not a match: switch selection to the newly tapped tile.
            selectedID = id
            return .mismatch
        }
    }

    // MARK: Hints

    /// Returns true if a hint was shown; false if none available.
    @discardableResult
    func hint() -> Bool {
        guard phase == .playing else { return false }
        if let pair = board.availableMatch() {
            hintPair = pair
            hintsUsed += 1
            return true
        }
        return false
    }
    func clearHint() { hintPair = nil }

    var availableHintExists: Bool { board.hasAvailableMatch }

    // MARK: Shuffle

    /// Reshuffle remaining tiles, preserving solvability where possible.
    @discardableResult
    func shuffle() -> Bool {
        guard phase == .playing || phase == .deadEnd else { return false }
        var local = rng
        if let newBoard = board.reshuffled(using: &local) {
            board = newBoard
            rng = local
            shufflesUsed += 1
            selectedID = nil
            hintPair = nil
            recomputeFree()
            evaluatePhase(startTimerIfPlaying: false)
            return true
        }
        return false
    }

    // MARK: Undo

    var canUndo: Bool { !undoStack.isEmpty && (phase == .playing || phase == .deadEnd) }

    @discardableResult
    func undo() -> Bool {
        guard canUndo, let last = undoStack.popLast() else { return false }
        board.restore(last.idA, last.idB)
        moves = max(0, moves - 1)
        selectedID = nil
        hintPair = nil
        recomputeFree()
        evaluatePhase(startTimerIfPlaying: true)
        return true
    }

    // MARK: Pause / resume / restart

    func pause() {
        guard phase == .playing else { return }
        phase = .paused
        stopTimer()
    }
    func resume() {
        guard phase == .paused else { return }
        phase = .playing
        startTimer()
    }

    /// Re-deal a fresh solvable board for the same layout/seed family.
    func restart() {
        stopTimer()
        // Advance the RNG slightly so a restart isn't identical (except daily,
        // which should stay deterministic — daily restarts reuse the same seed).
        if !isDaily {
            _ = rng.next()
        } else if let key = dailyDateKey {
            rng = SeededRNG(seed: UInt64(stableSeed: key + board.layout.rawValue))
        }
        generate()
    }

    // MARK: Free / phase

    private func recomputeFree() {
        freeIDs = board.freeIDs()
    }

    private func evaluatePhase(startTimerIfPlaying: Bool) {
        if board.isCleared {
            phase = .won
            stopTimer()
        } else if !board.hasAvailableMatch {
            phase = .deadEnd
            stopTimer()
        } else {
            phase = .playing
            if startTimerIfPlaying { startTimer() }
        }
    }

    // MARK: Snapshot for persistence

    func snapshot() -> SavedGameState {
        SavedGameState(
            layout: board.layout,
            slots: board.slots,
            tiles: board.tiles,
            elapsedSec: elapsedSec,
            moves: moves,
            undoStack: undoStack,
            hintsUsed: hintsUsed,
            shufflesUsed: shufflesUsed,
            isDaily: isDaily,
            dailyDateKey: dailyDateKey
        )
    }

    deinit { timer?.cancel() }
}
