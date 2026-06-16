import SwiftUI

/// The interactive gem grid. Supports tap-tap and drag swap modes.
struct BoardView: View {
    @Bindable var game: GameViewModel
    var swapMode: SwapMode
    var showHints: Bool

    @State private var dragStart: Cell?

    var body: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 4
            let totalSpacing = spacing * CGFloat(game.cols - 1)
            let tile = max(20, (geo.size.width - totalSpacing) / CGFloat(game.cols))

            VStack(spacing: spacing) {
                ForEach(0..<game.board.rows, id: \.self) { r in
                    HStack(spacing: spacing) {
                        ForEach(0..<game.board.cols, id: \.self) { c in
                            cellView(r: r, c: c, tile: tile)
                        }
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.width)
            .contentShape(Rectangle())
            .gesture(swapMode == .drag ? dragGesture(tile: tile, spacing: spacing) : nil)
        }
        .aspectRatio(1, contentMode: .fit)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: Theme.rLarge, style: .continuous)
                .fill(Theme.surfaceRaised)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.rLarge, style: .continuous)
                        .stroke(Theme.hairline, lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private func cellView(r: Int, c: Int, tile: CGFloat) -> some View {
        let cell = Cell(row: r, col: c)
        if let gem = game.board.gem(r, c) {
            let isSelected = game.selection == cell
            let isHinted = showHints && (game.hintMove?.0 == cell || game.hintMove?.1 == cell)
            let isClearing = game.clearing.contains(cell)
            GemView(
                gem: gem,
                size: tile,
                selected: isSelected,
                hinted: isHinted,
                clearing: isClearing,
                reduceMotion: game.reduceMotion
            )
            .id(gem.id)
            .accessibilityElement()
            .accessibilityLabel("\(gem.accessibilityLabel), row \(r + 1) column \(c + 1)")
            .accessibilityHint("Double tap to select, then an adjacent gem to swap.")
            .accessibilityAddTraits(.isButton)
            .onTapGesture {
                if swapMode == .tap { game.tapGem(at: cell) }
            }
        } else {
            // Empty slot during gravity — keep layout stable.
            RoundedRectangle(cornerRadius: Theme.rGem, style: .continuous)
                .fill(Color.clear)
                .frame(width: tile, height: tile)
                .accessibilityHidden(true)
        }
    }

    private func dragGesture(tile: CGFloat, spacing: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: tile * 0.3)
            .onChanged { value in
                if dragStart == nil {
                    dragStart = cellAt(point: value.startLocation, tile: tile, spacing: spacing)
                }
            }
            .onEnded { value in
                defer { dragStart = nil }
                guard let start = dragStart else { return }
                let dx = value.translation.width
                let dy = value.translation.height
                let target: Cell
                if abs(dx) > abs(dy) {
                    target = Cell(row: start.row, col: start.col + (dx > 0 ? 1 : -1))
                } else {
                    target = Cell(row: start.row + (dy > 0 ? 1 : -1), col: start.col)
                }
                game.dragSwap(from: start, to: target)
            }
    }

    private func cellAt(point: CGPoint, tile: CGFloat, spacing: CGFloat) -> Cell? {
        let step = tile + spacing
        guard step > 0 else { return nil }
        let c = Int(point.x / step)
        let r = Int(point.y / step)
        let cell = Cell(row: r, col: c)
        return game.board.inBounds(cell) ? cell : nil
    }
}
