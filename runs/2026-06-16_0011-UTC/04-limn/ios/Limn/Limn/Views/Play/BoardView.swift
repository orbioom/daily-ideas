import SwiftUI

/// The interactive nonogram board: a top column-clue strip, a left row-clue strip, and the
/// cell grid. Cells are tappable; for large grids the whole board can be pinched/panned.
/// Rendering is bounds-safe and uses stable IDs for the grid cells.
struct BoardView: View {
    let model: GameViewModel
    let tapMode: TapMode
    let assist: Bool
    let onTap: (Int, Int) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Pan / zoom state (only meaningful for big grids).
    @State private var zoom: CGFloat = 1
    @State private var lastZoom: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private var cols: Int { model.cols }
    private var rows: Int { model.rows }

    /// Base cell size chosen so smaller grids fill the width comfortably.
    private func baseCell(for width: CGFloat) -> CGFloat {
        // Reserve ~28% of width for the row-clue gutter on larger boards.
        let clueGutter: CGFloat = rows >= 10 ? 64 : 44
        let available = max(width - clueGutter - 8, 80)
        let raw = available / CGFloat(max(cols, 1))
        // Clamp so 5×5 isn't gigantic and 15×15 stays tappable.
        return min(max(raw, 18), 56)
    }

    var body: some View {
        GeometryReader { geo in
            let cell = baseCell(for: geo.size.width)
            let clueGutter: CGFloat = rows >= 10 ? 64 : 44
            let clueTop: CGFloat = clueGutter

            let boardContent = VStack(spacing: 0) {
                // Top row: corner spacer + column clues.
                HStack(spacing: 0) {
                    Color.clear.frame(width: clueGutter, height: clueTop)
                    columnClueStrip(cell: cell, height: clueTop)
                }
                // Body: row clues + cells.
                HStack(spacing: 0) {
                    rowClueStrip(cell: cell, width: clueGutter)
                    gridCells(cell: cell)
                }
            }
            .scaleEffect(zoom)
            .offset(offset)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .contentShape(Rectangle())

            // Large boards get pinch-to-zoom and pan; small boards stay fixed.
            Group {
                if rows >= 12 {
                    boardContent.gesture(panZoom)
                } else {
                    boardContent
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    // MARK: - Gestures (large boards only)

    private var panZoom: some Gesture {
        let magnify = MagnificationGesture()
            .onChanged { value in zoom = min(max(lastZoom * value, 1), 3) }
            .onEnded { _ in lastZoom = zoom }
        let drag = DragGesture()
            .onChanged { value in
                offset = CGSize(width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height)
            }
            .onEnded { _ in lastOffset = offset }
        return magnify.simultaneously(with: drag)
    }

    // MARK: - Clue strips

    private func columnClueStrip(cell: CGFloat, height: CGFloat) -> some View {
        HStack(spacing: 0) {
            ForEach(0..<cols, id: \.self) { c in
                let clue = model.columnClues[safe: c] ?? [0]
                VStack(spacing: 1) {
                    Spacer(minLength: 0)
                    ForEach(Array(clueText(clue).enumerated()), id: \.offset) { _, n in
                        Text(n)
                            .font(Theme.mono(min(cell * 0.34, 13), .semibold))
                            .foregroundStyle(Theme.inkSoft)
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                    }
                }
                .frame(width: cell, height: height)
                .background(majorTint(forColumn: c))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Column \(c + 1) clue: \(clueSpoken(clue))")
            }
        }
    }

    private func rowClueStrip(cell: CGFloat, width: CGFloat) -> some View {
        VStack(spacing: 0) {
            ForEach(0..<rows, id: \.self) { r in
                let clue = model.rowClues[safe: r] ?? [0]
                HStack(spacing: 3) {
                    Spacer(minLength: 0)
                    ForEach(Array(clueText(clue).enumerated()), id: \.offset) { _, n in
                        Text(n)
                            .font(Theme.mono(min(cell * 0.36, 13), .semibold))
                            .foregroundStyle(Theme.inkSoft)
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                    }
                }
                .padding(.trailing, 5)
                .frame(width: width, height: cell)
                .background(majorTint(forRow: r))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Row \(r + 1) clue: \(clueSpoken(clue))")
            }
        }
    }

    // MARK: - Cells

    private func gridCells(cell: CGFloat) -> some View {
        VStack(spacing: 0) {
            ForEach(0..<rows, id: \.self) { r in
                HStack(spacing: 0) {
                    ForEach(0..<cols, id: \.self) { c in
                        cellView(r: r, c: c, size: cell)
                    }
                }
            }
        }
        .background(
            // Major 5-cell dividers drawn as an overlay grid.
            GridDividers(rows: rows, cols: cols, cell: cell)
        )
        .overlay(
            Rectangle().strokeBorder(Theme.gridMajor, lineWidth: 1.5)
        )
    }

    private func cellView(r: Int, c: Int, size: CGFloat) -> some View {
        let state = model.state(r, c)
        let isHint = model.lastHintCell.map { $0.row == r && $0.col == c } ?? false
        let isWrong = assist && state == .filled && !model.solutionFilled(r, c)
        return CellTile(state: state, size: size, isHint: isHint, isWrong: isWrong, reduceMotion: reduceMotion)
            .contentShape(Rectangle())
            .onTapGesture { onTap(r, c) }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Row \(r + 1), column \(c + 1)")
            .accessibilityValue(state.accessibilityValue)
            .accessibilityHint("Double-tap to \(tapMode == .fill ? "fill" : "cross") this cell")
            .accessibilityAddTraits(state == .filled ? .isSelected : [])
    }

    // MARK: - Helpers

    private func clueText(_ clue: [Int]) -> [String] {
        let nonzero = clue.filter { $0 > 0 }
        return nonzero.isEmpty ? ["0"] : nonzero.map { "\($0)" }
    }

    private func clueSpoken(_ clue: [Int]) -> String {
        let nonzero = clue.filter { $0 > 0 }
        return nonzero.isEmpty ? "empty" : nonzero.map { "\($0)" }.joined(separator: ", ")
    }

    /// Faint tint every 5th row/column band so the eye can count.
    private func majorTint(forColumn c: Int) -> Color {
        ((c / 5) % 2 == 1) ? Theme.surfaceAlt.opacity(0.5) : Color.clear
    }
    private func majorTint(forRow r: Int) -> Color {
        ((r / 5) % 2 == 1) ? Theme.surfaceAlt.opacity(0.5) : Color.clear
    }
}

/// A single board cell tile, with a satisfying fill animation (disabled under Reduce Motion).
struct CellTile: View {
    let state: CellState
    let size: CGFloat
    let isHint: Bool
    let isWrong: Bool
    let reduceMotion: Bool

    var body: some View {
        ZStack {
            Rectangle()
                .fill(fillColor)
                .overlay(Rectangle().strokeBorder(Theme.gridMinor, lineWidth: 0.5))

            if state == .filled {
                RoundedRectangle(cornerRadius: max(size * 0.12, 2), style: .continuous)
                    .fill(isWrong ? Theme.bad : Theme.boardFill)
                    .padding(size * 0.08)
                    .transition(reduceMotion ? .identity : .scale(scale: 0.5).combined(with: .opacity))
            } else if state == .crossed {
                Image(systemName: "xmark")
                    .font(.system(size: max(size * 0.42, 8), weight: .bold))
                    .foregroundStyle(Theme.inkFaint)
            }

            if isHint {
                RoundedRectangle(cornerRadius: max(size * 0.12, 2), style: .continuous)
                    .strokeBorder(Theme.accent, lineWidth: 2)
                    .padding(1)
            }
        }
        .frame(width: size, height: size)
        .animation(reduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.7), value: state)
    }

    private var fillColor: Color {
        switch state {
        case .unknown: return Theme.boardCell
        case .crossed: return Theme.boardCrossed
        case .filled: return Theme.boardCell
        }
    }
}

/// Draws the bold dividers every 5 cells across the grid for readability.
struct GridDividers: View {
    let rows: Int
    let cols: Int
    let cell: CGFloat

    var body: some View {
        Canvas { context, _ in
            var path = Path()
            for c in stride(from: 5, to: cols, by: 5) {
                let x = CGFloat(c) * cell
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: CGFloat(rows) * cell))
            }
            for r in stride(from: 5, to: rows, by: 5) {
                let y = CGFloat(r) * cell
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: CGFloat(cols) * cell, y: y))
            }
            context.stroke(path, with: .color(Theme.gridMajor), lineWidth: 1)
        }
        .allowsHitTesting(false)
    }
}
