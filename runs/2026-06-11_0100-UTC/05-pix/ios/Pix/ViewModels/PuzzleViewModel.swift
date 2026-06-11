import SwiftUI
import SwiftData

@Observable
class PixPuzzleViewModel {
    let puzzle: NonogramPuzzle
    private(set) var progress: PuzzleProgress?
    private(set) var board: [[CellState]]
    private(set) var solved = false
    private(set) var elapsedSeconds: Double = 0
    var inputMode: CellState = .filled  // what tapping places

    private var timerActive = false
    private var timerStart = Date()
    private var accumulated: Double = 0

    init(puzzle: NonogramPuzzle, progress: PuzzleProgress?) {
        self.puzzle = puzzle
        self.progress = progress
        if let p = progress {
            self.board = p.loadBoard(size: puzzle.size)
            self.solved = p.solved
            self.elapsedSeconds = p.elapsedSeconds
        } else {
            self.board = Array(repeating: Array(repeating: .unknown, count: puzzle.size), count: puzzle.size)
        }
    }

    func toggleCell(row: Int, col: Int) {
        guard !solved else { return }
        let current = board[row][col]
        switch inputMode {
        case .filled:
            board[row][col] = current == .filled ? .unknown : .filled
        case .excluded:
            board[row][col] = current == .excluded ? .unknown : .excluded
        default:
            board[row][col] = .unknown
        }
        checkSolved()
    }

    func checkSolved() {
        if puzzle.checkSolved(board) {
            solved = true
            stopTimer()
        }
    }

    func resetBoard() {
        board = Array(repeating: Array(repeating: .unknown, count: puzzle.size), count: puzzle.size)
        solved = false
    }

    // MARK: Timer

    func startTimer() {
        guard !timerActive, !solved else { return }
        timerActive = true
        timerStart = Date()
    }

    func stopTimer() {
        guard timerActive else { return }
        timerActive = false
        accumulated += Date().timeIntervalSince(timerStart)
        elapsedSeconds = accumulated
    }

    func tick() {
        guard timerActive else { return }
        elapsedSeconds = accumulated + Date().timeIntervalSince(timerStart)
    }

    var elapsedFormatted: String {
        let t = Int(elapsedSeconds)
        return String(format: "%d:%02d", t / 60, t % 60)
    }

    // MARK: Persistence

    func save(modelContext: ModelContext) {
        let p: PuzzleProgress
        if let existing = progress {
            p = existing
        } else {
            p = PuzzleProgress(puzzleId: puzzle.id)
            modelContext.insert(p)
            progress = p
        }
        p.saveBoard(board)
        p.solved = solved
        p.elapsedSeconds = elapsedSeconds
    }

    // MARK: Clue highlight helpers

    func isRowComplete(_ row: Int) -> Bool {
        let rowClue = puzzle.rowClues[row]
        let filledSegments = computeSegments(row: row)
        return rowClue == filledSegments
    }

    func isColComplete(_ col: Int) -> Bool {
        let colClue = puzzle.colClues[col]
        let filledSegments = computeColSegments(col: col)
        return colClue == filledSegments
    }

    private func computeSegments(row: Int) -> [Int] {
        var segs: [Int] = []
        var count = 0
        for c in 0..<puzzle.size {
            if board[row][c] == .filled { count += 1 }
            else if count > 0 { segs.append(count); count = 0 }
        }
        if count > 0 { segs.append(count) }
        return segs.isEmpty ? [0] : segs
    }

    private func computeColSegments(col: Int) -> [Int] {
        var segs: [Int] = []
        var count = 0
        for r in 0..<puzzle.size {
            if board[r][col] == .filled { count += 1 }
            else if count > 0 { segs.append(count); count = 0 }
        }
        if count > 0 { segs.append(count) }
        return segs.isEmpty ? [0] : segs
    }
}
