import SwiftUI

struct GameView: View {
    @Bindable var game: GinRummyGame
    let prefs: AppPreferences
    let onQuit: () -> Void

    @State private var showHand = false

    private var cardBack: Color {
        AnteTheme.cardBackColor(for: prefs.cardBackColor)
    }

    var body: some View {
        ZStack {
            AnteTheme.feltGreen
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                topBar

                // Opponent hand
                opponentSection
                    .padding(.top, 8)

                Spacer(minLength: 8)

                // Middle: Stock + Discard + Knock
                middleSection
                    .padding(.vertical, 12)

                Spacer(minLength: 8)

                // Drawn card area
                if let drawn = game.drawnCard {
                    drawnCardSection(card: drawn)
                        .padding(.bottom, 8)
                }

                // Player hand
                playerHandSection
                    .padding(.bottom, 8)

                // Status bar
                statusBar
                    .padding(.bottom, 12)
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button(action: onQuit) {
                Image(systemName: "xmark")
                    .foregroundColor(AnteTheme.textSecondary)
                    .padding(10)
                    .background(AnteTheme.surface)
                    .clipShape(Circle())
            }

            Spacer()

            VStack(spacing: 2) {
                Text("Round \(game.roundNumber)")
                    .font(.headline)
                    .foregroundColor(.white)
                if prefs.showCardCount {
                    Text("\(game.deck.count) cards left")
                        .font(.caption2)
                        .foregroundColor(AnteTheme.textMuted)
                }
            }

            Spacer()

            ScoreRingView(
                playerScore: game.playerScore,
                opponentScore: game.opponentScore,
                winningScore: game.winningScore
            )
            .scaleEffect(0.7)
            .frame(width: 140)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var opponentSection: some View {
        VStack(spacing: 6) {
            Label(
                game.gameMode == "passAndPlay" ? "Player 2" : "Opponent",
                systemImage: game.gameMode == "passAndPlay" ? "person.2.fill" : "cpu"
            )
            .font(.caption.weight(.medium))
            .foregroundColor(AnteTheme.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: -12) {
                    ForEach(game.opponentHand) { card in
                        SmallCardView(card: card, faceUp: false, cardBackColor: cardBack)
                            .rotationEffect(.degrees(Double.random(in: -3...3)))
                    }
                }
                .padding(.horizontal, 24)
            }

            Text("\(game.opponentHand.count) cards")
                .font(.caption2)
                .foregroundColor(AnteTheme.textMuted)
        }
        .padding(.vertical, 8)
        .background(AnteTheme.feltGreenLight.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
    }

    private var middleSection: some View {
        HStack(spacing: 24) {
            // Stock pile
            VStack(spacing: 6) {
                Button {
                    game.playerDraw(from: .stock)
                } label: {
                    ZStack {
                        ForEach(0..<3, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 8)
                                .fill(cardBack)
                                .frame(width: 64, height: 90)
                                .offset(x: CGFloat(i) * 1.5, y: CGFloat(i) * -1.5)
                                .shadow(radius: 2)
                        }
                        Image(systemName: "suit.club.fill")
                            .foregroundColor(.white.opacity(0.3))
                            .font(.title2)
                    }
                }
                .disabled(game.phase != .playerTurn || game.drawnCard != nil)
                .opacity(game.phase == .playerTurn && game.drawnCard == nil ? 1 : 0.5)

                Text("Stock")
                    .font(.caption2)
                    .foregroundColor(AnteTheme.textMuted)
                Text("\(game.deck.count)")
                    .font(.caption.weight(.bold))
                    .foregroundColor(AnteTheme.textSecondary)
            }

            // VS label
            Text("or")
                .font(.caption)
                .foregroundColor(AnteTheme.textMuted)

            // Discard pile
            VStack(spacing: 6) {
                if let top = game.discardTop {
                    Button {
                        game.playerDraw(from: .discard)
                    } label: {
                        CardView(card: top, faceUp: true, width: 64, height: 90)
                    }
                    .disabled(game.phase != .playerTurn || game.drawnCard != nil)
                    .opacity(game.phase == .playerTurn && game.drawnCard == nil ? 1 : 0.5)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AnteTheme.gold.opacity(0.3), lineWidth: 2, antialiased: true)
                        .frame(width: 64, height: 90)
                        .overlay(Text("Empty").font(.caption2).foregroundColor(AnteTheme.textMuted))
                }
                Text("Discard")
                    .font(.caption2)
                    .foregroundColor(AnteTheme.textMuted)
            }

            // Knock button
            if game.canKnock && game.phase == .playerTurn && game.drawnCard == nil {
                VStack(spacing: 6) {
                    Button(action: game.playerKnock) {
                        VStack(spacing: 4) {
                            Image(systemName: "hand.tap.fill")
                                .font(.title2)
                            Text("KNOCK")
                                .font(.caption.weight(.black))
                                .kerning(1)
                        }
                        .foregroundColor(AnteTheme.feltGreen)
                        .frame(width: 72, height: 72)
                        .background(AnteTheme.gold)
                        .clipShape(Circle())
                        .shadow(color: AnteTheme.gold.opacity(0.5), radius: 8)
                    }
                    Text("Deadwood: \(game.playerHandDeadwoodValue())")
                        .font(.caption2)
                        .foregroundColor(AnteTheme.gold)
                }
            } else if game.phase == .playerTurn && game.drawnCard == nil {
                VStack(spacing: 4) {
                    Image(systemName: "hand.point.up.left")
                        .font(.title2)
                        .foregroundColor(AnteTheme.textMuted)
                    Text("DW: \(game.playerHandDeadwoodValue())")
                        .font(.caption2)
                        .foregroundColor(AnteTheme.textMuted)
                    Text("Need ≤10 to knock")
                        .font(.caption2)
                        .foregroundColor(AnteTheme.textMuted)
                        .multilineTextAlignment(.center)
                        .frame(width: 72)
                }
            }
        }
    }

