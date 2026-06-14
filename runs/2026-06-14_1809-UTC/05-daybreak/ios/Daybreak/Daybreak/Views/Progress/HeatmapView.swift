import SwiftUI

/// A GitHub-style runs heatmap: weeks as columns, weekdays as rows.
struct HeatmapView: View {
    let cells: [HeatCell]

    private let columns = 7
    private let cellSize: CGFloat = 30

    /// Group cells into rows of 7 (one week per row, oldest first).
    private var rows: [[HeatCell]] {
        guard !cells.isEmpty else { return [] }
        var result: [[HeatCell]] = []
        var i = 0
        while i < cells.count {
            let end = min(i + columns, cells.count)
            result.append(Array(cells[i..<end]))
            i += columns
        }
        return result
    }

    var body: some View {
        VStack(spacing: 6) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 6) {
                    ForEach(row) { cell in
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(color(for: cell.count))
                            .frame(width: cellSize, height: cellSize)
                            .accessibilityLabel(label(for: cell))
                    }
                    // Pad short final row so alignment stays clean.
                    if row.count < columns {
                        ForEach(Array(0..<(columns - row.count)), id: \.self) { _ in
                            Color.clear.frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
            legend
        }
    }

    private var legend: some View {
        HStack(spacing: 6) {
            Text("Less").font(Theme.rounded(11)).foregroundStyle(Theme.inkFaint)
            ForEach(0..<4, id: \.self) { level in
                RoundedRectangle(cornerRadius: 3)
                    .fill(color(for: level))
                    .frame(width: 14, height: 14)
            }
            Text("More").font(Theme.rounded(11)).foregroundStyle(Theme.inkFaint)
        }
        .padding(.top, 4)
        .accessibilityHidden(true)
    }

    private func color(for count: Int) -> Color {
        switch count {
        case 0: return Theme.accentSoft
        case 1: return Theme.accent.opacity(0.4)
        case 2: return Theme.accent.opacity(0.7)
        default: return Theme.accent
        }
    }

    private func label(for cell: HeatCell) -> String {
        let day = cell.date.formatted(.dateTime.month().day())
        if cell.count == 0 { return "\(day): no runs" }
        return "\(day): \(cell.count) run\(cell.count == 1 ? "" : "s")"
    }
}
