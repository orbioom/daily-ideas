import SwiftUI
import SwiftData
import Observation

/// The view-model that owns a live game: wraps the pure `SpiderEngine`, drives
/// the undo stack, the wall-clock timer, the current selection, and persistence.
@Observable
final class GameViewModel {

    // MARK: - Core

    private(set) var engine: SpiderEngine
    private(set) var dealKind: DealKind

    /// Snapshot stack for undo (deep copies of engine state).
    private var undoStack: [SpiderEngine] = []

    /// Wall-clock anchor; the live timer recomputes elapsed from this Date.
    private(set) var startDate: Date
    /// Accumulated elapsed seconds from before the current session anchor
    /// (so a resumed game keeps its prior time).
    private var baseElapsed: Int

    /// Currently selected source: column + the index the run starts at.
    var selection: Selection?
    /// Transient, calm message surfaced to the player (e.g. "Fill empty columns").
    var banner: String?
    /// Set when the game is won so the Play screen can show the success overlay.
    private(set) var didWin: Bool = false
    /// True once this game's result has been recorded (avoid double-counting).
    private var recorded: Bool = false

    struct Selection: Equatable {
        let column: Int
        let index: Int
    }

    // MARK: - Init

    init(suitMode: SuitMode, dealKind: DealKind, seed: UInt64) {
        self.engine = SpiderEngine(suitMode: suitMode, seed: seed)
        self.dealKind = dealKind
        self.startDate = .now
        self.baseElapsed = 0
    }

    /// Restores a previously saved game.
    init(restored engine: SpiderEngine, dealKind: DealKind, elapsedSeconds: Int) {
        self.engine = engine
        self.dealKind = dealKind
        self.startDate = .now
        self.baseElapsed = max(0, elapsedSeconds)
        self.didWin = engine.isWon
    }

    // MARK: - Convenience constructors

    static func newGame(suitMode: SuitMode, kind: DealKind, referenceDate: Date = .now) -> GameViewModel {
        let seed: UInt64
        switch kind {
        case .random:
            seed = UInt64.random(in: UInt64.min...UInt64.max)
        case let .daily(seedInt):
            seed = UInt64(bitPattern: Int64(seedInt))
        case let .numbered(n):
            seed = DealSeed.numberedSeed(n)
        }
        return GameViewModel(suitMode: suitMode, dealKind: kind, seed: seed)
    }

    // MARK: - Timer

    /// Elapsed seconds at `date`, combining base + current anchor.
    func elapsedSeconds(at date: Date = .now) -> Int {
        let live = max(0, Int(date.timeIntervalSince(startDate)))
        return baseElapsed + (didWin ? 0 : live)
    }

    /// mm:ss formatting, capped sensibly.
    func elapsedString(at date: Date = .now) -> String {
        let total = elapsedSeconds(at: date)
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }

    /// Re-anchor the clock when returning from background so the timer doesn't jump.
    func reanchorClock() {
        guard !didWin else { return }
        baseElapsed = elapsedSeconds()
        startDate = .now
    }

    // MARK: - Derived

    var score: Int { engine.score }
    var moves: Int { engine.moves }
    var dealsRemaining: Int { engine.dealsRemaining }
    var foundationsCount: Int { engine.foundations.count }
    var foundations: [Suit] { engine.foundations }
    var columns: [[Card]] { engine.columns }
    var canUndo: Bool { !undoStack.isEmpty }
    var canDeal: Bool { engine.canDealFromStock }

    // MARK: - Player actions

    private func pushUndo() {
        undoStack.append(engine)
        // Keep the stack bounded to avoid unbounded growth on very long games.
        if undoStack.count > 500 { undoStack.removeFirst(undoStack.count - 500) }
    }

    /// Tap-to-select / tap-to-move flow. Tapping a card selects the longest run
    /// from there; tapping a destination column attempts the move.
    func tapColumn(_ column: Int, cardIndex: Int?) {
        banner = nil
        guard let pile = engine.columns[safe: column] else { return }

        if let current = selection {
            // A source is already selected — treat this tap as a destination.
            if current.column == column {
                // Tapping the same column toggles / re-selects.
                if let cardIndex, engine.isMovableRun(column: column, fromIndex: cardIndex) {
                    selection = Selection(column: column, index: cardIndex)
                    Haptics.selection()
                } else {
                    selection = nil
                }
                return
            }
            attemptMove(from: current, toColumn: column)
            return
        }

        // No selection yet — try to select a run.
        guard !pile.isEmpty else { return }
        let index: Int
        if let cardIndex, engine.isMovableRun(column: column, fromIndex: cardIndex) {
            index = cardIndex
        } else if let start = engine.longestRunStart(column: column) {
            index = start
        } else {
            return
        }
        selection = Selection(column: column, index: index)
        Haptics.selection()
    }

