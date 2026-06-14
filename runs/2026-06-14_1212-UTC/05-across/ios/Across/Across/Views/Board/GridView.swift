import SwiftUI

/// Renders the crossword grid: blocks, fillable cells, numbers, entered letters,
/// selection + slot highlight, and check/reveal coloring. Sizes itself to fit.
struct GridView: View {
    @ObservedObject var vm: BoardViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Active board palette (driven by Settings via Theme.palette).
    private var palette: ThemePalette { Theme.palette }

    var body: some View {
        GeometryReader { geo in
            let n = max(vm.engine.cols, 1)
            let m = max(vm.engine.rows, 1)
            let side = min(geo.size.width / CGFloat(n), geo.size.height / CGFloat(m))
            let cell = max(side, 1)

            VStack(spacing: 0) {
                ForEach(0..<m, id: \.self) { r in
                    HStack(spacing: 0) {
                        ForEach(0..<n, id: \.self) { c in
                            cellView(row: r, col: c, size: cell)
                        }
                    }
                }
            }
            .frame(width: cell * CGFloat(n), height: cell * CGFloat(m))
            .overlay(
                Rectangle()
                    .stroke(palette.gridLine, lineWidth: 2)
                    .frame(width: cell * CGFloat(n), height: cell * CGFloat(m))
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private func cellView(row: Int, col: Int, size: CGFloat) -> some View {
        let coord = Coord(row: row, col: col)
        if let info = vm.info(coord) {
            if info.isBlock {
                Rectangle()
                    .fill(palette.blockFill)
                    .frame(width: size, height: size)
                    .border(palette.gridLine, width: 0.5)
                    .accessibilityHidden(true)
            } else {
                fillableCell(coord: coord, info: info, size: size)
            }
        } else {
            Rectangle().fill(palette.blockFill).frame(width: size, height: size)
        }
    }

    private func fillableCell(coord: Coord, info: CellInfo, size: CGFloat) -> some View {
        let isSelected = (coord == vm.selected)
        let inSlot = vm.inCurrentSlot(coord)
        let wrong = vm.isWrong(coord)
        let revealed = vm.isRevealed(coord)
        let letter = vm.letter(at: coord)

        let fill: Color = {
            if isSelected { return palette.selected }
            if inSlot { return palette.slotHighlight }
            return palette.cellFill
        }()

        let pencilled = vm.isPencilled(coord)
        let letterColor: Color = {
            if wrong { return Theme.bad }
            if revealed { return Theme.accent }
            if pencilled { return palette.letter.opacity(0.45) }
            return palette.letter
        }()

        return ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(fill)
                .frame(width: size, height: size)

            if let number = info.number {
                Text("\(number)")
                    .font(.system(size: max(size * 0.24, 8), weight: .semibold))
                    .foregroundStyle(palette.letter.opacity(0.7))
                    .padding(.leading, size * 0.06)
                    .padding(.top, size * 0.02)
                    .accessibilityHidden(true)
            }

            if let letter {
                Text(String(letter))
                    .font(.system(size: max(size * 0.5, 12), weight: .semibold, design: .rounded))
                    .foregroundStyle(letterColor)
                    .frame(width: size, height: size)
            }

            if wrong {
                // Slash mark in the corner to flag an incorrect checked cell.
                Path { p in
                    p.move(to: CGPoint(x: size * 0.72, y: size * 0.08))
                    p.addLine(to: CGPoint(x: size * 0.92, y: size * 0.28))
                }
                .stroke(Theme.bad, lineWidth: 1.5)
                .accessibilityHidden(true)
            }
        }
        .frame(width: size, height: size)
        .border(palette.gridLine, width: 0.5)
        .contentShape(Rectangle())
        .onTapGesture { vm.selectCell(coord) }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: isSelected)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: inSlot)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel(coord: coord, info: info, letter: letter, wrong: wrong))
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }

    private func accessibilityLabel(coord: Coord, info: CellInfo, letter: Character?, wrong: Bool) -> String {
        var parts: [String] = []
        if let number = info.number { parts.append("Cell \(number)") }
        else { parts.append("Cell row \(coord.row + 1), column \(coord.col + 1)") }
        if let letter { parts.append("contains \(letter)") } else { parts.append("empty") }
        if wrong { parts.append("incorrect") }
        return parts.joined(separator: ", ")
    }
}
