import CoreGraphics

/// Builds the geometry + covering graph for each layout.
/// Every layout produces exactly 28 tableau positions with a valid cover graph
/// (a card is playable only when the positions covering it are all cleared).
enum BoardLayoutFactory {

    static func spec(for layout: BoardLayout) -> BoardSpec {
        switch layout {
        case .threePeaks: return threePeaks()
        case .pyramid: return pyramid()
        case .diamond: return diamond()
        }
    }

    // MARK: - Three Peaks (classic): rows of 3, 6, 9, 10 = 28

    private static func threePeaks() -> BoardSpec {
        // Row sizes top->bottom.
        let rowSizes = [3, 6, 9, 10]
        // Horizontal slot for each card, on a 0...1 axis sized to the widest row.
        // We lay each row out on a shared grid of half-steps so peaks overlap.
        // Column centers (in "half-card" units) for each row, hand-tuned for the
        // three-peak silhouette.
        let rowCols: [[CGFloat]] = [
            [3, 9, 15],                                   // row 0: 3 peak tips
            [2, 4, 8, 10, 14, 16],                        // row 1: 6
            [1, 3, 5, 7, 9, 11, 13, 15, 17],              // row 2: 9
            [0, 2, 4, 6, 8, 10, 12, 14, 16, 18]           // row 3: 10 (base)
        ]
        let maxCol: CGFloat = 18
        let rowCount = rowSizes.count

        var positions: [BoardPosition] = []
        var indexByRowCol: [[Int]] = []   // index lookup per row by slot
        var id = 0
        for (r, cols) in rowCols.enumerated() {
            var rowIndices: [Int] = []
            for col in cols {
                let x = (col + 1) / (maxCol + 2)               // small padding
                let y = (CGFloat(r) + 0.5) / CGFloat(rowCount)
                positions.append(BoardPosition(id: id, x: x, y: y, row: r))
                rowIndices.append(id)
                id += 1
            }
            indexByRowCol.append(rowIndices)
        }

        // Build covers: a card in row r at column position is covered by the two
        // cards in row r+1 whose column centers are nearest above-left / above-right.
        var covers = Array(repeating: [Int](), count: positions.count)
        for r in 0..<(rowCount - 1) {
            let below = rowCols[r + 1]
            for (cI, col) in rowCols[r].enumerated() {
                let myIndex = indexByRowCol[r][cI]
                // children: positions in row r+1 at col-1 and col+1
                for childCol in [col - 1, col + 1] {
                    if let bI = below.firstIndex(of: childCol) {
                        let childIndex = indexByRowCol[r + 1][bI]
                        covers[myIndex].append(childIndex)
                    }
                }
            }
        }
        return BoardSpec(positions: positions, covers: covers, aspect: 1.55)
    }

    // MARK: - Pyramid: a single triangle of rows 1,2,3,4,5,6,7 = 28

    private static func pyramid() -> BoardSpec {
        let rowSizes = Array(1...7)         // 1+2+3+4+5+6+7 = 28
        let rowCount = rowSizes.count
        let maxCols = 7

        var positions: [BoardPosition] = []
        var indexByRow: [[Int]] = []
        var id = 0
        for (r, n) in rowSizes.enumerated() {
            var rowIndices: [Int] = []
            // Center the row: offset so the triangle is symmetric.
            let offset = (CGFloat(maxCols) - CGFloat(n)) / 2
            for c in 0..<n {
                let colCenter = offset + CGFloat(c) + 0.5
                let x = colCenter / CGFloat(maxCols)
                let y = (CGFloat(r) + 0.5) / CGFloat(rowCount)
                positions.append(BoardPosition(id: id, x: x, y: y, row: r))
                rowIndices.append(id)
                id += 1
            }
            indexByRow.append(rowIndices)
        }

        // Classic pyramid covering: card (r,c) is covered by (r+1,c) and (r+1,c+1).
        var covers = Array(repeating: [Int](), count: positions.count)
        for r in 0..<(rowCount - 1) {
            for c in 0..<rowSizes[r] {
                let me = indexByRow[r][c]
                covers[me].append(indexByRow[r + 1][c])
                covers[me].append(indexByRow[r + 1][c + 1])
            }
        }
        return BoardSpec(positions: positions, covers: covers, aspect: 1.25)
    }

    // MARK: - Diamond: a symmetric diamond. Rows 1,3,5,5,5,5,3,1 = 28

    private static func diamond() -> BoardSpec {
        // Upper half widens; lower half narrows. Total = 1+3+5+5+5+5+3+1 = 28.
        let rowSizes = [1, 3, 5, 5, 5, 5, 3, 1]
        let rowCount = rowSizes.count
        let maxCols = 5

        var positions: [BoardPosition] = []
        var indexByRow: [[Int]] = []
        var id = 0
        for (r, n) in rowSizes.enumerated() {
            var rowIndices: [Int] = []
            let offset = (CGFloat(maxCols) - CGFloat(n)) / 2
            for c in 0..<n {
                let colCenter = offset + CGFloat(c) + 0.5
                let x = colCenter / CGFloat(maxCols)
                let y = (CGFloat(r) + 0.5) / CGFloat(rowCount)
                positions.append(BoardPosition(id: id, x: x, y: y, row: r))
                rowIndices.append(id)
                id += 1
            }
            indexByRow.append(rowIndices)
        }

        // Build a valid cover graph. A card is covered by the card(s) in the row
        // below whose column ranges overlap it from above. We compute overlap by
        // comparing normalized x-centers within a tolerance of half a column.
        var covers = Array(repeating: [Int](), count: positions.count)
        let tol = (1.0 / CGFloat(maxCols)) * 0.75
        for r in 0..<(rowCount - 1) {
            for upper in indexByRow[r] {
                let ux = positions[upper].x
                for lower in indexByRow[r + 1] {
                    let lx = positions[lower].x
                    if abs(ux - lx) <= tol {
                        covers[upper].append(lower)
                    }
                }
            }
        }
        // Safety: any upper card with no detected child but a non-empty row below
        // is linked to the nearest lower card so it can never be permanently stuck-open
        // in an inconsistent way (keeps the graph well-formed).
        for r in 0..<(rowCount - 1) {
            let lowerRow = indexByRow[r + 1]
            guard !lowerRow.isEmpty else { continue }
            for upper in indexByRow[r] where covers[upper].isEmpty {
                let ux = positions[upper].x
                if let nearest = lowerRow.min(by: { abs(positions[$0].x - ux) < abs(positions[$1].x - ux) }) {
                    covers[upper].append(nearest)
                }
            }
        }
        return BoardSpec(positions: positions, covers: covers, aspect: 1.05)
    }
}
