import SwiftUI

/// A small static thumbnail of a puzzle's grid (blocks vs cells), optionally
/// showing solved letters. Used in cards and archive rows.
struct MiniGridPreview: View {
    let grid: [String]
    var solved: Bool = false
    var side: CGFloat = 64

    private var rows: [[Character]] { grid.map { Array($0.uppercased()) } }
    private var cols: Int { rows.first?.count ?? 0 }

    var body: some View {
        let n = max(cols, 1)
        let m = max(rows.count, 1)
        let cell = side / CGFloat(max(n, m))
        VStack(spacing: 0) {
            ForEach(0..<m, id: \.self) { r in
                HStack(spacing: 0) {
                    ForEach(0..<n, id: \.self) { c in
                        cellRect(r: r, c: c, size: cell)
                    }
                }
            }
        }
        .frame(width: cell * CGFloat(n), height: cell * CGFloat(m))
        .overlay(
            Rectangle().stroke(Theme.ink.opacity(0.5), lineWidth: 1)
        )
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func cellRect(r: Int, c: Int, size: CGFloat) -> some View {
        let ch: Character = (r < rows.count && c < rows[r].count) ? rows[r][c] : "#"
        if ch == "#" {
            Rectangle()
                .fill(Theme.ink.opacity(0.85))
                .frame(width: size, height: size)
        } else {
            ZStack {
                Rectangle()
                    .fill(Theme.surface)
                    .frame(width: size, height: size)
                if solved {
                    Text(String(ch))
                        .font(.system(size: size * 0.6, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.ink)
                }
            }
            .overlay(Rectangle().stroke(Theme.ink.opacity(0.35), lineWidth: 0.5))
        }
    }
}
