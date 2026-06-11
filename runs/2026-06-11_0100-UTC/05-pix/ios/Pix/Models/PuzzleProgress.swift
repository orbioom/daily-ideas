import SwiftData
import Foundation

@Model
class PuzzleProgress {
    var puzzleId: Int
    var date: Date
    var boardData: Data   // encoded [[CellState]] as JSON
    var solved: Bool
    var elapsedSeconds: Double
    var mistakesCount: Int

    init(puzzleId: Int) {
        self.puzzleId = puzzleId
        self.date = Date()
        self.boardData = Data()
        self.solved = false
        self.elapsedSeconds = 0
        self.mistakesCount = 0
    }

    func loadBoard(size: Int) -> [[CellState]] {
        guard let board = try? JSONDecoder().decode([[CellState]].self, from: boardData),
              board.count == size, board.first?.count == size else {
            return Array(repeating: Array(repeating: CellState.unknown, count: size), count: size)
        }
        return board
    }

    func saveBoard(_ board: [[CellState]]) {
        boardData = (try? JSONEncoder().encode(board)) ?? Data()
    }
}
