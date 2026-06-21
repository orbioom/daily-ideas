import SwiftUI

struct BoardView: View {
    let board: [[GomokuEngine.Stone?]]
    let lastMove: (row: Int, col: Int)?
    let winningCells: Set<String>
    let showCoords: Bool
    let boardTheme: String
    let isThinking: Bool
    let onTap: (Int, Int) -> Void

    private let size = GomokuEngine.size

    private var gridColor: Color {
        boardTheme == "Dark" ? Color.gray.opacity(0.5) : Color(red: 0.3, green: 0.2, blue: 0.05)
    }

    private var boardBG: Color {
        switch boardTheme {
        case "Dark": return Color(red: 0.12, green: 0.12, blue: 0.18)
        case "Bamboo": return Color(red: 0.78, green: 0.65, blue: 0.35)
        default: return Color(red: 0.87, green: 0.72, blue: 0.42)
        }
    }

    var body: some View {
        GeometryReader { geo in
            let totalSize = min(geo.size.width, geo.size.height)
            let labelSpace: CGFloat = showCoords ? 20 : 4
            let boardSize = totalSize - labelSpace * 2
            let cell = boardSize / CGFloat(size - 1)
            let ox = labelSpace
            let oy = labelSpace

            ZStack(alignment: .topLeading) {
                // Board background
                RoundedRectangle(cornerRadius: 8)
                    .fill(boardBG)
                    .frame(width: totalSize, height: totalSize)

                // Grid lines
                Canvas { ctx, _ in
                    for i in 0..<size {
                        let fi = CGFloat(i)
                        var h = Path()
                        h.move(to: CGPoint(x: ox, y: oy + fi * cell))
                        h.addLine(to: CGPoint(x: ox + CGFloat(size - 1) * cell, y: oy + fi * cell))
                        ctx.stroke(h, with: .color(gridColor), lineWidth: i == 0 || i == size - 1 ? 1.5 : 0.7)

                        var v = Path()
                        v.move(to: CGPoint(x: ox + fi * cell, y: oy))
                        v.addLine(to: CGPoint(x: ox + fi * cell, y: oy + CGFloat(size - 1) * cell))
                        ctx.stroke(v, with: .color(gridColor), lineWidth: i == 0 || i == size - 1 ? 1.5 : 0.7)
                    }
                    // Star points (standard Gomoku dots)
                    let starPts = [(3,3),(3,11),(7,7),(11,3),(11,11)]
                    for (sr, sc) in starPts {
                        let cx = ox + CGFloat(sc) * cell
                        let cy = oy + CGFloat(sr) * cell
                        let r: CGFloat = 3.5
                        ctx.fill(Path(ellipseIn: CGRect(x: cx-r, y: cy-r, width: r*2, height: r*2)), with: .color(gridColor.opacity(2)))
                    }
                }
                .frame(width: totalSize, height: totalSize)

                // Coordinate labels
                if showCoords {
                    ForEach(0..<size, id: \.self) { i in
                        let col = String(UnicodeScalar(65 + i)!)
                        Text(col)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(gridColor.opacity(1.5))
                            .frame(width: 14)
                            .position(x: ox + CGFloat(i) * cell, y: 8)
                        Text("\(i + 1)")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(gridColor.opacity(1.5))
                            .frame(width: 14)
                            .position(x: 8, y: oy + CGFloat(i) * cell)
                    }
                }

                // Stones
                Canvas { ctx, _ in
                    for row in 0..<size {
                        for col in 0..<size {
                            guard let stone = board[row][col] else { continue }
                            let cx = ox + CGFloat(col) * cell
                            let cy = oy + CGFloat(row) * cell
                            let r = cell * 0.46
                            let rect = CGRect(x: cx-r, y: cy-r, width: r*2, height: r*2)
                            let key = "\(row),\(col)"
                            let isWin = winningCells.contains(key)

                            if stone == .black {
                                ctx.fill(Path(ellipseIn: rect), with: .color(.black))
                                if isWin {
                                    ctx.fill(Path(ellipseIn: CGRect(x: cx-r*0.35, y: cy-r*0.35, width: r*0.7, height: r*0.7)), with: .color(.yellow))
                                } else if let last = lastMove, last.row == row, last.col == col {
                                    ctx.fill(Path(ellipseIn: CGRect(x: cx-r*0.28, y: cy-r*0.28, width: r*0.56, height: r*0.56)), with: .color(Color(red: 0.6, green: 0.6, blue: 0.6)))
                                }
                            } else {
                                ctx.fill(Path(ellipseIn: rect), with: .color(.white))
                                ctx.stroke(Path(ellipseIn: rect), with: .color(Color(white: 0.5)), lineWidth: 1)
                                if isWin {
                                    ctx.fill(Path(ellipseIn: CGRect(x: cx-r*0.35, y: cy-r*0.35, width: r*0.7, height: r*0.7)), with: .color(.yellow))
                                } else if let last = lastMove, last.row == row, last.col == col {
                                    ctx.fill(Path(ellipseIn: CGRect(x: cx-r*0.28, y: cy-r*0.28, width: r*0.56, height: r*0.56)), with: .color(Color(white: 0.4)))
                                }
                            }
                        }
                    }
                }
                .frame(width: totalSize, height: totalSize)

                // Tap handler
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onEnded { value in
                                let x = value.location.x - ox
                                let y = value.location.y - oy
                                guard cell > 0 else { return }
                                let col = Int((x / cell).rounded())
                                let row = Int((y / cell).rounded())
                                guard row >= 0, row < size, col >= 0, col < size else { return }
                                onTap(row, col)
                            }
                    )
                    .frame(width: totalSize, height: totalSize)
            }
            .frame(width: totalSize, height: totalSize)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
