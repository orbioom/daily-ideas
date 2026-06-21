import Foundation
import SwiftUI
import Observation

@Observable
final class PuzzleViewModel {
    var puzzle: PuzzleState
    var selectedCells: [(row: Int, col: Int)] = []
    var isDragging = false
    var elapsedSeconds = 0
    var isComplete = false
    var dragStart: (row: Int, col: Int)? = nil
    var dragEnd: (row: Int, col: Int)? = nil

    private var timer: Timer?
    private var colorIndex = 0

    init(category: WordCategory, difficulty: PuzzleDifficulty) {
        self.puzzle = PuzzleState(category: category, difficulty: difficulty)
        startTimer()
    }

    func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self, !self.isComplete else { return }
            self.elapsedSeconds += 1
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    func startDrag(row: Int, col: Int) {
        dragStart = (row, col)
        dragEnd = (row, col)
        isDragging = true
        updateSelection()
    }

    func updateDrag(row: Int, col: Int) {
        dragEnd = (row, col)
        updateSelection()
    }

    func endDrag() {
        isDragging = false
        checkSelection()
        dragStart = nil
        dragEnd = nil
        selectedCells = []
    }

    private func updateSelection() {
        guard let start = dragStart, let end = dragEnd else { return }
        selectedCells = linearCells(from: start, to: end)
    }

    private func linearCells(from start: (row: Int, col: Int), to end: (row: Int, col: Int)) -> [(row: Int, col: Int)] {
        let dr = end.row - start.row
        let dc = end.col - start.col
        let steps = max(abs(dr), abs(dc))
        guard steps > 0 else { return [start] }
        let stepR = dr == 0 ? 0 : dr / abs(dr)
        let stepC = dc == 0 ? 0 : dc / abs(dc)
        let isDiagonal = abs(dr) == abs(dc)
        let isStraight = dr == 0 || dc == 0
        guard isDiagonal || isStraight else { return [start] }
        return (0...steps).map { i in (start.row + stepR * i, start.col + stepC * i) }
    }

    private func checkSelection() {
        let word = String(selectedCells.map { puzzle.grid[$0.row][$0.col] })
        let reversed = String(word.reversed())
        for i in 0..<puzzle.placedWords.count {
            guard !puzzle.placedWords[i].isFound else { continue }
            if puzzle.placedWords[i].word == word || puzzle.placedWords[i].word == reversed {
                puzzle.placedWords[i].isFound = true
                puzzle.placedWords[i].foundColorIndex = colorIndex % SeekTheme.highlightColors.count
                colorIndex += 1
                if puzzle.isComplete {
                    isComplete = true
                    stopTimer()
                }
                return
            }
        }
    }

    func foundColorIndex(for cell: (row: Int, col: Int)) -> Int? {
        for pw in puzzle.placedWords where pw.isFound {
            for c in pw.cells {
                if c.row == cell.row && c.col == cell.col {
                    return pw.foundColorIndex
                }
            }
        }
        return nil
    }

    var formattedTime: String {
        let m = elapsedSeconds / 60
        let s = elapsedSeconds % 60
        return String(format: "%d:%02d", m, s)
    }

    func newPuzzle(category: WordCategory, difficulty: PuzzleDifficulty) {
        stopTimer()
        puzzle = PuzzleState(category: category, difficulty: difficulty)
        selectedCells = []
        elapsedSeconds = 0
        isComplete = false
        colorIndex = 0
        dragStart = nil
        dragEnd = nil
        startTimer()
    }
}
