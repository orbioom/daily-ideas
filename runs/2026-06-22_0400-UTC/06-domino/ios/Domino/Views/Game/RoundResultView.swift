import SwiftUI

struct RoundResultView: View {
    let result: DominoEngine.RoundResult
    let playerScore: Int
    let aiScore: Int
    let matchPointTarget: Int
    let onContinue: () -> Void

    private var isPlayerWin: Bool { result.winner == "player" }
    private var isBlocked: Bool { result.winner == "blocked" }

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Result header
                VStack(spacing: 8) {
                    Text(resultEmoji)
                        .font(.system(size: 48))

                    Text(resultTitle)
                        .font(DominoTheme.titleFont)
                        .foregroundStyle(resultColor)

                    Text(result.reason)
                        .font(DominoTheme.captionFont)
                        .foregroundStyle(DominoTheme.ivory.opacity(0.8))
                        .multilineTextAlignment(.center)
                }

                // Score breakdown
                VStack(spacing: 12) {
                    HStack {
                        scoreBlock(label: "Your Score", value: "+\(result.playerRoundScore)", isHighlight: isPlayerWin)
                        Spacer()
                        scoreBlock(label: "AI Score", value: "+\(result.aiRoundScore)", isHighlight: !isPlayerWin && !isBlocked)
                    }

                    Divider()
                        .background(DominoTheme.gold.opacity(0.3))

                    HStack {
                        totalBlock(label: "Your Total", value: playerScore, target: matchPointTarget)
                        Spacer()
                        totalBlock(label: "AI Total", value: aiScore, target: matchPointTarget)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(DominoTheme.mahoganyDark.opacity(0.8))
                )

                // Continue button
                Button(action: onContinue) {
                    Text("Next Round")
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(DominoTheme.mahogany)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(DominoTheme.gold)
                        )
                }
                .accessibilityLabel("Start next round")
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(DominoTheme.mahogany)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(DominoTheme.gold.opacity(0.4), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 24)
            .dominoCardShadow()
        }
    }

    private var resultTitle: String {
        if isBlocked { return "Game Blocked" }
        return isPlayerWin ? "Round Win!" : "Round Loss"
    }

    private var resultEmoji: String {
        if isBlocked { return "🤝" }
        return isPlayerWin ? "🏆" : "💀"
    }

    private var resultColor: Color {
        if isBlocked { return DominoTheme.gold }
        return isPlayerWin ? DominoTheme.gold : DominoTheme.ivory
    }

    private func scoreBlock(label: String, value: String, isHighlight: Bool) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(DominoTheme.captionFont)
                .foregroundStyle(DominoTheme.ivory.opacity(0.6))
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(isHighlight ? DominoTheme.gold : DominoTheme.ivory)
        }
    }

    private func totalBlock(label: String, value: Int, target: Int) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(DominoTheme.captionFont)
                .foregroundStyle(DominoTheme.ivory.opacity(0.6))
            Text("\(value) / \(target)")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(value >= target ? DominoTheme.gold : DominoTheme.ivory)
        }
    }
}

#Preview {
    RoundResultView(
        result: DominoEngine.RoundResult(
            playerRoundScore: 24,
            aiRoundScore: 0,
            winner: "player",
            reason: "You played all your tiles! (24 pts)"
        ),
        playerScore: 69,
        aiScore: 45,
        matchPointTarget: 100,
        onContinue: {}
    )
}
