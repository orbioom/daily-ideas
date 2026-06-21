import SwiftUI

struct HandResultView: View {
    let result: HandResult?
    let humanScore: Int
    let aiScore: Int
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.system(size: 48))
                    .foregroundStyle(iconColor)
                    .padding(.top, 24)

                Text(titleText)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)

                Text(result?.resultDescription ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Divider()

            HStack(spacing: 40) {
                VStack(spacing: 4) {
                    Text("Tricks")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(result?.tricksHuman ?? 0)")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                    Text("You & Partner")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Divider().frame(height: 60)

                VStack(spacing: 4) {
                    Text("Tricks")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(result?.tricksAI ?? 0)")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                    Text("Opponents")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 40) {
                VStack(spacing: 2) {
                    Text("Game Score")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(humanScore) — \(aiScore)")
                        .font(.title2.bold())
                }
            }

            Button(action: onNext) {
                Text("Next Hand")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(BuckTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 24)
    }

    private var iconName: String {
        guard let result else { return "questionmark.circle" }
        if result.makerTeamIsHuman {
            if result.tricksHuman >= 3 { return result.wentAlone ? "star.fill" : "checkmark.circle.fill" }
            return "xmark.circle.fill"
        } else {
            if result.tricksAI < 3 { return "hand.thumbsup.fill" }
            return "arrow.down.circle.fill"
        }
    }

    private var iconColor: Color {
        guard let result else { return .gray }
        if result.makerTeamIsHuman {
            if result.tricksHuman >= 3 { return .green }
            return .red
        } else {
            if result.tricksAI < 3 { return .green }
            return .orange
        }
    }

    private var titleText: String {
        guard let result else { return "Hand Over" }
        if result.makerTeamIsHuman {
            if result.tricksHuman >= 5 { return result.wentAlone ? "Lone Hand!" : "March!" }
            if result.tricksHuman >= 3 { return "Made It!" }
            return "Euchred!"
        } else {
            if result.tricksAI < 3 { return "Euchred Them!" }
            if result.tricksAI >= 5 { return "Opponents Marched" }
            return "Opponents Made It"
        }
    }
}

// MARK: - Game Over

struct GameOverView: View {
    let humanWon: Bool
    let humanScore: Int
    let aiScore: Int
    let handsPlayed: Int
    let onNewGame: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Image(systemName: humanWon ? "trophy.fill" : "flag.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(humanWon ? BuckTheme.goldAccent : .gray)
                    .padding(.top, 24)

                Text(humanWon ? "You Win!" : "Opponents Win")
                    .font(.system(size: 32, weight: .black, design: .rounded))

                Text(humanWon
                     ? "Congratulations! Your team won the game."
                     : "Better luck next time!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 40) {
                VStack(spacing: 4) {
                    Text("\(humanScore)")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundStyle(humanWon ? BuckTheme.accent : .secondary)
                    Text("You & Partner")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text("—")
                    .font(.title)
                    .foregroundStyle(.secondary)
                VStack(spacing: 4) {
                    Text("\(aiScore)")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundStyle(!humanWon ? .orange : .secondary)
                    Text("Opponents")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text("\(handsPlayed) hands played")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button(action: onNewGame) {
                Text("New Game")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(BuckTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 24)
    }
}
