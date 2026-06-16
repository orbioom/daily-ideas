import SwiftUI

/// The interactive letter grid with robust, fully-guarded drag-to-select cell math.
struct WordGridView: View {
    let board: WordSearchBoard
    let highlightColor: Color

    /// Cells in the live selection band.
    let selectionPath: [GridPoint]
    /// Cells belonging to already-found words.
    let foundCells: Set<GridPoint>
    /// Optional briefly-revealed hint cell.
    let hintCell: GridPoint?
    let reduceMotion: Bool

    /// Called continuously while dragging with (start, current) cells.
    let onDragChange: (GridPoint, GridPoint) -> Void
    /// Called on release.
    let onDragEnd: () -> Void

    @State private var dragStart: GridPoint?

    var body: some View {
        GeometryReader { geo in
            let size = board.size
            let side = min(geo.size.width, geo.size.height)
            // Guard against a zero or negative grid size before dividing.
            let cell = size > 0 ? side / CGFloat(size) : side

            ZStack(alignment: .topLeading) {
                // Background board surface.
                RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                    .fill(Theme.surface)
                    .frame(width: side, height: side)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                            .strokeBorder(Theme.hairline, lineWidth: 1)
                    )

                // The connecting band for the live selection.
                if selectionPath.count >= 1, cell > 0 {
                    selectionBand(cell: cell)
                }

                // Letters.
                ForEach(0..<size, id: \.self) { row in
                    ForEach(0..<size, id: \.self) { col in
                        let point = GridPoint(row, col)
                        cellView(point: point, cell: cell)
                            .frame(width: cell, height: cell)
                            .position(
                                x: cell * (CGFloat(col) + 0.5),
                                y: cell * (CGFloat(row) + 0.5)
                            )
                    }
                }
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .contentShape(Rectangle())
            .gesture(dragGesture(cell: cell, side: side))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Word search grid, \(size) by \(size)")
            .accessibilityHint("Drag across letters to select a word")
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: Cells

    @ViewBuilder
    private func cellView(point: GridPoint, cell: CGFloat) -> some View {
        let isFound = foundCells.contains(point)
        let isSelected = selectionPath.contains(point)
        let isHint = hintCell == point

        Text(String(board.letter(at: point)))
            .font(Theme.rounded(max(12, cell * 0.45), .semibold))
            .foregroundStyle(textColor(found: isFound, selected: isSelected))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(cellBackground(found: isFound, selected: isSelected, hint: isHint))
            .clipShape(RoundedRectangle(cornerRadius: cell * 0.18, style: .continuous))
            .scaleEffect(isHint && !reduceMotion ? 1.12 : 1)
            .animation(reduceMotion ? nil : .snappy(duration: 0.2), value: isHint)
    }

    @ViewBuilder
    private func cellBackground(found: Bool, selected: Bool, hint: Bool) -> some View {
        if found {
            highlightColor.opacity(0.22)
        } else if hint {
            Theme.warn.opacity(0.35)
        } else {
            Color.clear
        }
    }

    private func textColor(found: Bool, selected: Bool) -> Color {
        if selected { return .white }
        if found { return highlightColor }
        return Theme.ink
    }

    // MARK: Selection band

    private func selectionBand(cell: CGFloat) -> some View {
        // Draw a rounded capsule from the first to the last selected cell center.
        let points = selectionPath
        let firstPoint = points.first ?? GridPoint(0, 0)
        let lastPoint = points.last ?? firstPoint
        let start = center(of: firstPoint, cell: cell)
        let end = center(of: lastPoint, cell: cell)
        let band = cell * 0.78

        return Path { path in
            path.move(to: start)
            path.addLine(to: end)
        }
        .stroke(highlightColor.opacity(0.85), style: StrokeStyle(lineWidth: band, lineCap: .round))
        .allowsHitTesting(false)
    }

    private func center(of point: GridPoint, cell: CGFloat) -> CGPoint {
        CGPoint(x: cell * (CGFloat(point.col) + 0.5), y: cell * (CGFloat(point.row) + 0.5))
    }

    // MARK: Drag → cell math (fully guarded)

    private func dragGesture(cell: CGFloat, side: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard cell > 0 else { return }
                guard let current = cellAt(location: value.location, cell: cell, side: side) else { return }
                if dragStart == nil {
                    dragStart = current
                }
                if let start = dragStart {
                    onDragChange(start, current)
                }
            }
            .onEnded { _ in
                dragStart = nil
                onDragEnd()
            }
    }

    /// Converts a touch location to a grid cell, or nil if outside the board. Guards all math.
    private func cellAt(location: CGPoint, cell: CGFloat, side: CGFloat) -> GridPoint? {
        guard cell > 0, side > 0 else { return nil }
        guard location.x >= 0, location.y >= 0, location.x < side, location.y < side else { return nil }
        let col = Int(location.x / cell)
        let row = Int(location.y / cell)
        guard row >= 0, row < board.size, col >= 0, col < board.size else { return nil }
        return GridPoint(row, col)
    }
}
