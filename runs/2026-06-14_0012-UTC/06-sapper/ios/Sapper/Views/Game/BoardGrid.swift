import SwiftUI

/// Renders the grid of cells at a fixed cell size. Drawn as rows of cells so the
/// whole board scrolls/zooms as one canvas. Sizes are bounded (≤16×30), so a
/// plain VStack/HStack of cells stays smooth.
struct BoardGrid: View {
    @ObservedObject var vm: GameViewModel
    let cellSize: CGFloat
    let haptics: Bool

    var body: some View {
        VStack(spacing: 2) {
            ForEach(0..<vm.rows, id: \.self) { row in
                HStack(spacing: 2) {
                    ForEach(0..<vm.cols, id: \.self) { col in
                        CellView(cell: vm.cell(row, col),
                                 size: cellSize,
                                 isGameOver: vm.isOver)
                            .onTapGesture {
                                vm.primaryTap(row: row, col: col, haptics: haptics)
                            }
                            .onLongPressGesture(minimumDuration: 0.28) {
                                vm.toggleFlag(row: row, col: col, haptics: haptics)
                            }
                            .accessibilityLabel(accessibilityLabel(row, col))
                            .accessibilityHint("Double-tap to reveal, long-press to flag")
                    }
                }
            }
        }
    }

    private func accessibilityLabel(_ row: Int, _ col: Int) -> String {
        let c = vm.cell(row, col)
        let pos = "Row \(row + 1), column \(col + 1)"
        switch c.state {
        case .hidden: return "\(pos), hidden"
        case .flagged: return "\(pos), flagged"
        case .questioned: return "\(pos), question mark"
        case .revealed:
            if c.hasMine { return "\(pos), mine" }
            return c.adjacent == 0 ? "\(pos), empty" : "\(pos), \(c.adjacent)"
        }
    }
}

/// A single cell. Pure presentation given a `Cell` snapshot.
struct CellView: View {
    let cell: Cell
    let size: CGFloat
    let isGameOver: Bool

    var body: some View {
        ZStack {
            background
            content
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: max(3, size * 0.16), style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: max(3, size * 0.16), style: .continuous)
                .strokeBorder(borderColor, lineWidth: 1)
        )
        .contentShape(Rectangle())
    }

    @ViewBuilder private var background: some View {
        switch cell.state {
        case .revealed:
            if cell.hasMine {
                (cell.detonated ? Theme.bad : Theme.bad.opacity(0.18))
            } else {
                Theme.cellRevealed
            }
        default:
            LinearGradient(colors: [Theme.cellHiddenTop, Theme.cellHidden],
                           startPoint: .top, endPoint: .bottom)
        }
    }

    private var borderColor: Color {
        switch cell.state {
        case .revealed: return Theme.hairline.opacity(0.6)
        default: return Theme.hairline
        }
    }

    @ViewBuilder private var content: some View {
        switch cell.state {
        case .hidden:
            EmptyView()
        case .flagged:
            Image(systemName: "flag.fill")
                .font(.system(size: size * 0.48, weight: .black))
                .foregroundStyle(cell.wrongFlag ? Theme.inkFaint : Theme.flag)
                .overlay(wrongFlagSlash)
        case .questioned:
            Text("?")
                .font(Theme.rounded(size * 0.55, .heavy))
                .foregroundStyle(Theme.accent)
        case .revealed:
            revealedContent
        }
    }

    @ViewBuilder private var revealedContent: some View {
        if cell.hasMine {
            Image(systemName: "burst.fill")
                .font(.system(size: size * 0.5, weight: .bold))
                .foregroundStyle(cell.detonated ? Color.white : Theme.ink)
        } else if cell.adjacent > 0 {
            Text("\(cell.adjacent)")
                .font(Theme.rounded(size * 0.56, .black))
                .foregroundStyle(Theme.numberColor(cell.adjacent))
                .monospacedDigit()
        } else {
            EmptyView()
        }
    }

    @ViewBuilder private var wrongFlagSlash: some View {
        if cell.wrongFlag {
            Image(systemName: "xmark")
                .font(.system(size: size * 0.6, weight: .heavy))
                .foregroundStyle(Theme.bad)
        }
    }
}
