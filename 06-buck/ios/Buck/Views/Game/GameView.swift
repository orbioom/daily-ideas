import SwiftUI

struct GameView: View {
    @Bindable var viewModel: GameViewModel
    let settings: BuckSettings
    @Environment(\.modelContext) private var ctx
    @State private var showHandResult = false
    @State private var showGameOver = false

    var body: some View {
        ZStack {
            BuckTheme.feltGreen.ignoresSafeArea()

            VStack(spacing: 0) {
                ScoreHeaderView(
                    humanScore: viewModel.humanTeamScore,
                    aiScore: viewModel.aiTeamScore,
                    trump: viewModel.trump,
                    statusMessage: viewModel.statusMessage
                )
                .padding(.top, 8)

                Spacer()

                // Table area showing the current trick and other players
                TableAreaView(viewModel: viewModel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Spacer()

                // Human hand at the bottom
                HumanHandView(
                    cards: viewModel.hands[.south] ?? [],
                    legalCards: viewModel.legalHumanCards,
                    isYourTurn: viewModel.isHumanTurn && viewModel.phase == .playing,
                    showValues: settings.showCardValues,
                    onCardTap: { card in
                        if settings.hapticEnabled {
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                        }
                        viewModel.humanPlayCard(card)
                    }
                )
                .frame(height: 110)
                .padding(.bottom, 8)
            }

            // Bidding overlay slides up from the bottom when it's the human's turn to bid
            if viewModel.phase == .bidding && viewModel.currentBidder.isHuman {
                BiddingView(viewModel: viewModel)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35), value: viewModel.phase)
        .sheet(isPresented: $showHandResult) {
            HandResultView(
                result: viewModel.lastHandResult,
                humanScore: viewModel.humanTeamScore,
                aiScore: viewModel.aiTeamScore,
                onNext: {
                    showHandResult = false
                    if viewModel.phase != .gameOver {
                        viewModel.nextHand()
                    } else {
                        showGameOver = true
                    }
                }
            )
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showGameOver) {
            GameOverView(
                humanWon: viewModel.humanTeamScore >= 10,
                humanScore: viewModel.humanTeamScore,
                aiScore: viewModel.aiTeamScore,
                handsPlayed: viewModel.handsPlayed,
                onNewGame: {
                    showGameOver = false
                    viewModel.startNewGame(
                        difficulty: viewModel.difficulty,
                        screwTheDealer: viewModel.screwTheDealer
                    )
                }
            )
            .presentationDetents([.medium])
        }
        .onChange(of: viewModel.phase) { _, newPhase in
            if newPhase == .handOver {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showHandResult = true
                }
            } else if newPhase == .gameOver {
                viewModel.saveGame(context: ctx)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showGameOver = true
                }
            }
        }
    }
}

// MARK: - Score Header

struct ScoreHeaderView: View {
    let humanScore: Int
    let aiScore: Int
    let trump: Suit?
    let statusMessage: String

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("You & Partner")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    Text("\(humanScore)")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }

                Spacer()

                if let trump = trump {
                    VStack(spacing: 2) {
                        Text(trump.rawValue)
                            .font(.system(size: 28))
                        Text("trump")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Opponents")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    Text("\(aiScore)")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 20)

            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.horizontal, 20)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.2))
    }
}

// MARK: - Table Area

struct TableAreaView: View {
    @Bindable var viewModel: GameViewModel

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // North (Partner) position
                VStack(spacing: 4) {
                    Text(PlayerSeat.north.displayName)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    playedCardView(for: .north)
                }
                .position(x: geo.size.width / 2, y: geo.size.height * 0.18)

                // West position
                VStack(spacing: 4) {
                    Text(PlayerSeat.west.displayName)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    playedCardView(for: .west)
                }
                .position(x: geo.size.width * 0.18, y: geo.size.height / 2)

                // East position
                VStack(spacing: 4) {
                    Text(PlayerSeat.east.displayName)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    playedCardView(for: .east)
                }
                .position(x: geo.size.width * 0.82, y: geo.size.height / 2)

                // Center: show the turned-up card during bidding, or trick count during play
                if viewModel.phase == .bidding, let flipped = viewModel.flippedCard {
                    VStack(spacing: 4) {
                        Text("Turned Up")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.6))
                        CardView(card: flipped, size: .medium, faceDown: false)
                    }
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                }

                // South (human) played card
                VStack(spacing: 4) {
                    playedCardView(for: .south)
                    Text(PlayerSeat.south.displayName)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .position(x: geo.size.width / 2, y: geo.size.height * 0.82)

                // Trick count display during active play
                if viewModel.phase == .playing || viewModel.phase == .handOver {
                    VStack(spacing: 2) {
                        Text("Tricks")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.5))
                        Text("You \(viewModel.humanTricksThisHand) — AI \(viewModel.aiTricksThisHand)")
                            .font(.caption.bold())
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                }
            }
        }
    }

    @ViewBuilder
    private func playedCardView(for seat: PlayerSeat) -> some View {
        let played = viewModel.currentTrick.plays.first(where: { $0.player == seat })
        if let play = played {
            CardView(card: play.card, size: .medium, faceDown: false)
        } else {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.white.opacity(0.25), lineWidth: 1.5)
                .frame(width: 52, height: 72)
        }
    }
}

// MARK: - Human Hand

struct HumanHandView: View {
    let cards: [Card]
    let legalCards: Set<String>
    let isYourTurn: Bool
    let showValues: Bool
    let onCardTap: (Card) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: -12) {
                ForEach(cards) { card in
                    let isLegal = legalCards.contains(card.id)
                    CardView(card: card, size: .small, faceDown: false)
                        .opacity(isYourTurn && !isLegal ? 0.45 : 1.0)
                        .scaleEffect(isYourTurn && isLegal ? 1.05 : 1.0)
                        .animation(.spring(response: 0.3), value: isYourTurn)
                        .onTapGesture {
                            if isYourTurn && isLegal {
                                onCardTap(card)
                            }
                        }
                        .zIndex(cards.firstIndex(where: { $0.id == card.id }).map { Double($0) } ?? 0)
                }
            }
            .padding(.horizontal, 20)
        }
    }
}
