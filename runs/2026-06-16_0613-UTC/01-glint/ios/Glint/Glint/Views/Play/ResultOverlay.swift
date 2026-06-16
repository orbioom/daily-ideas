import SwiftUI

/// Win/lose overlay with stars and retry/next/exit actions.
struct ResultOverlay: View {
    let outcome: GameViewModel.GameOutcome
    let score: Int
    let mode: GameMode
    let level: Level?
    var onRetry: (() -> Void)?
    var onNext: () -> Void
    var onExit: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var won: Bool {
        if case .won = outcome { return true }
        return false
    }

    private var stars: Int {
        if case .won(let s) = outcome { return s }
        return 0
    }

    private var hasNext: Bool {
        guard mode == .level, let level else { return false }
        return LevelCatalog.level(id: level.id + 1) != nil
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 18) {
                Image(systemName: won ? "checkmark.seal.fill" : "arrow.counterclockwise.circle.fill")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(won ? Theme.good : Theme.warn)
                    .accessibilityHidden(true)

                Text(won ? "Level Complete!" : "Out of Moves")
                    .font(Theme.rounded(26, .bold))
                    .foregroundStyle(Theme.ink)

                if won && mode == .level {
                    StarRow(stars: stars, size: 30)
                        .scaleEffect(reduceMotion ? 1 : 1.1)
                }

                Text("Score: \(score)")
                    .font(Theme.rounded(20, .semibold))
                    .foregroundStyle(Theme.accent)

                VStack(spacing: 10) {
                    if won && hasNext {
                        PrimaryButton(title: "Next Level", systemImage: "arrow.right") { onNext() }
                    }
                    if let onRetry {
                        Button { onRetry() } label: {
                            actionLabel(won ? "Play Again" : "Retry", "arrow.counterclockwise")
                        }
                    }
                    Button { onExit() } label: {
                        actionLabel("Back to Menu", "house.fill")
                    }
                }
            }
            .padding(28)
            .frame(maxWidth: 340)
            .background(RoundedRectangle(cornerRadius: Theme.rLarge).fill(Theme.surface))
            .padding(32)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(won ? "Level complete, \(stars) stars, score \(score)" : "Out of moves, score \(score)")
    }

    private func actionLabel(_ title: String, _ symbol: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
            Text(title).font(Theme.rounded(16, .semibold))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .foregroundStyle(Theme.accent)
        .background(RoundedRectangle(cornerRadius: Theme.rMed).fill(Theme.surfaceRaised))
    }
}
