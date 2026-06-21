import Foundation

// MARK: - Core Types

enum Player: String, Codable, CaseIterable {
    case red, black

    var opponent: Player {
        self == .red ? .black : .red
    }
}

enum PieceType: String, Codable {
    case man, king
}

struct Piece: Equatable, Codable {
    let player: Player
    var type: PieceType
}

typealias BoardState = [[Piece?]]

// MARK: - Board

struct CheckersBoard {
    var cells: BoardState
    var currentPlayer: Player

    // MARK: Initialisation

    /// Produces the standard 8×8 starting position.
    /// Red on rows 0-2, Black on rows 5-7, on dark squares only.
    /// Dark squares satisfy (row + col) % 2 == 1.
    static func initial() -> CheckersBoard {
        var cells: BoardState = Array(repeating: Array(repeating: nil, count: 8), count: 8)

        for row in 0..<8 {
            for col in 0..<8 {
                guard (row + col) % 2 == 1 else { continue }
                if row < 3 {
                    cells[row][col] = Piece(player: .red, type: .man)
                } else if row > 4 {
                    cells[row][col] = Piece(player: .black, type: .man)
                }
            }
        }

        return CheckersBoard(cells: cells, currentPlayer: .red)
    }

    // MARK: Queries

    var hasMandatoryJump: Bool {
        cells.indices.contains { row in
            cells[row].indices.contains { col in
                guard let piece = cells[row][col], piece.player == currentPlayer else { return false }
                return !jumps(for: piece, at: (row, col), cells: cells).isEmpty
            }
        }
    }

    var isTerminal: Bool {
        validMoves(for: currentPlayer).isEmpty
    }

    func winner() -> Player? {
        guard isTerminal else { return nil }
        // The player who cannot move loses.
        return currentPlayer.opponent
    }

    func pieceCount(for player: Player) -> Int {
        cells.flatMap { $0 }.compactMap { $0 }.filter { $0.player == player }.count
    }

    func kingCount(for player: Player) -> Int {
        cells.flatMap { $0 }.compactMap { $0 }.filter { $0.player == player && $0.type == .king }.count
    }

    // MARK: Valid Moves

    func validMoves(for player: Player) -> [CheckersMove] {
        var allJumps: [CheckersMove] = []
        var allSimple: [CheckersMove] = []

        for row in 0..<8 {
            for col in 0..<8 {
                guard let piece = cells[row][col], piece.player == player else { continue }
                let pieceJumps = allMultiJumps(originRow: row, originCol: col, currentRow: row, currentCol: col, piece: piece, cells: cells, capturedSoFar: [])
                if !pieceJumps.isEmpty {
                    allJumps.append(contentsOf: pieceJumps)
                } else {
                    allSimple.append(contentsOf: simpleMovesFor(piece: piece, row: row, col: col, cells: cells))
                }
            }
        }

        // Mandatory jump: if any jump exists, only jumps are legal.
        return allJumps.isEmpty ? allSimple : allJumps
    }

    // MARK: Apply Move

    func applyMove(_ move: CheckersMove) -> CheckersBoard {
        var newCells = cells

        // Move the piece
        let movingPiece = newCells[move.from.row][move.from.col]
        newCells[move.from.row][move.from.col] = nil

        guard var piece = movingPiece else {
            return CheckersBoard(cells: newCells, currentPlayer: currentPlayer.opponent)
        }

        // Remove captured pieces
        for cap in move.captures {
            newCells[cap.row][cap.col] = nil
        }

        // Check for promotion
        let toRow = move.to.row
        if piece.type == .man {
            if piece.player == .red && toRow == 7 {
                piece.type = .king
            } else if piece.player == .black && toRow == 0 {
                piece.type = .king
            }
        }

        newCells[toRow][move.to.col] = piece

        return CheckersBoard(cells: newCells, currentPlayer: currentPlayer.opponent)
    }

    // MARK: - Private Helpers

    /// Returns all simple (non-jump) moves for a piece.
    private func simpleMovesFor(piece: Piece, row: Int, col: Int, cells: BoardState) -> [CheckersMove] {
        let directions = forwardDirections(for: piece)
        var moves: [CheckersMove] = []

        for (dr, dc) in directions {
            let nr = row + dr
            let nc = col + dc
            guard inBounds(nr, nc), cells[nr][nc] == nil else { continue }
            moves.append(CheckersMove(from: (row, col), to: (nr, nc), captures: []))
        }

        return moves
    }

