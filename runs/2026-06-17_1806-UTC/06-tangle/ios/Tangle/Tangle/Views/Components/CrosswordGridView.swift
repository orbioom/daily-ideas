import SwiftUI

/// Renders the crossword grid. Filled cells show as empty tiles until revealed;
/// revealed/hinted cells flip to show their letter. Respects Reduce Motion.
struct CrosswordGridView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let layout: CrosswordLayout
    /// Returns true if a given cell's letter should be shown.
    let isVisible: (GridCoord) -> Bool
    /// Cells that were just revealed (for a brief pop animation).
    let recentlyRevealed: Set<GridCoord>

    var body: some View {
        GeometryReader { geo in
            let cols = max(layout.cols, 1)
            let rows = max(layout.rows, 1)
            let spacing: CGFloat = 4
            let available = min(geo.size.width, geo.size.height)
            let widthBased = (geo.size.width - spacing * CGFloat(cols - 1)) / CGFloat(cols)
            let heightBased = (geo.size.height - spacing * CGFloat(rows - 1)) / CGFloat(rows)
            let cell = max(12, min(widthBased, heightBased, 46))
            let gridW = cell * CGFloat(cols) + spacing * CGFloat(cols - 1)
            let gridH = cell * CGFloat(rows) + spacing * CGFloat(rows - 1)

            VStack(spacing: spacing) {
                ForEach(0..<rows, id: \.self) { r in
                    HStack(spacing: spacing) {
                        ForEach(0..<cols, id: \.self) { c in
                            let coord = GridCoord(row: r, col: c)
                            cellView(coord: coord, side: cell)
                        }
                    }
                }
            }
            .frame(width: gridW, height: gridH)
            .frame(width: geo.size.width, height: geo.size.height)
            .id(available)
        }
    }

    @ViewBuilder
    private func cellView(coord: GridCoord, side: CGFloat) -> some View {
        if let letter = layout.letter(at: coord) {
            let visible = isVisible(coord)
            let popped = recentlyRevealed.contains(coord)
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(visible ? AnyShapeStyle(Theme.tileGradient) : AnyShapeStyle(Theme.surfaceSunken))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(visible ? Theme.accent.opacity(0.55) : Theme.hairline, lineWidth: 1.5)
                    )
                if visible {
                    Text(String(letter))
                        .font(Theme.rounded(side * 0.52, .heavy))
                        .foregroundStyle(Theme.ink)
                        .minimumScaleFactor(0.4)
                }
            }
            .frame(width: side, height: side)
            .scaleEffect(popped && !reduceMotion ? 1.0 : 1.0)
            .animation(reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 0.6), value: visible)
            .accessibilityElement()
            .accessibilityLabel(visible ? "Tile, letter \(String(letter))" : "Hidden tile")
        } else {
            // Empty (non-word) cell — invisible spacer to preserve grid shape.
            Color.clear
                .frame(width: side, height: side)
                .accessibilityHidden(true)
        }
    }
}
