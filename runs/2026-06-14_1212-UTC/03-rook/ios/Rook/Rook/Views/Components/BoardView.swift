import SwiftUI

/// A reusable chessboard renderer + interaction surface. Used by Play, Puzzles and Learn.
struct BoardView: View {
    let board: Board
    var theme: BoardTheme = .walnut
    var pieceStyle: PieceStyle = .classic
    /// Render from Black's perspective (board flipped) when true.
    var flipped: Bool = false
    var showCoordinates: Bool = true

    // Interaction (all optional so the view can also be a static diagram).
    var selectedSquare: Square? = nil
    var legalTargets: [Square] = []
    var lastMove: Move? = nil
    var checkSquare: Square? = nil
    var showLegalDots: Bool = true
    var onTapSquare: ((Square) -> Void)? = nil

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let cell = side / 8
            ZStack {
                ForEach(0..<64, id: \.self) { display in
                    let sq = squareForDisplay(display)
                    cellView(sq: sq, cell: cell)
                        .position(x: positionX(display, cell: cell),
                                  y: positionY(display, cell: cell))
                }
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(theme.frame, lineWidth: 4)
                    .frame(width: side, height: side)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            )
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Chess board")
    }

    // MARK: Cell

    @ViewBuilder
    private func cellView(sq: Square, cell: CGFloat) -> some View {
        let isLight = (sq.file + sq.rank) % 2 == 1
        ZStack {
            Rectangle()
                .fill(isLight ? theme.lightSquare : theme.darkSquare)

            if lastMove?.from == sq || lastMove?.to == sq {
                Rectangle().fill(theme.highlight)
            }
            if checkSquare == sq {
                Rectangle().fill(theme.checkTint)
            }
            if selectedSquare == sq {
                Rectangle().fill(theme.selection)
            }

            // Coordinates in the corners (rank on file a, file on rank 1).
            if showCoordinates {
                coordinateOverlay(sq: sq, isLight: isLight, cell: cell)
            }

            // Piece.
            if let piece = board.piece(at: sq) {
                PieceGlyph(piece: piece, size: cell * 0.74, style: pieceStyle)
            }

            // Legal-move indicator.
            if showLegalDots, legalTargets.contains(sq) {
                if board.piece(at: sq) == nil {
                    Circle()
                        .fill(theme.dot)
                        .frame(width: cell * 0.30, height: cell * 0.30)
                } else {
                    Circle()
                        .strokeBorder(theme.dot, lineWidth: cell * 0.09)
                        .frame(width: cell * 0.92, height: cell * 0.92)
                }
            }
        }
        .frame(width: cell, height: cell)
        .contentShape(Rectangle())
        .onTapGesture { onTapSquare?(sq) }
        .accessibilityLabel(accessibilityLabel(for: sq))
        .accessibilityAddTraits(onTapSquare != nil ? .isButton : [])
    }

    private func coordinateOverlay(sq: Square, isLight: Bool, cell: CGFloat) -> some View {
        let textColor = (isLight ? theme.darkSquare : theme.lightSquare).opacity(0.9)
        return ZStack {
            if sq.file == (flipped ? 7 : 0) {
                Text("\(sq.rank + 1)")
                    .font(.system(size: cell * 0.20, weight: .semibold, design: .rounded))
                    .foregroundStyle(textColor)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(2)
            }
            if sq.rank == (flipped ? 7 : 0) {
                Text(fileLetter(sq.file))
                    .font(.system(size: cell * 0.20, weight: .semibold, design: .rounded))
                    .foregroundStyle(textColor)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(2)
            }
        }
        .allowsHitTesting(false)
    }

    private func fileLetter(_ f: Int) -> String {
        let files = Array("abcdefgh")
        guard (0..<8).contains(f) else { return "" }
        return String(files[f])
    }

    private func accessibilityLabel(for sq: Square) -> String {
        if let p = board.piece(at: sq) {
            let colorName = p.color == .white ? "White" : "Black"
            let typeName = String(describing: p.type)
            return "\(sq.name), \(colorName) \(typeName)"
        }
        return "\(sq.name), empty"
    }

    // MARK: Layout mapping

    /// Map a display slot (0 = top-left) to a board square, honoring `flipped`.
    private func squareForDisplay(_ display: Int) -> Square {
        let row = display / 8        // 0 at top
        let col = display % 8        // 0 at left
        let file = flipped ? 7 - col : col
        let rank = flipped ? row : 7 - row
        // Display slots 0...63 always map to valid files/ranks; a1 is an unreachable fallback.
        return Square(file: file, rank: rank) ?? .a1
    }

    private func positionX(_ display: Int, cell: CGFloat) -> CGFloat {
        let col = display % 8
        return (CGFloat(col) + 0.5) * cell
    }

    private func positionY(_ display: Int, cell: CGFloat) -> CGFloat {
        let row = display / 8
        return (CGFloat(row) + 0.5) * cell
    }
}
