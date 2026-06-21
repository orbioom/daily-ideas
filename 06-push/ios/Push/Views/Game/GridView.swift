import SwiftUI

struct GridView: View {
    let game: SokobanGame
    let onMove: (Direction) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Gesture tracking
    @State private var dragStart: CGPoint = .zero

    var body: some View {
        GeometryReader { geo in
            let cellSize = computeCellSize(in: geo.size)
            let gridW = cellSize * CGFloat(game.level.cols)
            let gridH = cellSize * CGFloat(game.level.rows)

            VStack(spacing: 0) {
                ForEach(0..<game.level.rows, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<game.level.cols, id: \.self) { col in
                            CellView(cell: game.grid[row][col], size: cellSize)
                        }
                    }
                }
            }
            .frame(width: gridW, height: gridH)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.10), value: game.playerPos.row)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.10), value: game.playerPos.col)
            .gesture(
                DragGesture(minimumDistance: 12)
                    .onChanged { value in
                        if dragStart == .zero {
                            dragStart = value.startLocation
                        }
                    }
                    .onEnded { value in
                        dragStart = .zero
                        let dx = value.translation.width
                        let dy = value.translation.height
                        let absDx = abs(dx)
                        let absDy = abs(dy)

                        if absDx > absDy {
                            onMove(dx > 0 ? .right : .left)
                        } else {
                            onMove(dy > 0 ? .down : .up)
                        }
                    }
            )
        }
    }

    private func computeCellSize(in size: CGSize) -> CGFloat {
        let byWidth = size.width / CGFloat(game.level.cols)
        let byHeight = size.height / CGFloat(game.level.rows)
        return min(byWidth, byHeight, 56) // cap at 56pt to keep grid tight on iPads
    }
}

#Preview {
    let game = SokobanGame(level: allLevels[0])
    return GridView(game: game, onMove: { _ in })
        .frame(width: 300, height: 200)
        .background(PushTheme.background)
}