    /// Returns all single-step jump moves from a given position (not multi-jumps).
    private func jumps(for piece: Piece, at position: (row: Int, col: Int), cells: BoardState) -> [(land: (Int, Int), capture: (Int, Int))] {
        let directions = allDirections(for: piece)
        var results: [(land: (Int, Int), capture: (Int, Int))] = []

        for (dr, dc) in directions {
            let midRow = position.row + dr
            let midCol = position.col + dc
            let landRow = position.row + 2 * dr
            let landCol = position.col + 2 * dc

            guard inBounds(midRow, midCol), inBounds(landRow, landCol) else { continue }
            guard let midPiece = cells[midRow][midCol], midPiece.player != piece.player else { continue }
            guard cells[landRow][landCol] == nil else { continue }

            results.append((land: (landRow, landCol), capture: (midRow, midCol)))
        }

        return results
    }

    /// Recursively builds all complete multi-jump sequences.
    ///
    /// - Parameters:
    ///   - originRow/originCol: The square the piece started from (constant throughout recursion).
    ///   - currentRow/currentCol: Where the piece currently sits during sequence building.
    ///   - piece: Current piece (may have been promoted mid-sequence).
    ///   - cells: Board state with all earlier captures already removed.
    ///   - capturedSoFar: Squares already captured in this sequence (to avoid re-jumping).
    /// - Returns: All terminal `CheckersMove` values whose `from` equals the origin.
    private func allMultiJumps(
        originRow: Int,
        originCol: Int,
        currentRow: Int,
        currentCol: Int,
        piece: Piece,
        cells: BoardState,
        capturedSoFar: [(row: Int, col: Int)]
    ) -> [CheckersMove] {
        let position = (row: currentRow, col: currentCol)
        let available = jumps(for: piece, at: position, cells: cells)
            .filter { jump in
                !capturedSoFar.contains(where: { $0.row == jump.capture.0 && $0.col == jump.capture.1 })
            }

        if available.isEmpty {
            // Terminal — if we captured at least one piece this is a valid move.
            if !capturedSoFar.isEmpty {
                return [CheckersMove(
                    from: (originRow, originCol),
                    to: (currentRow, currentCol),
                    captures: capturedSoFar
                )]
            }
            return []
        }

        var results: [CheckersMove] = []

        for jump in available {
            let landRow = jump.land.0
            let landCol = jump.land.1
            let capture = (row: jump.capture.0, col: jump.capture.1)

            // Apply this single jump to a scratch board
            var tempCells = cells
            tempCells[currentRow][currentCol] = nil
            tempCells[capture.row][capture.col] = nil

            // Check mid-sequence promotion
            var landingPiece = piece
            if landingPiece.type == .man {
                if landingPiece.player == .red  && landRow == 7 { landingPiece.type = .king }
                if landingPiece.player == .black && landRow == 0 { landingPiece.type = .king }
            }
            tempCells[landRow][landCol] = landingPiece

            let newCaptured = capturedSoFar + [capture]

            // Recurse from the new landing square, keeping the same origin
            let extended = allMultiJumps(
                originRow: originRow,
                originCol: originCol,
                currentRow: landRow,
                currentCol: landCol,
                piece: landingPiece,
                cells: tempCells,
                capturedSoFar: newCaptured
            )
            results.append(contentsOf: extended)
        }

        return results
    }

    /// Diagonal directions a piece is allowed to move (and jump) toward.
    private func forwardDirections(for piece: Piece) -> [(Int, Int)] {
        switch piece.type {
        case .king:
            return [(-1, -1), (-1, 1), (1, -1), (1, 1)]
        case .man:
            // Red moves toward higher rows (down), black moves toward lower rows (up)
            return piece.player == .red ? [(1, -1), (1, 1)] : [(-1, -1), (-1, 1)]
        }
    }

    /// All diagonal directions (for jumps, kings and men can jump backward too in many rule sets).
    /// Here we follow standard English draughts: men can only jump forward, kings jump any direction.
    private func allDirections(for piece: Piece) -> [(Int, Int)] {
        forwardDirections(for: piece)
    }

    private func inBounds(_ row: Int, _ col: Int) -> Bool {
        row >= 0 && row < 8 && col >= 0 && col < 8
    }
}

// MARK: - Equatable

extension CheckersBoard: Equatable {
    static func == (lhs: CheckersBoard, rhs: CheckersBoard) -> Bool {
        guard lhs.currentPlayer == rhs.currentPlayer else { return false }
        for r in 0..<8 {
            for c in 0..<8 {
                if lhs.cells[r][c] != rhs.cells[r][c] { return false }
            }
        }
        return true
    }
}
