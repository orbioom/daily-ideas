import SwiftUI

/// The 9×9 Sudoku grid. Highlights the selected cell, its peers (row/col/box),
/// and all cells sharing the selected value; flags conflicts in red.
struct BoardView: View {
    let session: GameSession

    @AppStorage("highlightConflicts") private var highlightConflicts = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var selectedValue: Int? {
        guard let s = session.selected else { return nil }
        let v = session.values[s]
        return v == 0 ? nil : v
    }

    var body: some View {
        GeometryReader { geo in
            let dim = min(geo.size.width, geo.size.height)
            let cell = dim / 9
            ZStack {
                // Cells
                ForEach(0..<81, id: \.self) { i in
                    cellView(i, size: cell)
                        .position(x: (CGFloat(i % 9) + 0.5) * cell,
                                  y: (CGFloat(i / 9) + 0.5) * cell)
                }
                gridLines(dim: dim, cell: cell)
            }
            .frame(width: dim, height: dim)
            .frame(maxWidth: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func cellView(_ i: Int, size: CGFloat) -> some View {
        let value = session.values[i]
        let isGiven = session.givenMask[i]
        let isSelected = session.selected == i
        let conflict = highlightConflicts && session.isConflicting(i)
        let highlightPeer = isPeer(of: session.selected, index: i)
        let sameValue = selectedValue != nil && value == selectedValue && value != 0

        return ZStack {
            Rectangle()
                .fill(background(isSelected: isSelected, peer: highlightPeer, same: sameValue, conflict: conflict))
            if value != 0 {
                Text("\(value)")
                    .font(.system(size: size * 0.5, weight: isGiven ? .semibold : .regular, design: .rounded))
                    .foregroundStyle(textColor(isGiven: isGiven, conflict: conflict, selected: isSelected))
            } else {
                notesGrid(session.notes(at: i), size: size)
            }
        }
        .frame(width: size, height: size)
        .contentShape(Rectangle())
        .onTapGesture { session.select(i) }
        .accessibilityElement()
        .accessibilityLabel(cellAccessibility(i, value: value, isGiven: isGiven))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: isSelected)
    }

    private func notesGrid(_ notes: Set<Int>, size: CGFloat) -> some View {
        let cols = Array(repeating: GridItem(.flexible(), spacing: 0), count: 3)
        return LazyVGrid(columns: cols, spacing: 0) {
            ForEach(1...9, id: \.self) { d in
                Text(notes.contains(d) ? "\(d)" : " ")
                    .font(.system(size: size * 0.20, weight: .medium))
                    .foregroundStyle(Brand.text3)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(size * 0.06)
        .accessibilityHidden(true)
    }

    private func background(isSelected: Bool, peer: Bool, same: Bool, conflict: Bool) -> Color {
        if conflict { return Brand.danger.opacity(0.22) }
        if isSelected { return session.difficulty.tint.opacity(0.30) }
        if same { return session.difficulty.tint.opacity(0.18) }
        if peer { return Brand.dynamic(0x000000, 0xFFFFFF).opacity(0.05) }
        return .clear
    }

    private func textColor(isGiven: Bool, conflict: Bool, selected: Bool) -> Color {
        if conflict { return Brand.danger }
        if isGiven { return Brand.text }
        return session.difficulty.tint
    }

    private func isPeer(of sel: Int?, index: Int) -> Bool {
        guard let s = sel, s != index else { return false }
        let sr = s / 9, sc = s % 9, ir = index / 9, ic = index % 9
        if sr == ir || sc == ic { return true }
        return (sr/3 == ir/3) && (sc/3 == ic/3)
    }

    private func gridLines(dim: CGFloat, cell: CGFloat) -> some View {
        Path { path in
            for k in 0...9 {
                let x = CGFloat(k) * cell
                path.move(to: CGPoint(x: x, y: 0)); path.addLine(to: CGPoint(x: x, y: dim))
                let y = CGFloat(k) * cell
                path.move(to: CGPoint(x: 0, y: y)); path.addLine(to: CGPoint(x: dim, y: y))
            }
        }
        .stroke(Brand.hairline, lineWidth: 1)
        .overlay(
            Path { path in
                for k in stride(from: 0, through: 9, by: 3) {
                    let x = CGFloat(k) * cell
                    path.move(to: CGPoint(x: x, y: 0)); path.addLine(to: CGPoint(x: x, y: dim))
                    let y = CGFloat(k) * cell
                    path.move(to: CGPoint(x: 0, y: y)); path.addLine(to: CGPoint(x: dim, y: y))
                }
            }
            .stroke(Brand.text.opacity(0.65), lineWidth: 2)
        )
        .allowsHitTesting(false)
    }

    private func cellAccessibility(_ i: Int, value: Int, isGiven: Bool) -> String {
        let r = i / 9 + 1, c = i % 9 + 1
        let v = value == 0 ? "empty" : "\(value)\(isGiven ? ", clue" : "")"
        return "Row \(r), column \(c), \(v)"
    }
}
