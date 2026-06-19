import Foundation

// Standard 15x15 Scrabble board layout
enum BoardLayout {
    static let size = 15
    static let center = 7

    static func squareType(row: Int, col: Int) -> SquareType {
        let r = min(row, 14 - row)
        let c = min(col, 14 - col)
        let (a, b) = (min(r, c), max(r, c))
        switch (a, b) {
        case (0, 0), (0, 7), (7, 7): return a == 7 && b == 7 ? .center : .tripleWord
        case (0, 0): return .tripleWord
        case (7, 7): return .center
        default: break
        }
        if row == 7 && col == 7 { return .center }
        if (row == 0 || row == 7 || row == 14) && (col == 0 || col == 7 || col == 14) { return .tripleWord }
        if (row == 1 || row == 13) && (col == 1 || col == 13) { return .doubleWord }
        if (row == 2 || row == 12) && (col == 2 || col == 12) { return .doubleWord }
        if (row == 3 || row == 11) && (col == 3 || col == 11) { return .doubleWord }
        if (row == 4 || row == 10) && (col == 4 || col == 10) { return .doubleWord }
        if row == col || row + col == 14 { return .doubleWord }
        if (row == 5 || row == 9) && (col == 1 || col == 5 || col == 9 || col == 13) { return .tripleLetter }
        if (col == 5 || col == 9) && (row == 1 || row == 13) { return .tripleLetter }
        if (row == 0 || row == 14) && (col == 3 || col == 11) { return .doubleLetter }
        if (col == 0 || col == 14) && (row == 3 || row == 11) { return .doubleLetter }
        if (row == 2 || row == 12) && (col == 6 || col == 8) { return .doubleLetter }
        if (col == 2 || col == 12) && (row == 6 || row == 8) { return .doubleLetter }
        if (row == 3 || row == 11) && (col == 7) { return .doubleLetter }
        if (col == 3 || col == 11) && (row == 7) { return .doubleLetter }
        if (row == 6 || row == 8) && (col == 6 || col == 8) { return .doubleLetter }
        if (row == 7) && (col == 3 || col == 11) { return .doubleLetter }
        if (col == 7) && (row == 3 || row == 11) { return .doubleLetter }
        return .normal
    }

    static func makeBoard() -> [[BoardSquare]] {
        var board: [[BoardSquare]] = []
        for r in 0..<size {
            var row: [BoardSquare] = []
            for c in 0..<size {
                let sq = BoardSquare(id: r * size + c, row: r, col: c, type: squareType(row: r, col: c))
                row.append(sq)
            }
            board.append(row)
        }
        return board
    }
}
