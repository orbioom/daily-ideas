import SwiftUI

/// Renders a tray piece as its polyomino shape laid out on a small grid. Selectable.
struct PieceView: View {
    let piece: Piece?
    let palette: BlockPalette
    var selected: Bool = false
    /// Side length of one block cell.
    var cellSize: CGFloat = 18
    var spacing: CGFloat = 2

    var body: some View {
        if let piece {
            shape(piece)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(label(for: piece))
                .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
        } else {
            // An already-used slot keeps the tray spacing stable.
            RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                .fill(Theme.surfaceAlt.opacity(0.5))
                .frame(width: cellSize * 3, height: cellSize * 3)
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.inkFaint)
                )
                .accessibilityLabel("Used")
        }
    }

    private func shape(_ piece: Piece) -> some View {
        let rows = piece.height
        let cols = piece.width
        let filled = Set(piece.cells)
        return VStack(spacing: spacing) {
            ForEach(0..<rows, id: \.self) { r in
                HStack(spacing: spacing) {
                    ForEach(0..<cols, id: \.self) { c in
                        if filled.contains(Coord(row: r, col: c)) {
                            BlockCell(colorIndex: piece.colorIndex, palette: palette, size: cellSize, corner: 4)
                        } else {
                            Color.clear.frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                .fill(selected ? Theme.accentSoft : Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                .strokeBorder(selected ? Theme.accent : Theme.hairline, lineWidth: selected ? 2 : 1)
        )
        .scaleEffect(selected ? 1.05 : 1.0)
    }

    private func label(for piece: Piece) -> String {
        let s = piece.size
        let cells = s == 1 ? "1 cell" : "\(s) cells"
        return "Block piece, \(cells)\(selected ? ", selected" : "")"
    }
}
