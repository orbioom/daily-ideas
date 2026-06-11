import Foundation

// Cell state: unknown, filled, excluded
enum CellState: Int, Codable {
    case unknown  = 0
    case filled   = 1
    case excluded = 2
}

struct NonogramPuzzle: Identifiable {
    let id: Int
    let name: String
    let size: Int
    let solution: [[Bool]]   // [row][col]
    let difficulty: Int      // 1 = easy, 2 = medium, 3 = hard

    var rowClues: [[Int]] { computeClues(rows: solution) }
    var colClues: [[Int]] {
        let transposed = (0..<size).map { col in (0..<size).map { row in solution[row][col] } }
        return computeClues(rows: transposed)
    }

    private func computeClues(rows: [[Bool]]) -> [[Int]] {
        rows.map { row in
            var clues: [Int] = []
            var count = 0
            for cell in row {
                if cell { count += 1 }
                else if count > 0 { clues.append(count); count = 0 }
            }
            if count > 0 { clues.append(count) }
            return clues.isEmpty ? [0] : clues
        }
    }

    // Check if current board matches solution
    func checkSolved(_ board: [[CellState]]) -> Bool {
        for r in 0..<size {
            for c in 0..<size {
                let shouldFill = solution[r][c]
                let isFilled = board[r][c] == .filled
                if shouldFill != isFilled { return false }
            }
        }
        return true
    }
}

@_documentation(visibility: private)
extension NonogramPuzzle {
    static func daily() -> NonogramPuzzle { puzzleForDate(Date()) }

    static func puzzleForDate(_ date: Date) -> NonogramPuzzle {
        let epoch = Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let days = Calendar.current.dateComponents([.day], from: epoch, to: date).day ?? 0
        return PixPuzzleBank.all[abs(days) % PixPuzzleBank.all.count]
    }
}
