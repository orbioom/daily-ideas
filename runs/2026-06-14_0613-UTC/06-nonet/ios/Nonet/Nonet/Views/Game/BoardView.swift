import SwiftUI

/// The 9×9 board. Renders cells, grid lines, selection/peer/conflict highlighting, and
/// pencil marks. Each cell has an accessibility label/value. Uses a GeometryReader so the
/// board stays large and legible on every device.
struct BoardView: View {
    @ObservedObject var vm: GameViewModel
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let cell = side / 9.0
            ZStack {
                // Cells
                ForEach(0..<81, id: \.self) { index in
                    cellView(index: index, size: cell)
                        .position(x: cellCenterX(index, cell), y: cellCenterY(index, cell))
                }
                // Grid lines
                gridLines(side: side, cell: cell)
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                    .stroke(Theme.boardLineBold, lineWidth: 2)
            )
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func cellCenterX(_ index: Int, _ cell: CGFloat) -> CGFloat {
        CGFloat(index % 9) * cell + cell / 2
    }
    private func cellCenterY(_ index: Int, _ cell: CGFloat) -> CGFloat {
        CGFloat(index / 9) * cell + cell / 2
    }

    // MARK: Cell

    @ViewBuilder
    private func cellView(index: Int, size: CGFloat) -> some View {
        let value = vm.value(at: index)
        let given = vm.isGiven(index)
        let isSelected = vm.selected == index
        let isConflict = vm.conflicts.contains(index)
        let mask = vm.candidateMask(at: index)

        Rectangle()
            .fill(background(for: index, isSelected: isSelected, isConflict: isConflict))
            .frame(width: size, height: size)
            .overlay {
                if value != 0 {
                    Text("\(value)")
                        .font(Theme.rounded(size * 0.52, given ? .bold : .medium))
                        .foregroundStyle(textColor(given: given, conflict: isConflict, value: value))
                        .minimumScaleFactor(0.5)
                } else if mask != 0 {
                    pencilGrid(mask: mask, size: size)
                }
            }
            .overlay {
                if vm.lastHintIndex == index {
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Theme.accent, lineWidth: 2)
                        .padding(1)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { vm.select(index) }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(cellLabel(index: index))
            .accessibilityValue(value != 0 ? "\(value)" : "empty")
            .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
            .accessibilityHint(given ? "Given clue" : "Double tap to select")
    }

    private func pencilGrid(mask: Int, size: CGFloat) -> some View {
        VStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { r in
                HStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { c in
                        let digit = r * 3 + c + 1
                        let present = mask & (1 << (digit - 1)) != 0
                        Text(present ? "\(digit)" : "")
                            .font(Theme.mono(size * 0.2))
                            .foregroundStyle(Theme.textSecondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }
        .padding(size * 0.04)
        .accessibilityHidden(true)
    }

    // MARK: Styling

    private func background(for index: Int, isSelected: Bool, isConflict: Bool) -> Color {
        if isConflict && (settings.conflictHighlight) { return Theme.cellConflict }
        if isSelected { return Theme.cellSelected }
        guard let sel = vm.selected, sel >= 0, sel < 81 else { return Theme.surface }
        let selVal = vm.value(at: sel)
        if settings.highlightSameNumber, selVal != 0, vm.value(at: index) == selVal {
            return Theme.cellSameNumber
        }
        if settings.highlightPeers, isPeer(of: sel, index) {
            return Theme.cellPeer
        }
        return Theme.surface
    }

    private func isPeer(of sel: Int, _ index: Int) -> Bool {
        guard sel >= 0, sel < 81, index >= 0, index < 81, sel != index else { return false }
        let sr = sel / 9, scol = sel % 9
        let r = index / 9, c = index % 9
        if sr == r || scol == c { return true }
        return (sr / 3 == r / 3) && (scol / 3 == c / 3)
    }

    private func textColor(given: Bool, conflict: Bool, value: Int) -> Color {
        if conflict && settings.conflictHighlight { return Theme.error }
        return given ? Theme.textGiven : Theme.textEntry
    }

    private func cellLabel(index: Int) -> String {
        guard index >= 0, index < 81 else { return "" }
        return "row \(index / 9 + 1) column \(index % 9 + 1)"
    }

    // MARK: Grid lines

    private func gridLines(side: CGFloat, cell: CGFloat) -> some View {
        ZStack {
            ForEach(0...9, id: \.self) { i in
                let bold = i % 3 == 0
                let pos = CGFloat(i) * cell
                // Vertical
                Rectangle()
                    .fill(bold ? Theme.boardLineBold : Theme.boardLine)
                    .frame(width: bold ? 2 : 1, height: side)
                    .position(x: min(pos, side), y: side / 2)
                // Horizontal
                Rectangle()
                    .fill(bold ? Theme.boardLineBold : Theme.boardLine)
                    .frame(width: side, height: bold ? 2 : 1)
                    .position(x: side / 2, y: min(pos, side))
            }
        }
        .allowsHitTesting(false)
    }
}
