import SwiftUI

/// The celebratory reveal shown when a puzzle is solved: the full picture, its name, and
/// the solve time. The picture animates in (disabled under Reduce Motion).
struct WinOverlay: View {
    let puzzle: Puzzle
    let timeLabel: String
    let mistakes: Int
    let showMistakes: Bool
    let onClose: () -> Void
    let onReplay: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealProgress: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
                .onTapGesture { onClose() }

            VStack(spacing: 18) {
                Text("Solved!")
                    .font(Theme.rounded(30, .bold))
                    .foregroundStyle(.white)

                pictureCard

                Text(puzzle.name)
                    .font(Theme.rounded(24, .bold))
                    .foregroundStyle(.white)

                HStack(spacing: 14) {
                    badge(icon: "timer", text: timeLabel)
                    badge(icon: "square.grid.2x2", text: puzzle.sizeLabel)
                    if showMistakes {
                        badge(icon: "exclamationmark.triangle", text: "\(mistakes)")
                    }
                }

                VStack(spacing: 10) {
                    PrimaryButton(title: "Done", systemImage: "checkmark") { onClose() }
                    Button("Play again") { onReplay() }
                        .font(Theme.rounded(15, .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .padding(.top, 4)
            }
            .padding(26)
            .frame(maxWidth: 360)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Theme.heroGradient)
                    .shadow(color: .black.opacity(0.3), radius: 24, y: 12)
            )
            .padding(24)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Puzzle solved. \(puzzle.name). Time \(timeLabel).")
        .onAppear {
            if reduceMotion {
                revealProgress = 1
            } else {
                withAnimation(.easeOut(duration: 0.6)) { revealProgress = 1 }
            }
        }
    }

    /// A Canvas rendering the solved picture, fading the filled cells in row-by-row.
    private var pictureCard: some View {
        Canvas { context, size in
            let rows = max(puzzle.rows, 1)
            let cols = max(puzzle.cols, 1)
            let cellW = size.width / CGFloat(cols)
            let cellH = size.height / CGFloat(rows)
            context.fill(Path(CGRect(origin: .zero, size: size)),
                         with: .color(.white.opacity(0.18)))
            let revealedRows = Int((Double(rows) * revealProgress).rounded(.up))
            for r in 0..<min(revealedRows, rows) {
                let row = puzzle.solution[safe: r] ?? []
                for c in 0..<cols where (row[safe: c] ?? false) {
                    let rect = CGRect(x: CGFloat(c) * cellW + 0.5,
                                      y: CGFloat(r) * cellH + 0.5,
                                      width: cellW - 1,
                                      height: cellH - 1)
                    context.fill(Path(roundedRect: rect, cornerRadius: max(cellW * 0.18, 1)),
                                 with: .color(.white))
                }
            }
        }
        .frame(width: 220, height: 220)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(0.12))
        )
        .accessibilityHidden(true)
    }

    private func badge(icon: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 12, weight: .bold))
            Text(text).font(Theme.mono(15, .bold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Capsule().fill(.white.opacity(0.2)))
    }
}
