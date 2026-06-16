import Foundation

/// Validates a drag selection against the board's placed words.
/// Every path here is fully guarded: no force-unwraps, no unguarded indexing or division.
enum SelectionValidator {

    /// Given a start and end cell, returns the ordered straight-line path of cells
    /// if (and only if) they lie on one of the eight directions. Returns nil otherwise.
    static func path(from start: GridPoint, to end: GridPoint, size: Int) -> [GridPoint]? {
        guard size > 0 else { return nil }
        guard inBounds(start, size: size), inBounds(end, size: size) else { return nil }

        let deltaRow = end.row - start.row
        let deltaCol = end.col - start.col

        // Same cell: a single-cell path is valid (lets a 1-letter tap be the whole word edge case).
        if deltaRow == 0 && deltaCol == 0 {
            return [start]
        }

        // Must be horizontal, vertical, or a perfect 45-degree diagonal.
        let absRow = abs(deltaRow)
        let absCol = abs(deltaCol)
        let isStraight = deltaRow == 0 || deltaCol == 0 || absRow == absCol
        guard isStraight else { return nil }

        let steps = max(absRow, absCol)
        guard steps > 0 else { return [start] }

        let stepRow = deltaRow == 0 ? 0 : deltaRow / steps
        let stepCol = deltaCol == 0 ? 0 : deltaCol / steps

        var path: [GridPoint] = []
        var i = 0
        while i <= steps {
            let r = start.row + stepRow * i
            let c = start.col + stepCol * i
            guard inBounds(GridPoint(r, c), size: size) else { return nil }
            path.append(GridPoint(r, c))
            i += 1
        }
        return path
    }

    /// Extracts the string spelled by a path on the board.
    static func word(for path: [GridPoint], board: WordSearchBoard) -> String {
        String(path.map { board.letter(at: $0) })
    }

    /// If the selection (forward or reversed) matches an unfound placement, returns that word.
    static func match(
        path: [GridPoint],
        board: WordSearchBoard,
        alreadyFound: Set<String>
    ) -> String? {
        guard !path.isEmpty else { return nil }
        let spelled = word(for: path, board: board)
        guard spelled.count >= 2 else { return nil }
        let reversed = String(spelled.reversed())

        for (placedWord, placedPath) in board.placements {
            if alreadyFound.contains(placedWord) { continue }
            // The selection length must equal the placement length.
            if placedPath.count != path.count { continue }
            if placedWord == spelled || placedWord == reversed {
                // Confirm the selected cells actually cover the placement cells (set equality).
                if Set(placedPath) == Set(path) {
                    return placedWord
                }
            }
        }
        return nil
    }

    private static func inBounds(_ point: GridPoint, size: Int) -> Bool {
        point.row >= 0 && point.row < size && point.col >= 0 && point.col < size
    }
}
