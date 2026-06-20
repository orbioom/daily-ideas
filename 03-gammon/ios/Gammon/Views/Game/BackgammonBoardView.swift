import SwiftUI

// MARK: - Backgammon Board View
// Canvas-rendered board. Portrait layout:
//   Top row: points 13–24 (triangles point DOWN), left-to-right display = 13,14,15,16,17,18 | bar | 19,20,21,22,23,24
//   Bottom row: points 12–1 (triangles point UP),  left-to-right display = 12,11,10,9,8,7   | bar | 6,5,4,3,2,1
//   Board index: point N displayed is index (N-1) in the points array.

struct BackgammonBoardView: View {
    let game: BackgammonGame
    let boardScheme: BoardColorScheme
    let onTapPoint: (Int) -> Void
    let onTapBar: () -> Void
    let onTapBearOff: () -> Void

    var body: some View {
        GeometryReader { geo in
            let layout = BoardLayout(size: geo.size)
            Canvas { ctx, size in
                drawBoard(ctx: ctx, layout: layout)
                drawPoints(ctx: ctx, layout: layout)
                drawPieces(ctx: ctx, layout: layout)
                drawBarPieces(ctx: ctx, layout: layout)
                drawBearOffAreas(ctx: ctx, layout: layout)
                drawLegalDots(ctx: ctx, layout: layout)
                drawDiceIfNeeded(ctx: ctx, layout: layout)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        handleTap(at: value.location, layout: layout)
                    }
            )
        }
    }

    // MARK: - Layout

    struct BoardLayout {
        let size: CGSize
        let borderW: CGFloat
        let barW: CGFloat
        let boardRect: CGRect
        let topRowY: CGFloat
        let bottomRowY: CGFloat
        let pointH: CGFloat
        let sectionW: CGFloat   // width of each 6-point section
        let pointW: CGFloat     // width of each triangle
        let pieceDiam: CGFloat

        init(size: CGSize) {
            self.size = size
            let w = size.width
            let h = size.height
            borderW = w * 0.04
            barW = w * 0.08
            let bx = borderW
            let by = borderW
            let bw = w - 2 * borderW
            let bh = h - 2 * borderW
            boardRect = CGRect(x: bx, y: by, width: bw, height: bh)
            sectionW = (bw - barW) / 2
            pointW = sectionW / 6
            pointH = bh * 0.42
            topRowY = by
            bottomRowY = by + bh
            pieceDiam = min(pointW * 0.82, 34)
        }

        // Returns the tip X center for a given point column in a section
        // column 0..5 within a section
        func pointXCenter(section: Int, col: Int) -> CGFloat {
            // section 0 = left (indices 0..5), section 1 = right (indices 6..11)
            let sectionStartX = boardRect.minX + (section == 0 ? 0 : sectionW + barW)
            return sectionStartX + (CGFloat(col) + 0.5) * pointW
        }

        // Returns the tip-toward-center Y for a triangle (top or bottom row)
        func trianglePath(xCenter: CGFloat, isTop: Bool, baseW: CGFloat, height: CGFloat) -> Path {
            var p = Path()
            if isTop {
                // Triangle points DOWN: base at top, tip at bottom
                p.move(to: CGPoint(x: xCenter - baseW/2, y: boardRect.minY))
                p.addLine(to: CGPoint(x: xCenter + baseW/2, y: boardRect.minY))
                p.addLine(to: CGPoint(x: xCenter, y: boardRect.minY + height))
                p.closeSubpath()
            } else {
                // Triangle points UP: base at bottom, tip at top
                p.move(to: CGPoint(x: xCenter - baseW/2, y: boardRect.maxY))
                p.addLine(to: CGPoint(x: xCenter + baseW/2, y: boardRect.maxY))
                p.addLine(to: CGPoint(x: xCenter, y: boardRect.maxY - height))
                p.closeSubpath()
            }
            return p
        }

        // Center of bar
        var barCenterX: CGFloat {
            boardRect.minX + sectionW + barW / 2
        }

        var bearOffRightX: CGFloat {
            boardRect.maxX + borderW / 2
        }
    }

    // MARK: - Drawing

    private func drawBoard(ctx: GraphicsContext, layout: BoardLayout) {
        // Outer border / frame
        let outerRect = CGRect(x: 0, y: 0, width: layout.size.width, height: layout.size.height)
        ctx.fill(Path(roundedRect: outerRect, cornerRadius: 8), with: .color(boardScheme.boardBorder))

        // Board surface
        ctx.fill(Path(layout.boardRect), with: .color(boardScheme.boardSurface))

        // Bar
        let barRect = CGRect(
            x: layout.boardRect.minX + layout.sectionW,
            y: layout.boardRect.minY,
            width: layout.barW,
            height: layout.boardRect.height
        )
        ctx.fill(Path(barRect), with: .color(GammonTheme.barColor))

        // Center divider line
        let midY = layout.boardRect.midY
        let divLine = Path { p in
            p.move(to: CGPoint(x: layout.boardRect.minX, y: midY))
            p.addLine(to: CGPoint(x: layout.boardRect.minX + layout.sectionW, y: midY))
            p.move(to: CGPoint(x: layout.boardRect.minX + layout.sectionW + layout.barW, y: midY))
            p.addLine(to: CGPoint(x: layout.boardRect.maxX, y: midY))
        }
        ctx.stroke(divLine, with: .color(boardScheme.boardBorder), lineWidth: 2)
    }

    private func drawPoints(ctx: GraphicsContext, layout: BoardLayout) {
        // Top row: point indices 12–23 (display left-to-right = 12,13,14,15,16,17 | 18,19,20,21,22,23)
        // Bottom row: point indices 11–0 (display left-to-right = 11,10,9,8,7,6 | 5,4,3,2,1,0)

        // Top section left: indices 12,13,14,15,16,17 → columns 0..5
        for col in 0..<6 {
            let idx = 12 + col
            let xc = layout.pointXCenter(section: 0, col: col)
            let color = (col % 2 == 0) ? boardScheme.pointColorA : boardScheme.pointColorB
            let path = layout.trianglePath(xCenter: xc, isTop: true, baseW: layout.pointW * 0.95, height: layout.pointH)
            ctx.fill(path, with: .color(color.opacity(0.9)))
            drawPointNumber(ctx: ctx, layout: layout, number: idx + 1, xCenter: xc, isTop: true)
        }

        // Top section right: indices 18,19,20,21,22,23 → columns 0..5
        for col in 0..<6 {
            let idx = 18 + col
            let xc = layout.pointXCenter(section: 1, col: col)
            let color = (col % 2 == 0) ? boardScheme.pointColorA : boardScheme.pointColorB
            let path = layout.trianglePath(xCenter: xc, isTop: true, baseW: layout.pointW * 0.95, height: layout.pointH)
            ctx.fill(path, with: .color(color.opacity(0.9)))
            drawPointNumber(ctx: ctx, layout: layout, number: idx + 1, xCenter: xc, isTop: true)
        }

        // Bottom section left: indices 11,10,9,8,7,6 → columns 0..5
        for col in 0..<6 {
            let idx = 11 - col
            let xc = layout.pointXCenter(section: 0, col: col)
            let color = (col % 2 == 0) ? boardScheme.pointColorA : boardScheme.pointColorB
            let path = layout.trianglePath(xCenter: xc, isTop: false, baseW: layout.pointW * 0.95, height: layout.pointH)
            ctx.fill(path, with: .color(color.opacity(0.9)))
            drawPointNumber(ctx: ctx, layout: layout, number: idx + 1, xCenter: xc, isTop: false)
        }

        // Bottom section right: indices 5,4,3,2,1,0 → columns 0..5
        for col in 0..<6 {
            let idx = 5 - col
            let xc = layout.pointXCenter(section: 1, col: col)
            let color = (col % 2 == 0) ? boardScheme.pointColorA : boardScheme.pointColorB
            let path = layout.trianglePath(xCenter: xc, isTop: false, baseW: layout.pointW * 0.95, height: layout.pointH)
            ctx.fill(path, with: .color(color.opacity(0.9)))
            drawPointNumber(ctx: ctx, layout: layout, number: idx + 1, xCenter: xc, isTop: false)
        }
    }

    private func drawPointNumber(ctx: GraphicsContext, layout: BoardLayout, number: Int, xCenter: CGFloat, isTop: Bool) {
        let text = Text("\(number)").font(.system(size: 9, weight: .medium)).foregroundStyle(Color.white.opacity(0.35))
        let yOffset: CGFloat = isTop ? 6 : -6
        let anchor: UnitPoint = isTop ? .top : .bottom
        ctx.draw(text, at: CGPoint(x: xCenter, y: isTop ? layout.boardRect.minY + yOffset : layout.boardRect.maxY + yOffset), anchor: anchor)
    }

    private func drawPieces(ctx: GraphicsContext, layout: BoardLayout) {
        let d = layout.pieceDiam

        // Top row pieces
        for col in 0..<6 {
            drawPiecesAtPoint(ctx: ctx, layout: layout, pointIdx: 12 + col,
                              xc: layout.pointXCenter(section: 0, col: col), isTop: true)
        }
        for col in 0..<6 {
            drawPiecesAtPoint(ctx: ctx, layout: layout, pointIdx: 18 + col,
                              xc: layout.pointXCenter(section: 1, col: col), isTop: true)
        }

        // Bottom row pieces
        for col in 0..<6 {
            drawPiecesAtPoint(ctx: ctx, layout: layout, pointIdx: 11 - col,
                              xc: layout.pointXCenter(section: 0, col: col), isTop: false)
        }
        for col in 0..<6 {
            drawPiecesAtPoint(ctx: ctx, layout: layout, pointIdx: 5 - col,
                              xc: layout.pointXCenter(section: 1, col: col), isTop: false)
        }
        let _ = d
    }

    private func drawPiecesAtPoint(ctx: GraphicsContext, layout: BoardLayout, pointIdx: Int, xc: CGFloat, isTop: Bool) {
        guard pointIdx >= 0 && pointIdx < 24 else { return }
        let point = game.points[pointIdx]
        guard point.count > 0, let color = point.color else { return }

        let d = layout.pieceDiam
        let maxVisible = 5
        let count = point.count

        let isSelected = (game.selectedFrom == pointIdx)
        let isLegalDest = game.legalDests.contains(pointIdx)

        // If more than maxVisible, compress
        let spacing: CGFloat = count > maxVisible ? d * 0.55 : d * 0.95

        for i in 0..<count {
            let yOff = CGFloat(i) * spacing
            let yCenter: CGFloat
            if isTop {
                yCenter = layout.boardRect.minY + d / 2 + yOff
            } else {
                yCenter = layout.boardRect.maxY - d / 2 - yOff
            }

            let pieceRect = CGRect(x: xc - d/2, y: yCenter - d/2, width: d, height: d)

            // Shadow
            let shadowRect = pieceRect.offsetBy(dx: 1, dy: 2)
            ctx.fill(Path(ellipseIn: shadowRect), with: .color(Color.black.opacity(0.4)))

            // Piece body
            let pieceColor = color == .white ? GammonTheme.whitePiece : GammonTheme.blackPiece
            ctx.fill(Path(ellipseIn: pieceRect), with: .color(pieceColor))

            // Piece highlight (top left gleam)
            let highlightRect = CGRect(
                x: pieceRect.minX + d * 0.18,
                y: pieceRect.minY + d * 0.12,
                width: d * 0.32,
                height: d * 0.22
            )
            ctx.fill(Path(ellipseIn: highlightRect), with: .color(Color.white.opacity(color == .white ? 0.5 : 0.15)))

            // Selection ring on top piece
            if isSelected && i == count - 1 {
                ctx.stroke(Path(ellipseIn: pieceRect.insetBy(dx: -2, dy: -2)),
                           with: .color(GammonTheme.highlightRing),
                           lineWidth: 3)
            }
        }

        // Legal destination overlay (dot on the point area)
        if isLegalDest {
            let dotY: CGFloat = isTop ? layout.boardRect.minY + layout.pointH * 0.75 : layout.boardRect.maxY - layout.pointH * 0.75
            let dotRect = CGRect(x: xc - 8, y: dotY - 8, width: 16, height: 16)
            ctx.fill(Path(ellipseIn: dotRect), with: .color(GammonTheme.legalDot))
        }
    }

    private func drawBarPieces(ctx: GraphicsContext, layout: BoardLayout) {
        let d = layout.pieceDiam
        let xc = layout.barCenterX

        // White bar (top half of bar)
        for i in 0..<game.whiteBar {
            let yCenter = layout.boardRect.midY - CGFloat(i + 1) * (d * 0.9) - 4
            let pieceRect = CGRect(x: xc - d/2, y: yCenter - d/2, width: d, height: d)
            ctx.fill(Path(ellipseIn: pieceRect.offsetBy(dx: 1, dy: 2)), with: .color(Color.black.opacity(0.3)))
            ctx.fill(Path(ellipseIn: pieceRect), with: .color(GammonTheme.whitePiece))
            ctx.stroke(Path(ellipseIn: pieceRect), with: .color(GammonTheme.accent.opacity(0.6)), lineWidth: 1.5)
            if game.selectedFrom == -1 && game.currentPlayer == .white {
                ctx.stroke(Path(ellipseIn: pieceRect.insetBy(dx: -2, dy: -2)), with: .color(GammonTheme.highlightRing), lineWidth: 2.5)
            }
        }

        // Black bar (bottom half of bar)
        for i in 0..<game.blackBar {
            let yCenter = layout.boardRect.midY + CGFloat(i + 1) * (d * 0.9) + 4
            let pieceRect = CGRect(x: xc - d/2, y: yCenter - d/2, width: d, height: d)
            ctx.fill(Path(ellipseIn: pieceRect.offsetBy(dx: 1, dy: 2)), with: .color(Color.black.opacity(0.3)))
            ctx.fill(Path(ellipseIn: pieceRect), with: .color(GammonTheme.blackPiece))
            ctx.stroke(Path(ellipseIn: pieceRect), with: .color(GammonTheme.accent.opacity(0.4)), lineWidth: 1.5)
            if game.selectedFrom == -1 && game.currentPlayer == .black {
                ctx.stroke(Path(ellipseIn: pieceRect.insetBy(dx: -2, dy: -2)), with: .color(GammonTheme.highlightRing), lineWidth: 2.5)
            }
        }

        // Bar legal dest highlight
        if game.legalDests.contains(-1) {
            let dotRect = CGRect(x: xc - 8, y: layout.boardRect.midY - 8, width: 16, height: 16)
            ctx.fill(Path(ellipseIn: dotRect), with: .color(GammonTheme.legalDot))
        }
    }

    private func drawBearOffAreas(ctx: GraphicsContext, layout: BoardLayout) {
        // Right side bear-off strip
        let rightX = layout.boardRect.maxX
        let bw: CGFloat = layout.borderW * 0.8
        let bh = layout.boardRect.height

        // White off (bottom right)
        let whiteOffRect = CGRect(x: rightX + 2, y: layout.boardRect.maxY - bh/2, width: bw, height: bh/2)
        ctx.fill(Path(whiteOffRect), with: .color(GammonTheme.whitePiece.opacity(0.1)))
        let whiteText = Text("W:\(game.whiteOff)").font(.system(size: 10, weight: .bold)).foregroundStyle(GammonTheme.whitePiece.opacity(0.7))
        ctx.draw(whiteText, at: CGPoint(x: rightX + bw/2 + 2, y: layout.boardRect.maxY - 12), anchor: .bottom)

        // Black off (top right)
        let blackOffRect = CGRect(x: rightX + 2, y: layout.boardRect.minY, width: bw, height: bh/2)
        ctx.fill(Path(blackOffRect), with: .color(GammonTheme.blackPiece.opacity(0.3)))
        let blackText = Text("B:\(game.blackOff)").font(.system(size: 10, weight: .bold)).foregroundStyle(GammonTheme.textSecondary)
        ctx.draw(blackText, at: CGPoint(x: rightX + bw/2 + 2, y: layout.boardRect.minY + 12), anchor: .top)

        // Bear-off legal dest highlight
        if game.legalDests.contains(-2) {
            let dotRect = CGRect(x: rightX + 4, y: layout.boardRect.midY - 10, width: 20, height: 20)
            ctx.fill(Path(ellipseIn: dotRect), with: .color(GammonTheme.legalDot))
        }
    }

    private func drawLegalDots(ctx: GraphicsContext, layout: BoardLayout) {
        // Legal dots for board points are drawn inside drawPiecesAtPoint.
        // This function is a hook for any additional legal-dest overlays not covered elsewhere.
    }

    private func drawDiceIfNeeded(ctx: GraphicsContext, layout: BoardLayout) {
        // Dice are drawn in DiceView, not on the board canvas
    }

    // MARK: - Tap Handling

    private func handleTap(at location: CGPoint, layout: BoardLayout) {
        // Check bar
        let barRect = CGRect(
            x: layout.boardRect.minX + layout.sectionW,
            y: layout.boardRect.minY,
            width: layout.barW,
            height: layout.boardRect.height
        )
        if barRect.contains(location) {
            onTapBar()
            return
        }

        // Check bear-off area
        let bearOffRect = CGRect(
            x: layout.boardRect.maxX,
            y: layout.boardRect.minY,
            width: layout.borderW,
            height: layout.boardRect.height
        )
        if bearOffRect.contains(location) {
            onTapBearOff()
            return
        }

        // Map location to point index
        if let idx = pointIndex(at: location, layout: layout) {
            onTapPoint(idx)
        }
    }

    private func pointIndex(at location: CGPoint, layout: BoardLayout) -> Int? {
        let x = location.x
        let y = location.y
        let br = layout.boardRect
        guard br.contains(location) else { return nil }

        let isTop = y < br.midY
        let isRightSection = x > (br.minX + layout.sectionW + layout.barW)
        let sectionStartX = isRightSection ? (br.minX + layout.sectionW + layout.barW) : br.minX
        let colF = (x - sectionStartX) / layout.pointW
        let col = Int(colF).clamped(to: 0...5)

        if isTop {
            // Top section left → indices 12..17, right → 18..23
            return isRightSection ? (18 + col) : (12 + col)
        } else {
            // Bottom section left → indices 11..6 (col0=11, col5=6), right → 5..0 (col0=5, col5=0)
            return isRightSection ? (5 - col) : (11 - col)
        }
    }
}

// MARK: - Int Clamped Extension

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
