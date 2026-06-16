import SwiftUI

/// A board tile for the home grid: color/symbol header, progress ring, counts.
struct BoardCardView: View {
    let board: Board

    private var color: Color { Color(hex: UInt(max(0, board.colorHex))) }
    private var total: Int { BoardEngine.totalCards(for: board) }
    private var done: Int { BoardEngine.completedCount(for: board) }
    private var progress: Double { BoardEngine.progress(for: board) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(color.opacity(0.18))
                        .frame(width: 42, height: 42)
                    Image(systemName: board.symbolName)
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(color)
                        .accessibilityHidden(true)
                }
                Spacer()
                ProgressRing(progress: progress, size: 40, lineWidth: 4, tint: color)
            }

            Text(board.name)
                .font(Theme.rounded(17, .bold))
                .foregroundStyle(Theme.ink)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 14) {
                stat(value: "\(board.columns.count)", label: "lanes")
                stat(value: "\(total)", label: "cards")
                stat(value: "\(done)", label: "done")
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(board.name)
        .accessibilityValue("\(total) cards, \(done) done, \(Int(progress * 100)) percent complete")
        .accessibilityHint("Opens the board")
    }

    private func stat(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value)
                .font(Theme.rounded(15, .bold))
                .foregroundStyle(Theme.ink)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Theme.inkSoft)
        }
    }
}
