import SwiftUI

/// Renders the recessed board tray, empty cells, and the live tiles. Pure
/// presentation: it reads the view model's `tiles` and lays them out by row/col.
/// Swipes are handled by the parent so overlays can sit on top.
struct BoardView: View {
    @ObservedObject var game: GameViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let spacing: CGFloat = 8
    private let trayPadding: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let n = max(1, game.boardSize)
            let cell = max(1, (side - trayPadding * 2 - spacing * CGFloat(n - 1)) / CGFloat(n))
            let corner = max(6, cell * 0.16)

            ZStack(alignment: .topLeading) {
                // Tray
                RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                    .fill(Theme.boardTray)

                // Empty cells
                ForEach(0..<n, id: \.self) { r in
                    ForEach(0..<n, id: \.self) { c in
                        RoundedRectangle(cornerRadius: corner, style: .continuous)
                            .fill(Theme.boardCell)
                            .frame(width: cell, height: cell)
                            .offset(x: origin(c, cell), y: origin(r, cell))
                    }
                }
                .accessibilityHidden(true)

                // Tiles
                ForEach(game.tiles) { tile in
                    TileView(value: tile.value, side: cell, corner: corner)
                        .frame(width: cell, height: cell)
                        .offset(x: origin(tile.col, cell), y: origin(tile.row, cell))
                        .transition(tileTransition)
                }
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .animation(boardAnimation, value: game.tiles.map(\.id))
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(boardAccessibilityLabel)
    }

    private func origin(_ index: Int, _ cell: CGFloat) -> CGFloat {
        trayPadding + CGFloat(index) * (cell + spacing)
    }

    private var boardAnimation: Animation? {
        reduceMotion ? .easeInOut(duration: 0.12) : .spring(response: 0.28, dampingFraction: 0.72)
    }

    private var tileTransition: AnyTransition {
        if reduceMotion {
            return .opacity
        }
        return .asymmetric(
            insertion: .scale(scale: 0.2).combined(with: .opacity),
            removal: .opacity
        )
    }

    private var boardAccessibilityLabel: String {
        let n = game.boardSize
        var parts: [String] = ["\(n) by \(n) board."]
        let filled = game.tiles.count
        if filled == 0 {
            parts.append("Empty.")
        } else {
            let highest = game.tiles.map(\.value).max() ?? 0
            parts.append("\(filled) tiles. Highest \(highest).")
        }
        return parts.joined(separator: " ")
    }
}

/// A single number tile with its per-value color and bold rounded numeral.
struct TileView: View {
    let value: Int
    let side: CGFloat
    let corner: CGFloat

    private var colors: (fill: Color, ink: Color) { Theme.tileColors(forValue: value) }

    private var fontSize: CGFloat {
        let digits = String(value).count
        let base = side * 0.42
        switch digits {
        case 0...2: return base
        case 3: return base * 0.82
        case 4: return base * 0.66
        default: return base * 0.52
        }
    }

    var body: some View {
        RoundedRectangle(cornerRadius: corner, style: .continuous)
            .fill(colors.fill)
            .overlay(
                Text("\(value)")
                    .font(Theme.rounded(fontSize, .heavy))
                    .foregroundStyle(colors.ink)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .padding(2)
            )
            .shadow(color: .black.opacity(0.08), radius: 1, y: 1)
            .accessibilityHidden(true)
    }
}
