import Foundation
import SwiftUI
import SwiftData

/// The observable game state driving PlayView. Owns the puzzle, the per-cell
/// state, selection, timer, undo history, and win/loss bookkeeping.
@MainActor
@Observable
final class GameViewModel {

    // MARK: Loading / phase

    enum Phase: Equatable {
        case idle
        case generating
        case playing
        case won
        case failed(String)   // calm recoverable error
    }

    var phase: Phase = .idle

    // MARK: Core state

    private(set) var puzzle: Puzzle?
    var cells: [CellState] = []
    var selectedCell: Int? = nil

    private(set) var difficulty: Difficulty = .easy
    private(set) var isDaily: Bool = false
    private(set) var dateKey: String = ""

    var elapsedSeconds: Int = 0
    var mistakes: Int = 0
    var hintsUsed: Int = 0
    var mistakeLimit: Int = 0   // 0 == unlimited

    var notesMode: Bool = false

    /// Cells currently in conflict (recomputed on edits).
    private(set) var conflicts: Set<Int> = []

    /// Identity of the SwiftData SavedGame backing this session.
    private(set) var savedGameID: UUID = UUID()

    // MARK: Undo

    private struct Snapshot { let cells: [CellState]; let mistakes: Int }
    private var undoStack: [Snapshot] = []
    var canUndo: Bool { !undoStack.isEmpty }

    // MARK: Timer

    private var timerTask: Task<Void, Never>?

    var size: Int { puzzle?.size ?? 0 }
    var hasReachedMistakeLimit: Bool {
        mistakeLimit > 0 && mistakes >= mistakeLimit
    }

    // MARK: - Lifecycle

    deinit { timerTask?.cancel() }

    /// Starts a brand-new generated puzzle (async generation with loading state).
    func startNew(difficulty: Difficulty, isDaily: Bool, dateKey: String, seed: UInt64, mistakeLimit: Int) async {
        self.difficulty = difficulty
        self.isDaily = isDaily
        self.dateKey = dateKey
        self.mistakeLimit = mistakeLimit
        self.savedGameID = UUID()
        phase = .generating

        let generated = await PuzzleService.generate(difficulty: difficulty, seed: seed)
        guard generated.size > 0, generated.solution.count == generated.cellCount else {
            phase = .failed("We couldn't build that puzzle. Please try again.")
            return
        }

        self.puzzle = generated
        self.cells = Array(repeating: CellState(), count: generated.cellCount)
        self.selectedCell = nil
        self.elapsedSeconds = 0
        self.mistakes = 0
        self.hintsUsed = 0
        self.undoStack = []
        self.conflicts = []
        phase = .playing
        startTimer()
    }

    /// Resumes a previously saved game.
    func resume(from saved: SavedGame, mistakeLimit: Int) {
        guard let puzzle = saved.decodedPuzzle(),
              puzzle.size > 0,
              puzzle.solution.count == puzzle.cellCount,
              let state = saved.decodedState(),
              state.count == puzzle.cellCount else {
            phase = .failed("This saved game looks corrupted. Start a new puzzle to continue.")
            return
        }
        self.puzzle = puzzle
        self.cells = state
        self.difficulty = saved.difficulty
        self.isDaily = saved.isDaily
        self.dateKey = saved.dateKey
        self.elapsedSeconds = saved.elapsedSeconds
        self.mistakes = saved.mistakes
        self.hintsUsed = saved.hintsUsed
        self.mistakeLimit = mistakeLimit
        self.savedGameID = saved.id
        self.selectedCell = nil
        recomputeConflicts()
        phase = saved.isCompleted ? .won : .playing
        if phase == .playing { startTimer() }
    }

