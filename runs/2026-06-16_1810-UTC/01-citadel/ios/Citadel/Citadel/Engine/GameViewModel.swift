import Foundation
import Observation
import SwiftData

/// The observable game state that GameView binds to. Wraps the pure engine, owns the
/// undo stack and timer, and persists progress to a single SavedGame record.
@MainActor
@Observable
final class GameViewModel {

    // MARK: - Public observable state
    private(set) var board: Board
    private(set) var dealNumber: Int
    private(set) var moveCount: Int = 0
    private(set) var elapsedSeconds: Int = 0
    private(set) var hasWon: Bool = false

    /// Currently selected source (for tap-to-move). Nil when nothing is picked up.
    var selection: Location?

    /// A transient calm error message to show in a banner; cleared by the view.
    var errorMessage: String?

    /// Undo snapshots (each entry is the board *before* a move, paired with the prior move count).
    private(set) var undoStack: [(board: Board, moves: Int)] = []
    private(set) var undosUsed: Int = 0

    /// Free-tier undo limit; Pro lifts it.
    let freeUndoLimit = 3

    // MARK: - Private
    private var timer: Timer?
    private var startedAt: Date
    private var hasRecordedResult = false

    // MARK: - Init
    init(dealNumber: Int = FreeCellEngine.randomDealNumber()) {
        self.dealNumber = dealNumber
        self.board = FreeCellEngine.deal(number: dealNumber)
        self.startedAt = .now
    }

    // MARK: - Derived
    var foundationCardCount: Int { board.foundationCardCount }
    var isInProgress: Bool { moveCount > 0 && !hasWon }

    func undosRemaining(isPro: Bool) -> Int {
        isPro ? Int.max : max(0, freeUndoLimit - undosUsed)
    }

    func canUndo(isPro: Bool) -> Bool {
        !undoStack.isEmpty && (isPro || undosUsed < freeUndoLimit)
    }

    // MARK: - Timer
    func startTimer() {
        guard timer == nil, !hasWon else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, !self.hasWon else { return }
                self.elapsedSeconds += 1
            }
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - New / load game
    func startNewGame(dealNumber: Int) {
        stopTimer()
        self.dealNumber = dealNumber
        self.board = FreeCellEngine.deal(number: dealNumber)
        self.moveCount = 0
        self.elapsedSeconds = 0
        self.hasWon = false
        self.selection = nil
        self.errorMessage = nil
        self.undoStack = []
        self.undosUsed = 0
        self.startedAt = .now
        self.hasRecordedResult = false
    }

    /// Restore from a SavedGame record. Returns false if data was corrupt.
    @discardableResult
    func restore(from saved: SavedGame) -> Bool {
        guard let restoredBoard = saved.decodedBoard else { return false }
        stopTimer()
        self.board = restoredBoard
        self.dealNumber = saved.dealNumber
        self.moveCount = saved.moveCount
        self.elapsedSeconds = saved.elapsedSeconds
        self.startedAt = saved.startedAt
        self.undosUsed = saved.undosUsed
        self.undoStack = []
        self.hasWon = restoredBoard.isWon
        self.selection = nil
        self.errorMessage = nil
        self.hasRecordedResult = self.hasWon
        return true
    }

    // MARK: - Tap-to-move interaction

    /// Handle a tap on a location. Implements: tap to select source, tap destination to move,
    /// tap an already-selected card again to deselect, and quick-send to foundation.
    func handleTap(on location: Location, hapticsEnabled: Bool, autoMoveEnabled: Bool) {
        errorMessage = nil

        // Tapping a foundation directly when something is selected = move there.
        if let source = selection {
            if source == location {
                selection = nil
                return
            }
            attemptMove(from: source, to: location, hapticsEnabled: hapticsEnabled)
            return
        }

        // Nothing selected yet. Decide what the tap means.
        switch location {
        case let .cascade(c):
            guard board.cascades.indices.contains(c), let top = board.cascades[c].last else {
                return // empty column with no selection: nothing to do
            }
            // Quick-send the top card to its foundation if it's a valid (and, when enabled, safe) move.
            if autoMoveEnabled, FreeCellEngine.canPlaceOnFoundation(top, board: board) {
                attemptMove(from: location, to: .foundation(top.suit), hapticsEnabled: hapticsEnabled)
                return
            }
            selection = location

        case let .freeCell(i):
            guard board.freeCells.indices.contains(i), let card = board.freeCells[i] else {
                return // empty free cell: nothing to pick
            }
            if autoMoveEnabled, FreeCellEngine.canPlaceOnFoundation(card, board: board) {
                attemptMove(from: location, to: .foundation(card.suit), hapticsEnabled: hapticsEnabled)
                return
            }
            selection = location

        case .foundation:
            return // can't pick up from a foundation
        }
    }

