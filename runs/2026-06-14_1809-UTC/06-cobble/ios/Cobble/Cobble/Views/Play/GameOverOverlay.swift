import SwiftUI

/// The dimmed game-over panel: final score, best, and a New Game action.
struct GameOverOverlay: View {
    let score: Int
    let best: Int
    let linesCleared: Int
    let longestCombo: Int
    let isNewBest: Bool
    let onNewGame: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            VStack(spacing: 18) {
                Image(systemName: isNewBest ? "crown.fill" : "flag.checkered")
                    .font(.system(size: 44))
                    .foregroundStyle(isNewBest ? Theme.accent : Theme.inkSoft)
                    .accessibilityHidden(true)

                Text(isNewBest ? "New best!" : "No moves left")
                    .font(Theme.rounded(26, .bold))
                    .foregroundStyle(Theme.ink)

                Text("\(score)")
                    .font(Theme.mono(46, .bold))
                    .foregroundStyle(Theme.accent)
                    .accessibilityLabel("Final score \(score)")

                HStack(spacing: 22) {
                    statPill("Best", "\(best)")
                    statPill("Lines", "\(linesCleared)")
                    statPill("Top combo", "\(longestCombo)")
                }

                PrimaryButton(title: "New Game", systemImage: "arrow.clockwise") {
                    onNewGame()
                }
                .padding(.top, 4)
            }
            .padding(26)
            .background(
                RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                    .fill(Theme.surface)
            )
            .padding(.horizontal, 36)
        }
        .accessibilityAddTraits(.isModal)
    }

    private func statPill(_ label: String, _ value: String) -> some View {
        VStack(spacing: 3) {
            Text(value).font(Theme.rounded(18, .bold)).foregroundStyle(Theme.ink)
            Text(label).font(Theme.rounded(11)).foregroundStyle(Theme.inkSoft)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) \(value)")
    }
}