    private func attemptMove(from source: Selection, toColumn: Int) {
        if engine.canMove(fromColumn: source.column, fromIndex: source.index, toColumn: toColumn) {
            pushUndo()
            engine.move(fromColumn: source.column, fromIndex: source.index, toColumn: toColumn)
            selection = nil
            Haptics.light()
            checkWin()
        } else {
            // Illegal: keep selection, but if the new column has a selectable run,
            // switch the selection there instead for a smoother feel.
            if let start = engine.longestRunStart(column: toColumn) {
                selection = Selection(column: toColumn, index: start)
                Haptics.selection()
            } else {
                selection = nil
                banner = "That move isn't allowed."
            }
        }
    }

    /// Double-tap auto-move: send the longest run from this column to its best spot.
    func autoMove(column: Int, cardIndex: Int?) {
        banner = nil
        let index: Int
        if let cardIndex, engine.isMovableRun(column: column, fromIndex: cardIndex) {
            index = cardIndex
        } else if let start = engine.longestRunStart(column: column) {
            index = start
        } else {
            return
        }
        if let dest = engine.bestDestination(fromColumn: column, fromIndex: index) {
            pushUndo()
            engine.move(fromColumn: column, fromIndex: index, toColumn: dest)
            selection = nil
            Haptics.light()
            checkWin()
        } else {
            selection = Selection(column: column, index: index)
            banner = "No spot for that card yet."
        }
    }

    func deal() {
        banner = nil
        guard engine.canDealFromStock else {
            banner = engine.dealBlockedReason ?? "Can't deal right now."
            Haptics.warning()
            return
        }
        pushUndo()
        engine.dealFromStock()
        selection = nil
        Haptics.rigid()
        checkWin()
    }

    func undo() {
        guard let previous = undoStack.popLast() else { return }
        engine = previous
        selection = nil
        banner = nil
        Haptics.light()
    }

    /// Auto-collect: keep performing the single best legal build that makes progress
    /// and harvest any completed runs. Stops when nothing more helps.
    func autoCollect() {
        banner = nil
        var didSomething = false
        var safety = 0
        while safety < 200 {
            safety += 1
            // First, harvest any completable runs already present (handled inside move,
            // but also run a pass here in case a deal exposed them).
            let before = engine.foundations.count
            var localProgress = false
            // Try moves that build a longer same-suit run (heuristic: any legal move
            // whose destination is the same suit one higher).
            outer: for fromCol in 0..<SpiderEngine.columnCount {
                guard let pile = engine.columns[safe: fromCol], !pile.isEmpty else { continue }
                for idx in 0..<pile.count where engine.isMovableRun(column: fromCol, fromIndex: idx) {
                    guard let moving = pile[safe: idx] else { continue }
                    for toCol in 0..<SpiderEngine.columnCount where toCol != fromCol {
                        guard let dest = engine.columns[safe: toCol], let destTop = dest.last else { continue }
                        // Only same-suit merges, to avoid shuffling endlessly.
                        if destTop.suit == moving.suit, destTop.rank == moving.rank + 1 {
                            if engine.canMove(fromColumn: fromCol, fromIndex: idx, toColumn: toCol) {
                                pushUndo()
                                engine.move(fromColumn: fromCol, fromIndex: idx, toColumn: toCol)
                                localProgress = true
                                didSomething = true
                                break outer
                            }
                        }
                    }
                }
            }
            if engine.foundations.count > before { didSomething = true }
            if !localProgress { break }
        }
        selection = nil
        if didSomething {
            Haptics.success()
            checkWin()
        } else {
            banner = "Nothing to collect right now."
        }
    }

    func hint() -> SpiderEngine.Hint? {
        let h = engine.findHint()
        banner = h?.message ?? "No moves available. Try Undo, or start a new game."
        return h
    }

    private func checkWin() {
        if engine.isWon && !didWin {
            didWin = true
            Haptics.success()
        }
    }

    // MARK: - Selection helpers for the view

    /// True if the card at (column, index) is part of the current selection.
    func isSelected(column: Int, index: Int) -> Bool {
        guard let s = selection, s.column == column else { return false }
        return index >= s.index
    }

    var selectedCard: Card? {
        guard let s = selection else { return nil }
        return engine.columns[safe: s.column]?[safe: s.index]
    }

    // MARK: - Persistence

    /// A flat, Codable snapshot used by SavedGame.
    struct Snapshot: Codable {
        var engine: SpiderEngine
        var dealKind: DealKind
        var elapsedSeconds: Int
    }

    func makeSnapshot() -> Snapshot {
        Snapshot(engine: engine, dealKind: dealKind, elapsedSeconds: elapsedSeconds())
    }

    /// Records a finished or abandoned game's result, once.
    func recordResultIfFinished(into context: ModelContext) {
        guard didWin, !recorded else { return }
        recorded = true
        let result = GameResult(
            date: .now,
            won: true,
            suitCount: engine.suitMode.rawValue,
            moves: engine.moves,
            durationSeconds: elapsedSeconds(),
            score: engine.score,
            wasDaily: dealKind.isDaily,
            dealNumber: dealKind.dealNumber
        )
        context.insert(result)
        try? context.save()
    }
}
