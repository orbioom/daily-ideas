import SwiftUI

struct GameOverView: View {
    let game: GinRummyGame
    let onNewGame: () -> Void
    let onMenu: () -> Void

    var body: some View {
        ZStack {
            AnteTheme.feltGreenDark
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 16) {
                    if game.humanPlayerWon {
                        Text("WINNER!")
                            .font(.system(size: 52, weight: .black, design: .serif))
                            .foregroundColor(AnteTheme.gold)
                            .shadow(color: AnteTheme.gold.opacity(0.6), radius: 20)

                        Image(systemName: "crown.fill")
                            .font(.system(size: 64))
                            .foregroundColor(AnteTheme.gold)
                    } else {
                        Text("GAME OVER")
                            .font(.system(size: 44, weight: .black, design: .serif))
                            .foregroundColor(.white.opacity(0.8))

                        Image(systemName: "xmark.circle")
                            .font(.system(size: 64))
                            .foregroundColor(.red.opacity(0.7))
                    }
                }

                // Final scores
                HStack(spacing: 50) {
                    finalScoreColumn(label: "You", score: game.playerScore, isWinner: game.humanPlayerWon)
                    finalScoreColumn(
                        label: game.gameMode == "passAndPlay" ? "Player 2" : "CPU",
                        score: game.opponentScore,
                        isWinner: !game.humanPlayerWon
                    )
                }
                .padding(28)
                .background(AnteTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 20))

                // Stats
                VStack(spacing: 10) {
                    statRow(icon: "number", label: "Rounds Played", value: "\(game.roundNumber)")
                    statRow(icon: "clock", label: "Game Duration", value: formatDuration(game.elapsedSeconds))
                }
                .padding(20)
                .background(AnteTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                Spacer()

                VStack(spacing: 12) {
                    Button(action: onNewGame) {
                        Label("Play Again", systemImage: "arrow.counterclockwise")
                            .font(.headline)
                            .foregroundColor(AnteTheme.feltGreen)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AnteTheme.gold)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button(action: onMenu) {
                        Label("Main Menu", systemImage: "house.fill")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AnteTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 28)
        }
    }

    private func finalScoreColumn(label: String, score: Int, isWinner: Bool) -> some View {
        VStack(spacing: 6) {
            if isWinner {
                Image(systemName: "crown.fill")
                    .foregroundColor(AnteTheme.gold)
                    .font(.title3)
            }
            Text(label)
                .font(.caption)
                .foregroundColor(AnteTheme.textMuted)
            Text("\(score)")
                .font(.system(size: 48, weight: .black))
                .foregroundColor(isWinner ? AnteTheme.gold : .white.opacity(0.6))
        }
    }

    private func statRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(AnteTheme.gold)
                .frame(width: 24)
            Text(label)
                .font(.subheadline)
                .foregroundColor(AnteTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