    private func drawnCardSection(card: PlayingCard) -> some View {
        VStack(spacing: 6) {
            Text("Drawn — tap to discard or keep")
                .font(.caption)
                .foregroundColor(AnteTheme.gold)

            HStack(spacing: 16) {
                CardView(card: card, faceUp: true, isHighlighted: true, width: 60, height: 84)
                    .onTapGesture {
                        game.playerDiscard(card)
                    }
                    .overlay(
                        VStack {
                            Spacer()
                            Text("Discard")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red.opacity(0.8))
                                .clipShape(Capsule())
                                .padding(.bottom, 4)
                        }
                    )

                Image(systemName: "arrow.right")
                    .foregroundColor(AnteTheme.textMuted)

                Text("or tap a hand card to swap")
                    .font(.caption)
                    .foregroundColor(AnteTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(width: 120)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(AnteTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AnteTheme.gold.opacity(0.4), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }

    private var playerHandSection: some View {
        VStack(spacing: 8) {
            HStack {
                Label(
                    game.gameMode == "passAndPlay"
                        ? (game.currentPlayer == 0 ? "Player 1" : "Player 2")
                        : "Your Hand",
                    systemImage: "person.fill"
                )
                .font(.caption.weight(.medium))
                .foregroundColor(AnteTheme.gold)
                Spacer()
                Text("Deadwood: \(game.playerHandDeadwoodValue())")
                    .font(.caption2)
                    .foregroundColor(AnteTheme.textMuted)
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(game.playerHand.sorted { $0.sortKey < $1.sortKey }) { card in
                        let inDeadwood = computeDeadwood().contains(where: { $0.id == card.id })
                        CardView(
                            card: card,
                            faceUp: true,
                            isSelected: game.selectedCard?.id == card.id,
                            isHighlighted: !inDeadwood,
                            width: 56,
                            height: 78
                        )
                        .onTapGesture {
                            handleCardTap(card)
                        }
                        .overlay(alignment: .topTrailing) {
                            if !inDeadwood {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                    .padding(2)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }
        }
    }

    private func computeDeadwood() -> [PlayingCard] {
        let (_, dw) = MeldDetector.findBestMelds(game.playerHand)
        return dw
    }

    private func handleCardTap(_ card: PlayingCard) {
        guard game.phase == .playerTurn else { return }
        if game.drawnCard != nil {
            game.playerDiscard(card)
        } else {
            game.selectedCard = game.selectedCard?.id == card.id ? nil : card
        }
    }

    private var statusBar: some View {
        HStack {
            Image(systemName: game.phase == .opponentTurn ? "ellipsis.circle" : "info.circle")
                .foregroundColor(AnteTheme.textMuted)
            Text(game.phase == .opponentTurn ? "Thinking..." : game.message)
                .font(.caption)
                .foregroundColor(AnteTheme.textSecondary)
                .lineLimit(1)
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}