    /// Compute how many cards a cascade source intends to move toward a cascade destination.
    private func runCount(from: Location, to: Location) -> Int {
        guard case let .cascade(c) = from else { return 1 }
        // Move the longest valid run that still legally lands on the destination.
        let runLen = FreeCellEngine.movableRunLength(inCascade: c, board: board)
        guard runLen > 0, case let .cascade(destCol) = to,
              board.cascades.indices.contains(destCol) else { return 1 }
        let col = board.cascades[c]
        let destTop = board.cascades[destCol].last
        // Try the largest run first that fits capacity and lands legally.
        let cap = FreeCellEngine.maxMovable(board: board, destinationIsEmptyColumn: destTop == nil)
        var n = min(runLen, cap)
        while n >= 1 {
            let run = Array(col.suffix(n))
            if let bottom = run.first, FreeCellEngine.canStack(bottom, onCascadeTop: destTop) {
                return n
            }
            n -= 1
        }
        return 1
    }

    private func attemptMove(from: Location, to: Location, hapticsEnabled: Bool) {
        let count = runCount(from: from, to: to)
        let move = Move(from: from, to: to, count: count)
        do {
            let newBoard = try FreeCellEngine.apply(move, to: board)
            // Snapshot for undo before committing.
            undoStack.append((board: board, moves: moveCount))
            board = newBoard
            moveCount += 1
            selection = nil
            if count > 1 {
                Haptics.medium(enabled: hapticsEnabled)
            } else {
                Haptics.light(enabled: hapticsEnabled)
            }
            checkWin(hapticsEnabled: hapticsEnabled)
        } catch let error as FreeCellError {
            selection = nil
            errorMessage = error.message
            Haptics.warning(enabled: hapticsEnabled)
        } catch {
            selection = nil
            errorMessage = "That move couldn't be completed."
        }
    }

    // MARK: - Auto-collect

    func autoCollect(hapticsEnabled: Bool) {
        let result = FreeCellEngine.autoCollect(board)
        guard result.moved else { return }
        undoStack.append((board: board, moves: moveCount))
        board = result.board
        moveCount += 1
        selection = nil
        Haptics.medium(enabled: hapticsEnabled)
        checkWin(hapticsEnabled: hapticsEnabled)
    }

    // MARK: - Undo

    func undo(isPro: Bool, hapticsEnabled: Bool) {
        guard canUndo(isPro: isPro) else {
            errorMessage = isPro ? nil : "Upgrade to Citadel Pro for unlimited undo."
            Haptics.warning(enabled: hapticsEnabled)
            return
        }
        guard let last = undoStack.popLast() else { return }
        board = last.board
        moveCount = last.moves
        selection = nil
        errorMessage = nil
        if !isPro { undosUsed += 1 }
        hasWon = board.isWon
        Haptics.light(enabled: hapticsEnabled)
    }

    // MARK: - Win handling

    private func checkWin(hapticsEnabled: Bool) {
        if board.isWon {
            hasWon = true
            stopTimer()
            Haptics.success(enabled: hapticsEnabled)
        }
    }

    // MARK: - Persistence

    /// Encode the current board for storage. Returns nil only if encoding fails (never on the happy path).
    private func encodedBoard() -> Data? {
        try? JSONEncoder().encode(board)
    }

    /// Persist the current in-progress game into the single SavedGame slot.
    func persist(into context: ModelContext, existing: SavedGame?) {
        guard let data = encodedBoard() else { return }
        if let existing {
            existing.dealNumber = dealNumber
            existing.boardData = data
            existing.moveCount = moveCount
            existing.elapsedSeconds = elapsedSeconds
            existing.updatedAt = .now
            existing.undosUsed = undosUsed
        } else {
            let new = SavedGame(
                dealNumber: dealNumber,
                boardData: data,
                moveCount: moveCount,
                elapsedSeconds: elapsedSeconds,
                startedAt: startedAt,
                undosUsed: undosUsed
            )
            context.insert(new)
        }
        try? context.save()
    }

    /// Record a finished game into history (won or abandoned) and clear the saved slot.
    /// Returns the GameResult to insert, or nil if there's nothing meaningful to record.
    func makeResult(won: Bool) -> GameResult? {
        // Only record if the player actually made progress.
        guard moveCount > 0 || won else { return nil }
        if won && hasRecordedResult { return nil }
        if won { hasRecordedResult = true }
        return GameResult(
            dealNumber: dealNumber,
            won: won,
            durationSeconds: elapsedSeconds,
            moves: moveCount,
            date: .now
        )
    }
}