    func startTimer() {
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self else { return }
                if self.phase == .playing {
                    self.elapsedSeconds += 1
                }
            }
        }
    }

    func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }

    // MARK: - Selection

    func select(_ cell: Int) {
        guard let puzzle, cell >= 0, cell < puzzle.cellCount else { return }
        selectedCell = (selectedCell == cell) ? nil : cell
    }

    /// Cells related to the selection (same row/col/cage) for highlighting.
    func relatedCells(to cell: Int) -> Set<Int> {
        guard let puzzle, cell >= 0, cell < puzzle.cellCount else { return [] }
        let size = puzzle.size
        guard size > 0 else { return [] }
        let row = cell / size
        let col = cell % size
        var related = Set<Int>()
        for k in 0..<size {
            related.insert(row * size + k)
            related.insert(k * size + col)
        }
        if let cage = puzzle.cage(forCell: cell) {
            related.formUnion(cage.cells)
        }
        related.remove(cell)
        return related
    }

    // MARK: - Editing

    /// Whether this edit would be a mistake (value differs from the solution).
    private func isWrong(_ value: Int, at cell: Int) -> Bool {
        guard let puzzle, cell >= 0, cell < puzzle.solution.count else { return false }
        return puzzle.solution[cell] != value
    }

    /// Enters a value (or a note when notesMode is on) at the selected cell.
    /// Returns a feedback signal for haptics/UI.
    enum EditFeedback { case none, placed, mistake, won }

    @discardableResult
    func enter(_ value: Int, autoRemoveNotes: Bool, checkMistakes: Bool) -> EditFeedback {
        guard phase == .playing,
              let puzzle,
              let cell = selectedCell,
              cell >= 0, cell < cells.count,
              value >= 1, value <= puzzle.size else { return .none }

        pushUndo()

        if notesMode {
            if cells[cell].notes.contains(value) {
                cells[cell].notes.remove(value)
            } else {
                cells[cell].notes.insert(value)
            }
            cells[cell].value = nil
            return .placed
        }

        // Placing a definite value.
        var feedback: EditFeedback = .placed
        cells[cell].value = value
        cells[cell].notes = []

        if checkMistakes && isWrong(value, at: cell) {
            mistakes += 1
            feedback = .mistake
        }

        if autoRemoveNotes {
            removeNotes(value: value, relatedTo: cell)
        }

        recomputeConflicts()

        if isSolved() {
            phase = .won
            stopTimer()
            return .won
        }
        return feedback
    }

    func erase() {
        guard phase == .playing, let cell = selectedCell,
              cell >= 0, cell < cells.count else { return }
        guard !cells[cell].isEmpty else { return }
        pushUndo()
        cells[cell].value = nil
        cells[cell].notes = []
        recomputeConflicts()
    }

    /// Reveals the correct value for one cell (a hint). Prefers a wrong cell to
    /// fix, otherwise reveals an empty cell.
    @discardableResult
    func useHint() -> Bool {
        guard phase == .playing, let puzzle else { return false }

        // First, fix a wrong cell if any.
        if let wrong = (0..<cells.count).first(where: { idx in
            if let v = cells[idx].value, idx < puzzle.solution.count {
                return v != puzzle.solution[idx]
            }
            return false
        }) {
            pushUndo()
            cells[wrong].value = puzzle.solution[wrong]
            cells[wrong].notes = []
            selectedCell = wrong
            hintsUsed += 1
            recomputeConflicts()
            checkWin()
            return true
        }

        // Otherwise reveal an empty cell.
        if let empty = (0..<cells.count).first(where: { cells[$0].value == nil }) {
            guard empty < puzzle.solution.count else { return false }
            pushUndo()
            cells[empty].value = puzzle.solution[empty]
            cells[empty].notes = []
            selectedCell = empty
            hintsUsed += 1
            recomputeConflicts()
            checkWin()
            return true
        }
        return false
    }

    func undo() {
        guard let snapshot = undoStack.popLast() else { return }
        cells = snapshot.cells
        mistakes = snapshot.mistakes
        recomputeConflicts()
    }

    // MARK: - Helpers

    private func pushUndo() {
        undoStack.append(Snapshot(cells: cells, mistakes: mistakes))
        if undoStack.count > 200 { undoStack.removeFirst() }
    }

    private func removeNotes(value: Int, relatedTo cell: Int) {
        let related = relatedCells(to: cell)
        for idx in related where idx >= 0 && idx < cells.count {
            cells[idx].notes.remove(value)
        }
    }

    private func recomputeConflicts() {
        guard let puzzle else { conflicts = []; return }
        let values = cells.map { $0.value }
        conflicts = PuzzleValidator.conflicts(values: values, puzzle: puzzle)
    }

    private func isSolved() -> Bool {
        guard let puzzle else { return false }
        return PuzzleValidator.isSolved(values: cells.map { $0.value }, puzzle: puzzle)
    }

    private func checkWin() {
        if isSolved() {
            phase = .won
            stopTimer()
        }
    }

    var progress: Double {
        guard let puzzle, puzzle.cellCount > 0 else { return 0 }
        let filled = cells.filter { $0.value != nil }.count
        return Double(filled) / Double(puzzle.cellCount)
    }

    var formattedTime: String {
        let m = elapsedSeconds / 60
        let s = elapsedSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}
