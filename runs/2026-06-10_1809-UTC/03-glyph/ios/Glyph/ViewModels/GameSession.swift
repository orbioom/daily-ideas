import Foundation
import SwiftData
import SwiftUI

/// Drives an active Sudoku game: selection, number entry, pencil notes, undo,
/// hints, the timer, and win detection. Wraps the persisted `SudokuGame`.
@Observable
final class GameSession {
    let game: SudokuGame
    private let context: ModelContext

    var selected: Int? = nil
    var noteMode = false
    var elapsed: Int
    var justCompleted = false

    /// Undo records the full cell state before a change.
    private struct Move { let index: Int; let oldValue: Int; let oldNotes: Set<Int> }
    private var undoStack: [Move] = []

    private var grid: [Int]
    private var cellNotes: [Set<Int>]

    init(game: SudokuGame, context: ModelContext) {
        self.game = game
        self.context = context
        self.elapsed = game.elapsedSeconds
        self.grid = game.entryGrid
        self.cellNotes = game.notes
    }

    // MARK: - Derived

    var values: [Int] { grid }
    func notes(at index: Int) -> Set<Int> { cellNotes[safe: index] ?? [] }
    var givenMask: [Bool] { game.isGiven }
    var solution: [Int] { game.solutionGrid }
    var difficulty: SudokuDifficulty { game.difficulty }
    var mistakes: Int { game.mistakes }
    var hintsUsed: Int { game.hintsUsed }
    var isComplete: Bool { game.isComplete }
    var remaining: Int { 81 - grid.filter { $0 != 0 }.count }

    var canUndo: Bool { !undoStack.isEmpty }

    /// Count of each digit already placed (to disable a finished number).
    func placedCount(of digit: Int) -> Int { grid.filter { $0 == digit }.count }

    /// Cells that conflict with another of the same value in a unit.
    func isConflicting(_ index: Int) -> Bool {
        let v = grid[index]
        guard v != 0 else { return false }
        let row = index / 9, col = index % 9
        for c in 0..<9 where c != col && grid[row*9+c] == v { return true }
        for r in 0..<9 where r != row && grid[r*9+col] == v { return true }
        let br = (row/3)*3, bc = (col/3)*3
        for r in br..<br+3 { for c in bc..<bc+3 {
            let i = r*9+c
            if i != index && grid[i] == v { return true }
        }}
        return false
    }

    // MARK: - Actions

    func select(_ index: Int) {
        selected = index
        Haptics.selection()
    }

    func enter(_ digit: Int) {
        guard let idx = selected, !givenMask[idx], !game.isComplete else { return }
        if noteMode {
            // Toggle a pencil note (only on empty cells).
            guard grid[idx] == 0 else { return }
            recordMove(idx)
            if cellNotes[idx].contains(digit) { cellNotes[idx].remove(digit) }
            else { cellNotes[idx].insert(digit) }
            Haptics.tap()
        } else {
            recordMove(idx)
            if grid[idx] == digit {
                grid[idx] = 0
            } else {
                grid[idx] = digit
                cellNotes[idx] = []
                if game.solutionGrid[idx] != digit {
                    game.mistakes += 1
                    Haptics.warning()
                } else {
                    Haptics.tap()
                    // Clear this digit from notes of peers.
                    clearPeerNotes(of: idx, digit: digit)
                }
            }
        }
        persist()
        checkWin()
    }

    func clear() {
        guard let idx = selected, !givenMask[idx], !game.isComplete else { return }
        guard grid[idx] != 0 || !cellNotes[idx].isEmpty else { return }
        recordMove(idx)
        grid[idx] = 0
        cellNotes[idx] = []
        Haptics.tap()
        persist()
    }

    func undo() {
        guard let move = undoStack.popLast() else { return }
        grid[move.index] = move.oldValue
        cellNotes[move.index] = move.oldNotes
        Haptics.tap()
        persist()
    }

    /// Reveal one logically-deducible cell (or the selected cell's answer).
    func hint() {
        guard !game.isComplete else { return }
        if let h = SudokuEngine.logicalHint(grid) {
            apply(hint: h.index, value: h.value)
        } else if let idx = selected, !givenMask[idx], grid[idx] == 0 {
            apply(hint: idx, value: game.solutionGrid[idx])
        } else if let idx = grid.firstIndex(of: 0) {
            apply(hint: idx, value: game.solutionGrid[idx])
        }
    }

    private func apply(hint index: Int, value: Int) {
        recordMove(index)
        grid[index] = value
        cellNotes[index] = []
        clearPeerNotes(of: index, digit: value)
        game.hintsUsed += 1
        selected = index
        Haptics.success()
        persist()
        checkWin()
    }

    /// Fill all pencil notes from current candidates.
    func autoNotes() {
        for i in 0..<81 where grid[i] == 0 {
            cellNotes[i] = Set(SudokuEngine.candidates(grid, index: i))
        }
        undoStack.removeAll() // bulk action is not individually undoable
        Haptics.tap()
        persist()
    }

    // MARK: - Timer

    func tick() {
        guard !game.isComplete else { return }
        elapsed += 1
        game.elapsedSeconds = elapsed
    }

    // MARK: - Helpers

    private func recordMove(_ index: Int) {
        undoStack.append(Move(index: index, oldValue: grid[index], oldNotes: cellNotes[index]))
        if undoStack.count > 200 { undoStack.removeFirst() }
    }

    private func clearPeerNotes(of index: Int, digit: Int) {
        let autoRemove = UserDefaults.standard.object(forKey: "autoRemoveNotes") as? Bool ?? true
        guard autoRemove else { return }
        let row = index / 9, col = index % 9
        let br = (row/3)*3, bc = (col/3)*3
        for c in 0..<9 { cellNotes[row*9+c].remove(digit) }
        for r in 0..<9 { cellNotes[r*9+col].remove(digit) }
        for r in br..<br+3 { for c in bc..<bc+3 { cellNotes[r*9+c].remove(digit) } }
    }

    private func persist() {
        game.entryGrid = grid
        game.notes = cellNotes
        try? context.save()
    }

    private func checkWin() {
        guard !game.isComplete, grid.allSatisfy({ $0 != 0 }), grid == game.solutionGrid else { return }
        game.isComplete = true
        game.finishedAt = .now
        justCompleted = true
        try? context.save()
        Haptics.success()
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
