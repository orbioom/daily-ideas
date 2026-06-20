import SwiftUI

struct DropBoardView: View {
    let game: DropGame
    let onColumnTap: (Int) -> Void

    @State private var hoverCol: Int? = nil
    @State private var winPulse: Bool = false

    private let cols = DropGame.cols
    private let rows = DropGame.rows

    var body: some View {
        GeometryReader { geo in
            let cellSize = min(geo.size.width / CGFloat(cols), geo.size.height / CGFloat(rows))
            let boardW = cellSize * CGFloat(cols)
            let boardH = cellSize * CGFloat(rows)
            let offsetX = (geo.size.width - boardW) / 2
            let offsetY = (geo.size.height - boardH) / 2

            ZStack(alignment: .topLeading) {
                // Board background
                RoundedRectangle(cornerRadius: cellSize * 0.15)
                    .fill(DropTheme.boardColor)
                    .frame(width: boardW, height: boardH)
                    .offset(x: offsetX, y: offsetY)
                    .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)

                // Cells
                ForEach(0..<rows, id: \.self) { row in
                    ForEach(0..<cols, id: \.self) { col in
                        let cellX = offsetX + CGFloat(col) * cellSize
                        let cellY = offsetY + CGFloat(row) * cellSize
                        let padding = cellSize * 0.08
                        let radius = (cellSize - padding * 2) / 2
                        let cx = cellX + cellSize / 2
                        let cy = cellY + cellSize / 2
                        let isWinning = game.winningCells.contains([row, col])
                        let cellState = game.grid[row][col]

                        ZStack {
                            // Background cutout (empty slot)
                            Circle()
                                .fill(DropTheme.slotColor)
                                .frame(width: radius * 2, height: radius * 2)

                            // Disc fill
                            if cellState != .empty {
                                Circle()
                                    .fill(cellState == .human ? DropTheme.humanColor : DropTheme.cpuColor)
                                    .frame(width: radius * 2, height: radius * 2)
                                    .overlay(
                                        Circle()
                                            .fill(
                                                RadialGradient(
                                                    colors: [.white.opacity(0.3), .clear],
                                                    center: UnitPoint(x: 0.35, y: 0.3),
                                                    startRadius: 0,
                                                    endRadius: radius * 0.8
                                                )
                                            )
                                    )
                            }

                            // Winning highlight ring
                            if isWinning {
                                Circle()
                                    .stroke(Color.white, lineWidth: winPulse ? 3 : 1.5)
                                    .frame(width: radius * 2 + (winPulse ? 4 : 0),
                                           height: radius * 2 + (winPulse ? 4 : 0))
                                    .shadow(color: .white.opacity(winPulse ? 0.9 : 0.4), radius: winPulse ? 8 : 3)
                            }
                        }
                        .position(x: cx, y: cy)
                    }
                }

                // Column hover indicator (drop guide)
                if let hc = hoverCol, case .playing = game.phase {
                    let cellX = offsetX + CGFloat(hc) * cellSize
                    let cellY = offsetY - cellSize * 0.6
                    let padding = cellSize * 0.08
                    let radius = (cellSize - padding * 2) / 2

                    Circle()
                        .fill(DropTheme.playerColor(game.currentPlayer).opacity(0.7))
                        .frame(width: radius * 2, height: radius * 2)
                        .overlay(
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [.white.opacity(0.3), .clear],
                                        center: UnitPoint(x: 0.35, y: 0.3),
                                        startRadius: 0,
                                        endRadius: radius * 0.8
                                    )
                                )
                        )
                        .position(x: cellX + cellSize / 2, y: cellY + cellSize / 2)
                        .animation(.easeInOut(duration: 0.15), value: hc)
                }

                // Invisible tap zones per column
                ForEach(0..<cols, id: \.self) { col in
                    let cellX = offsetX + CGFloat(col) * cellSize
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: cellSize, height: boardH + cellSize)
                        .contentShape(Rectangle())
                        .position(x: cellX + cellSize / 2, y: offsetY + boardH / 2)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    if case .playing = game.phase, game.currentPlayer == .human {
                                        hoverCol = col
                                    }
                                }
                                .onEnded { _ in
                                    if case .playing = game.phase, game.currentPlayer == .human {
                                        onColumnTap(col)
                                    }
                                    hoverCol = nil
                                }
                        )
                        .accessibilityLabel("Drop in column \(col + 1)")
                        .accessibilityAddTraits(.isButton)
                        .accessibilityAction {
                            if case .playing = game.phase, game.currentPlayer == .human {
                                onColumnTap(col)
                            }
                        }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .onChange(of: game.winningCells) { _, newVal in
                if !newVal.isEmpty {
                    withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                        winPulse = true
                    }
                } else {
                    winPulse = false
                }
            }
        }
    }
}
