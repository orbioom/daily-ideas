import SwiftUI

/// A tiny static board diagram used to illustrate the rules in the Learn screen.
struct MiniBoard: View {
    struct Fill: Identifiable {
        let id = UUID()
        let row: Int
        let col: Int
        let colorIndex: Int
        let ghost: Ghost
        init(_ row: Int, _ col: Int, _ colorIndex: Int, ghost: Ghost = .solid) {
            self.row = row; self.col = col; self.colorIndex = colorIndex; self.ghost = ghost
        }
        enum Ghost { case solid, valid, flash }
    }

    let rows: Int
    let cols: Int
    let palette: BlockPalette
    let fills: [Fill]
    var cell: CGFloat = 20
    var gap: CGFloat = 3

    private func fill(_ r: Int, _ c: Int) -> Fill? {
        fills.first { $0.row == r && $0.col == c }
    }

    var body: some View {
        VStack(spacing: gap) {
            ForEach(0..<max(rows, 0), id: \.self) { r in
                HStack(spacing: gap) {
                    ForEach(0..<max(cols, 0), id: \.self) { c in
                        cellView(fill(r, c))
                    }
                }
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous).fill(Theme.boardBG))
    }

    @ViewBuilder
    private func cellView(_ f: Fill?) -> some View {
        if let f {
            switch f.ghost {
            case .solid:
                BlockCell(colorIndex: f.colorIndex, palette: palette, size: cell, corner: 4)
            case .valid:
                BlockCell(colorIndex: f.colorIndex, palette: palette, size: cell,
                          ghostState: .valid, corner: 4)
            case .flash:
                BlockCell(colorIndex: f.colorIndex, palette: palette, size: cell,
                          ghostState: .flashing, corner: 4)
            }
        } else {
            BlockCell(colorIndex: 0, palette: palette, size: cell, corner: 4)
        }
    }
}
