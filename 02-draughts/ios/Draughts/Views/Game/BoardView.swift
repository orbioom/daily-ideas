import SwiftUI

struct BoardView: View {
    let game: DraughtsGame
    let onTap: (Int, Int) -> Void

    var body: some View {
        GeometryReader { geo in
            let boardSize = min(geo.size.width, geo.size.height)
            let cellSize = boardSize / 8

            ZStack(alignment: .topLeading) {
                // Board background
                boardGrid(cellSize: cellSize, boardSize: boardSize)

                // Pieces
                piecesLayer(cellSize: cellSize)

                // Valid move dots
                moveDots(cellSize: cellSize)

                // Tap layer (invisible, covers entire board)
                tapLayer(cellSize: cellSize, boardSize: boardSize)
            }
            .frame(width: boardSize, height: boardSize)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(DraughtsTheme.gold.opacity(0.5), lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.6), radius: 12, y: 6)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - Sub-layers

    @ViewBuilder
    private func boardGrid(cellSize: CGFloat, boardSize: CGFloat) -> some View {
        Canvas { ctx, _ in
            for row in 0..<8 {
                for col in 0..<8 {
                    let isDark = (row + col) % 2 == 1
                    let rect = CGRect(
                        x: CGFloat(col) * cellSize,
                        y: CGFloat(row) * cellSize,
                        width: cellSize,
                        height: cellSize
                    )
                    ctx.fill(
                        Path(rect),
                        with: .color(isDark ? DraughtsTheme.darkSquare : DraughtsTheme.lightSquare)
                    )
                }
            }
        }
        .frame(width: boardSize, height: boardSize)
        // Highlight last move squares
        .overlay(lastMoveOverlay(cellSize: cellSize))
        // Highlight selected piece square
        .overlay(selectedOverlay(cellSize: cellSize))
    }

    @ViewBuilder
    private func lastMoveOverlay(cellSize: CGFloat) -> some View {
        if let mv = game.lastMove {
            ZStack(alignment: .topLeading) {
                squareHighlight(row: mv.from.row, col: mv.from.col, cellSize: cellSize, color: DraughtsTheme.lastMoveHighlight)
                squareHighlight(row: mv.to.row, col: mv.to.col, cellSize: cellSize, color: DraughtsTheme.lastMoveHighlight)
            }
        }
    }

    @ViewBuilder
    private func selectedOverlay(cellSize: CGFloat) -> some View {
        if let sel = game.selectedCell {
            squareHighlight(row: sel.row, col: sel.col, cellSize: cellSize, color: DraughtsTheme.selectedHighlight)
        }
    }

    private func squareHighlight(row: Int, col: Int, cellSize: CGFloat, color: Color) -> some View {
        Rectangle()
            .fill(color)
            .frame(width: cellSize, height: cellSize)
            .offset(x: CGFloat(col) * cellSize, y: CGFloat(row) * cellSize)
    }

    @ViewBuilder
    private func piecesLayer(cellSize: CGFloat) -> some View {
        let pieceSize = cellSize * 0.78

        ForEach(0..<8, id: \.self) { row in
            ForEach(0..<8, id: \.self) { col in
                if let piece = game.board.cells[row][col] {
                    PieceView(piece: piece, size: pieceSize)
                        .frame(width: cellSize, height: cellSize)
                        .offset(x: CGFloat(col) * cellSize, y: CGFloat(row) * cellSize)
                        .accessibilityLabel(accessibilityLabel(piece: piece, row: row, col: col))
                        .accessibilityAddTraits(
                            piece.player == game.humanPlayer ? .isButton : []
                        )
                }
            }
        }
    }

    @ViewBuilder
    private func moveDots(cellSize: CGFloat) -> some View {
        let dotSize = cellSize * 0.32

        ForEach(game.highlightedMoves, id: \.self) { move in
            Circle()
                .fill(DraughtsTheme.validMoveDot)
                .frame(width: dotSize, height: dotSize)
                .offset(
                    x: CGFloat(move.to.col) * cellSize + (cellSize - dotSize) / 2,
                    y: CGFloat(move.to.row) * cellSize + (cellSize - dotSize) / 2
                )
                .allowsHitTesting(false)
                .accessibilityLabel("Valid move to row \(move.to.row + 1) column \(move.to.col + 1)")
        }
    }

    private func tapLayer(cellSize: CGFloat, boardSize: CGFloat) -> some View {
        Canvas { _, _ in }
            .frame(width: boardSize, height: boardSize)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        let col = Int(value.location.x / cellSize).clamped(to: 0..<8)
                        let row = Int(value.location.y / cellSize).clamped(to: 0..<8)
                        onTap(row, col)
                    }
            )
    }

    // MARK: - Accessibility

    private func accessibilityLabel(piece: Piece, row: Int, col: Int) -> String {
        let playerName = piece.player == .red ? "Red" : "Black"
        let typeName = piece.type == .king ? "king" : "man"
        let selected = game.selectedCell.map { $0.row == row && $0.col == col } ?? false
        let suffix = selected ? ", selected" : ""
        return "\(playerName) \(typeName) at row \(row + 1) column \(col + 1)\(suffix)"
    }
}

// MARK: - Helper

private extension Int {
    func clamped(to range: Range<Int>) -> Int {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound - 1)
    }
}

#Preview {
    let game = DraughtsGame()
    return BoardView(game: game) { _, _ in }
        .padding()
        .background(DraughtsTheme.background)
}
