import SwiftUI

/// Renders the 9×9 board with selection, peer and same-value highlighting,
/// conflict marking, pencil notes, and bold 3×3 block borders.
struct SudokuGridView: View {
    let current: [Int]
    let givens: [Int]
    let notes: [Int]
    let selected: Int?
    let conflicts: Set<Int>
    let highlightValue: Int?
    let onTap: (Int) -> Void

    private var selectedRow: Int? { selected.map { $0 / 9 } }
    private var selectedCol: Int? { selected.map { $0 % 9 } }
    private var selectedBox: Int? { selected.map { ($0 / 9 / 3) * 3 + ($0 % 9 / 3) } }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let cell = size / 9
            ZStack {
                VStack(spacing: 0) {
                    ForEach(0..<9, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<9, id: \.self) { col in
                                cellView(index: row * 9 + col, side: cell)
                            }
                        }
                    }
                }
                gridLines(cell: cell, size: size)
            }
            .frame(width: size, height: size)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func cellView(index: Int, side: CGFloat) -> some View {
        let value = current[index]
        let isGiven = givens[index] != 0
        let isSelected = selected == index
        let inPeer = (selectedRow == index / 9) || (selectedCol == index % 9)
            || (selectedBox == (index / 9 / 3) * 3 + (index % 9 / 3))
        let isConflict = conflicts.contains(index)
        let sameValue = highlightValue != nil && value != 0 && value == highlightValue

        return ZStack {
            Rectangle()
                .fill(background(isSelected: isSelected, inPeer: inPeer, sameValue: sameValue))
            if value != 0 {
                Text("\(value)")
                    .font(.system(size: side * 0.55,
                                  weight: isGiven ? .semibold : .regular,
                                  design: .rounded))
                    .foregroundStyle(textColor(isGiven: isGiven, isConflict: isConflict))
            } else if notes[index] != 0 {
                notesGrid(mask: notes[index], side: side)
            }
        }
        .frame(width: side, height: side)
        .contentShape(Rectangle())
        .onTapGesture { onTap(index) }
        .accessibilityLabel("Row \(index / 9 + 1) column \(index % 9 + 1)")
        .accessibilityValue(value == 0 ? "empty" : "\(value)\(isGiven ? ", given" : "")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func notesGrid(mask: Int, side: CGFloat) -> some View {
        VStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { r in
                HStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { c in
                        let d = r * 3 + c + 1
                        Text(mask & (1 << (d - 1)) != 0 ? "\(d)" : " ")
                            .font(.system(size: side * 0.2, design: .rounded))
                            .foregroundStyle(Brand.text3)
                            .frame(width: side / 3, height: side / 3)
                    }
                }
            }
        }
    }

    private func background(isSelected: Bool, inPeer: Bool, sameValue: Bool) -> Color {
        if isSelected { return Brand.info.opacity(0.35) }
        if sameValue { return Brand.magic.opacity(0.22) }
        if inPeer { return Brand.info.opacity(0.10) }
        return Color.clear
    }

    private func textColor(isGiven: Bool, isConflict: Bool) -> Color {
        if isConflict { return Brand.danger }
        return isGiven ? Brand.text : Brand.info
    }

    /// Draw the thin and bold (block) grid lines on top.
    private func gridLines(cell: CGFloat, size: CGFloat) -> some View {
        Path { path in
            for i in 0...9 {
                let pos = cell * CGFloat(i)
                path.move(to: CGPoint(x: pos, y: 0)); path.addLine(to: CGPoint(x: pos, y: size))
                path.move(to: CGPoint(x: 0, y: pos)); path.addLine(to: CGPoint(x: size, y: pos))
            }
        }
        .stroke(Brand.hairline, lineWidth: 1)
        .overlay(
            Path { path in
                for i in stride(from: 0, through: 9, by: 3) {
                    let pos = cell * CGFloat(i)
                    path.move(to: CGPoint(x: pos, y: 0)); path.addLine(to: CGPoint(x: pos, y: size))
                    path.move(to: CGPoint(x: 0, y: pos)); path.addLine(to: CGPoint(x: size, y: pos))
                }
            }
            .stroke(Brand.text.opacity(0.7), lineWidth: 2)
        )
        .allowsHitTesting(false)
    }
}
