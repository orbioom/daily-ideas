import SwiftUI

struct HuntBoardView: View {
    let board: [[Character]]
    let selectedPath: [(Int, Int)]
    let onSelectCell: (Int, Int) -> Void
    let onCommit: () -> Void
    let onCancel: () -> Void

    @State private var boardSize: CGFloat = 0

    private var cellSize: CGFloat { boardSize / 4 }
    private var tilePad: CGFloat { cellSize * 0.06 }
    private var tileSize: CGFloat { cellSize - tilePad * 2 }
    private var cornerRadius: CGFloat { tileSize * 0.18 }

    func cellAt(point: CGPoint) -> (Int, Int)? {
        guard boardSize > 0 else { return nil }
        let col = Int(point.x / cellSize)
        let row = Int(point.y / cellSize)
        guard row >= 0, row < 4, col >= 0, col < 4 else { return nil }
        return (row, col)
    }

    func isSelected(_ r: Int, _ c: Int) -> Bool {
        selectedPath.contains(where: { $0.0 == r && $0.1 == c })
    }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack {
                // Draw path lines
                Canvas { ctx, _ in
                    guard selectedPath.count > 1 else { return }
                    var path = Path()
                    for (i, pos) in selectedPath.enumerated() {
                        let cx = CGFloat(pos.1) * cellSize + cellSize / 2
                        let cy = CGFloat(pos.0) * cellSize + cellSize / 2
                        if i == 0 {
                            path.move(to: CGPoint(x: cx, y: cy))
                        } else {
                            path.addLine(to: CGPoint(x: cx, y: cy))
                        }
                    }
                    ctx.stroke(path, with: .color(HuntTheme.pathColor.opacity(0.7)), style: StrokeStyle(lineWidth: cellSize * 0.15, lineCap: .round, lineJoin: .round))
                }
                .frame(width: size, height: size)

                // Draw tiles
                ForEach(0..<4, id: \.self) { r in
                    ForEach(0..<4, id: \.self) { c in
                        let selected = isSelected(r, c)
                        let isLast = selectedPath.last.map { $0.0 == r && $0.1 == c } ?? false
                        let letter = board.isEmpty ? Character("?") : board[r][c]

                        Text(String(letter))
                            .font(HuntTheme.tileFont(size: tileSize * 0.42))
                            .foregroundStyle(selected ? Color.black : HuntTheme.primaryText)
                            .frame(width: tileSize, height: tileSize)
                            .background(
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .fill(selected ? (isLast ? HuntTheme.tileSelected : HuntTheme.tileSelected.opacity(0.75)) : HuntTheme.tileBackground)
                                    .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 2)
                            )
                            .scaleEffect(selected ? 1.08 : 1.0)
                            .animation(.spring(duration: 0.2), value: selected)
                            .position(
                                x: CGFloat(c) * cellSize + cellSize / 2,
                                y: CGFloat(r) * cellSize + cellSize / 2
                            )
                    }
                }
            }
            .frame(width: size, height: size)
            .contentShape(Rectangle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if let cell = cellAt(point: value.location) {
                            onSelectCell(cell.0, cell.1)
                        }
                    }
                    .onEnded { _ in
                        onCommit()
                    }
            )
            .onAppear { boardSize = size }
            .onChange(of: geo.size) { _, newSize in
                boardSize = min(newSize.width, newSize.height)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
