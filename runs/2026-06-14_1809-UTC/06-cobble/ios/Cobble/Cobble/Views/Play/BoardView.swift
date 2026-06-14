import SwiftUI

/// The 8×8 board. Renders empty wells + filled glassy blocks, draws the ghost preview for
/// the selected piece, and maps taps/drags to board cells for tap-to-place.
///
/// Interaction: a single drag gesture (which also fires on a simple tap) updates the ghost
/// live as the finger moves; on release, a valid spot commits the piece. This keeps the
/// required tap-to-place path reliable while also supporting press-and-drag targeting.
struct BoardView: View {
    @ObservedObject var vm: GameViewModel
    let palette: BlockPalette
    let showGhost: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let n = BlockEngine.size
    private let spacing: CGFloat = 3

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let cell = max(1, (side - spacing * CGFloat(n + 1)) / CGFloat(n))
            let step = cell + spacing
            let ghost = vm.ghostCells()
            let ghostValid = vm.ghostAnchor.map { vm.ghostIsValid($0) } ?? false

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                    .fill(Theme.boardBG)

                ForEach(0..<n, id: \.self) { r in
                    ForEach(0..<n, id: \.self) { c in
                        let coord = Coord(row: r, col: c)
                        BlockCell(colorIndex: vm.grid[safe: r]?[safe: c] ?? 0,
                                  palette: palette,
                                  size: cell,
                                  ghostState: ghostState(coord, inGhost: ghost.contains(coord), valid: ghostValid),
                                  corner: 6)
                            .position(x: spacing + cell / 2 + CGFloat(c) * step,
                                      y: spacing + cell / 2 + CGFloat(r) * step)
                            .accessibilityLabel(cellLabel(r: r, c: c))
                    }
                }
            }
            .frame(width: side, height: side)
            .contentShape(Rectangle())
            .gesture(boardGesture(cell: cell, step: step, side: side))
            .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: vm.flashingCells)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .contain)
    }

    private func ghostState(_ coord: Coord, inGhost: Bool, valid: Bool) -> BlockCell.GhostState {
        if !reduceMotion && vm.flashingCells.contains(coord) { return .flashing }
        guard showGhost, inGhost else { return .none }
        return valid ? .valid : .invalid
    }

    private func cellLabel(r: Int, c: Int) -> String {
        let v = vm.grid[safe: r]?[safe: c] ?? 0
        let state = v > 0 ? "filled" : "empty"
        return "Row \(r + 1), column \(c + 1), \(state)"
    }

    /// Map a point in the board's coordinate space to a (row, col) target.
    private func target(at point: CGPoint, step: CGFloat, side: CGFloat) -> (Int, Int) {
        let usable = side - spacing
        let x = min(max(point.x - spacing, 0), max(usable, 0))
        let y = min(max(point.y - spacing, 0), max(usable, 0))
        let c = min(max(Int(x / step), 0), n - 1)
        let r = min(max(Int(y / step), 0), n - 1)
        return (r, c)
    }

    private func boardGesture(cell: CGFloat, step: CGFloat, side: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard vm.selectedPiece != nil else { return }
                let (r, c) = target(at: value.location, step: step, side: side)
                vm.updateGhost(targetRow: r, col: c)
            }
            .onEnded { value in
                guard vm.selectedPiece != nil else { return }
                let (r, c) = target(at: value.location, step: step, side: side)
                vm.commit(targetRow: r, col: c)
                vm.clearGhost()
            }
    }
}

/// Safe collection subscript used throughout the board to avoid out-of-range crashes.
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
