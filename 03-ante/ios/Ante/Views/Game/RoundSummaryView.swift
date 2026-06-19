import SwiftUI

struct RoundSummaryView: View {
    let game: GinRummyGame
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            AnteTheme.feltGreenDark
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Result badge
                    resultBadge

                    // Scores
                    HStack(spacing: 40) {
                        scoreColumn(label: "You", score: game.playerScore)
                        scoreColumn(label: game.gameMode == "passAndPlay" ? "Player 2" : "CPU", score: game.opponentScore)
                    }
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(AnteTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Round details
                    if let result = game.lastRoundResult {
                        VStack(spacing: 8) {
                            Text("Round Details")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(AnteTheme.textMuted)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            detailRow(label: "Knocker", value: result.knocker)
                            if result.isGin {
                                detailRow(label: "Result", value: "GIN! (+25 bonus)")
                            } else if result.isUndercut {
                                detailRow(label: "Result", value: "UNDERCUT! (+25 bonus)")
                            } else {
                                detailRow(label: "Result", value: "Knock")
                            }
                            detailRow(label: "\(result.knocker) deadwood", value: "\(result.knockerDeadwood) pts")
                            detailRow(label: "Defender deadwood", value: "\(result.defenderDeadwood) pts")
                            detailRow(label: "Points scored", value: "\(result.pointsScored) → \(result.scorer)")
                        }
                        .padding(16)
                        .background(AnteTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    if !game.deadHandMessage.isEmpty {
                        Text(game.deadHandMessage)
                            .font(.callout)
                            .foregroundColor(AnteTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(16)
                            .background(AnteTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Both hands revealed
                    handRevealSection

                    Button(action: onContinue) {
                        Text(game.playerScore >= game.winningScore || game.opponentScore >= game.winningScore
                             ? "See Final Results"
                             : "Next Round →")
                            .font(.headline)
                            .foregroundColor(AnteTheme.feltGreen)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AnteTheme.gold)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(20)
            }
        }
    }

    private var resultBadge: some View {
        VStack(spacing: 8) {
            if let result = game.lastRoundResult {
                if result.isGin {
                    Text("GIN!")
                        .font(.system(size: 40, weight: .black, design: .serif))
                        .foregroundColor(AnteTheme.gold)
                        .shadow(color: AnteTheme.gold.opacity(0.5), radius: 10)
                } else if result.isUndercut {
                    Text("UNDERCUT!")
                        .font(.system(size: 32, weight: .black, design: .serif))
                        .foregroundColor(.orange)
                } else {
                    Text("KNOCK")
                        .font(.system(size: 36, weight: .black, design: .serif))
                        .foregroundColor(.white)
                }
                Text("\(result.scorer) scores \(result.pointsScored) points")
                    .font(.subheadline)
                    .foregroundColor(AnteTheme.textSecondary)
            } else {
                Text("Round Over")
                    .font(.title.weight(.bold))
                    .foregroundColor(.white)
            }
            Text("Round \(game.roundNumber)  •  First to \(game.winningScore)")
                .font(.caption)
                .foregroundColor(AnteTheme.textMuted)
        }
        .padding(.top, 20)
    }

    private func scoreColumn(label: String, score: Int) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(AnteTheme.textMuted)
            Text("\(score)")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)
            Text("/ \(game.winningScore)")
                .font(.caption2)
                .foregroundColor(AnteTheme.textMuted)
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(AnteTheme.textMuted)
            Spacer()
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundColor(.white)
        }
    }

    private var handRevealSection: some View {
        VStack(spacing: 16) {
            Text("Hands Revealed")
                .font(.caption.weight(.semibold))
                .foregroundColor(AnteTheme.textMuted)
                .frame(maxWidth: .infinity, alignment: .leading)

            handSection(
                title: "Your Hand",
                hand: game.playerHand,
                melds: game.playerMelds,
                deadwood: game.playerDeadwood
            )
            handSection(
                title: game.gameMode == "passAndPlay" ? "Player 2" : "CPU",
                hand: game.opponentHand,
                melds: game.opponentMelds,
                deadwood: game.opponentDeadwood
            )
        }
    }

    private func handSection(title: String, hand: [PlayingCard], melds: [Meld], deadwood: [PlayingCard]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                Spacer()
                let dv = MeldDetector.deadwoodValue(deadwood)
                Text("DW: \(dv)")
                    .font(.caption.weight(.bold))
                    .foregroundColor(dv == 0 ? AnteTheme.gold : (dv <= 10 ? .green : .orange))
            }

            if !melds.isEmpty {
                Text("Melds")
                    .font(.caption2)
                    .foregroundColor(AnteTheme.gold)
                ForEach(melds) { meld in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(meld.cards) { card in
                                CardView(card: card, faceUp: true, isHighlighted: true, width: 44, height: 62)
                            }
                            Text(meld.type == .set ? "Set" : "Run")
                                .font(.caption2)
                                .foregroundColor(AnteTheme.textMuted)
                                .padding(.leading, 4)
                        }
                    }
                }
            }

            if !deadwood.isEmpty {
                Text("Deadwood")
                    .font(.caption2)
                    .foregroundColor(.orange)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(deadwood) { card in
                            CardView(card: card, faceUp: true, width: 44, height: 62)
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(AnteTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
