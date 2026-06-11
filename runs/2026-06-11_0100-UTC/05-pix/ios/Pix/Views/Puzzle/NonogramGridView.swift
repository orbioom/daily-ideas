import SwiftUI

struct NonogramGridView: View {
    @Bindable var vm: PixPuzzleViewModel
    let cellSize: CGFloat

    var body: some View {
        let size = vm.puzzle.size
        let rowClues = vm.puzzle.rowClues
        let colClues = vm.puzzle.colClues
        let maxRowClueWidth = rowClues.map { $0.count }.max() ?? 1
        let maxColClueHeight = colClues.map { $0.count }.max() ?? 1
        let clueW = max(20, CGFloat(maxRowClueWidth) * 16)
        let clueH = max(20, CGFloat(maxColClueHeight) * 14)

        VStack(spacing: 0) {
            // Column clues header
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: clueW, height: clueH)

                ForEach(0..<size, id: \.self) { col in
                    VStack(spacing: 0) {
                        let done = vm.isColComplete(col)
                        ForEach(colClues[col], id: \.self) { n in
                            Text("\(n)")
                                .font(PixTheme.clueFont)
                                .foregroundStyle(done ? PixTheme.accent : Color.primary)
                                .frame(width: cellSize, height: 14)
                        }
                    }
                    .frame(width: cellSize, height: clueH, alignment: .bottom)
                    .accessibilityLabel("Column \(col + 1) clue: \(colClues[col].map(String.init).joined(separator: ", "))")
                }
            }

            // Rows
            ForEach(0..<size, id: \.self) { row in
                HStack(spacing: 0) {
                    // Row clue
                    HStack(spacing: 2) {
                        Spacer(minLength: 0)
                        let done = vm.isRowComplete(row)
                        ForEach(rowClues[row], id: \.self) { n in
                            Text("\(n)")
                                .font(PixTheme.clueFont)
                                .foregroundStyle(done ? PixTheme.accent : Color.primary)
                        }
                    }
                    .frame(width: clueW, height: cellSize)
                    .accessibilityLabel("Row \(row + 1) clue: \(rowClues[row].map(String.init).joined(separator: ", "))")

                    // Grid cells
                    ForEach(0..<size, id: \.self) { col in
                        CellView(state: vm.board[row][col], cellSize: cellSize)
                            .onTapGesture { vm.toggleCell(row: row, col: col) }
                            .onLongPressGesture(minimumDuration: 0.3) {
                                let old = vm.inputMode
                                vm.inputMode = old == .excluded ? .filled : .excluded
                                vm.toggleCell(row: row, col: col)
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            }
                            .accessibilityLabel("Row \(row+1), column \(col+1). \(cellStateLabel(vm.board[row][col]))")
                            .accessibilityAddTraits(.isButton)
                    }
                }
                .overlay(alignment: .bottom) {
                    if (row + 1) % 5 == 0 && row < size - 1 {
                        Rectangle()
                            .fill(Color.primary.opacity(0.3))
                            .frame(height: 1)
                    }
                }
            }
        }
    }

    private func cellStateLabel(_ state: CellState) -> String {
        switch state {
        case .filled:   return "Filled"
        case .excluded: return "Marked empty"
        case .unknown:  return "Empty"
        }
    }
}

private struct CellView: View {
    let state: CellState
    let cellSize: CGFloat

    var body: some View {
        ZStack {
            Rectangle()
                .fill(cellFill)
                .frame(width: cellSize, height: cellSize)
                .overlay(
                    Rectangle()
                        .stroke(Color.primary.opacity(0.15), lineWidth: 0.5)
                )

            if state == .excluded {
                Image(systemName: "xmark")
                    .font(.system(size: cellSize * 0.45, weight: .medium))
                    .foregroundStyle(Color.primary.opacity(0.5))
            }
        }
    }

    private var cellFill: Color {
        switch state {
        case .filled:   return PixTheme.filled
        case .excluded: return PixTheme.excluded
        case .unknown:  return PixTheme.empty
        }
    }
}
