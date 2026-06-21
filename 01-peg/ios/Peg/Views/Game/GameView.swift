import SwiftUI
import SwiftData

struct GameView: View {
    @State private var game = CribbageGame()
    @Query private var statsQuery: [PegStats]
    @Query private var settingsQuery: [PegSettings]
    @Environment(\.modelContext) private var ctx

    private var settings: PegSettings {
        settingsQuery.first ?? PegSettings()
    }

    var body: some View {
        ZStack {
            PegTheme.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 12) {
                ScoreBoardView(humanScore: game.humanScore, aiScore: game.aiScore, dealer: game.dealer)
                    .padding(.horizontal)

                messageBar

                starterCardView

                Spacer()

                switch game.phase {
                case .discarding:
                    discardPhaseView
                case .cutting:
                    cutPhaseView
                case .pegging:
                    peggingPhaseView
                case .showHand, .showCrib:
                    showHandView
                case .gameOver:
                    gameOverView
                default:
                    ProgressView()
                        .tint(.white)
                }

                Spacer()
            }
            .padding(.top, 8)
        }
        .onAppear { game.startGame() }
    }

    private var messageBar: some View {
        Text(game.message)
            .font(PegTheme.headlineFont)
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(.black.opacity(0.3))
            .clipShape(Capsule())
            .animation(.easeInOut, value: game.message)
    }

    private var starterCardView: some View {
        HStack {
            Text("Starter:")
                .font(PegTheme.headlineFont)
                .foregroundStyle(.white.opacity(0.8))
            if let s = game.starter {
                CardView(card: s, size: 55)
            } else {
                CardView(card: Card(suit: .clubs, rank: .ace), isFaceDown: true, size: 55)
            }
        }
    }

    private var discardPhaseView: some View {
        VStack(spacing: 16) {
            Text("Your Hand — select 2 to discard to \(game.dealer == .human ? "your" : "AI's") crib")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))

            handRow(cards: game.humanHand, selectable: true)

            Button(action: {
                if settings.hapticFeedback { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
                game.humanDiscard()
            }) {
                Label("Discard to Crib", systemImage: "tray.and.arrow.down.fill")
                    .font(PegTheme.headlineFont)
                    .foregroundStyle(game.canDiscard ? PegTheme.feltGreenDark : .gray)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(game.canDiscard ? PegTheme.goldAccent : Color.gray.opacity(0.3))
                    .clipShape(Capsule())
            }
            .disabled(!game.canDiscard)
        }
    }

    private var cutPhaseView: some View {
        VStack(spacing: 20) {
            Text("Tap to cut the deck and reveal the starter")
                .font(PegTheme.headlineFont)
                .foregroundStyle(.white.opacity(0.8))
            Button(action: {
                if settings.hapticFeedback { UIImpactFeedbackGenerator(style: .rigid).impactOccurred() }
                game.cutDeck()
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(PegTheme.goldAccent)
                        .frame(width: 90, height: 130)
                    Image(systemName: "scissors")
                        .font(.system(size: 32))
                        .foregroundStyle(PegTheme.feltGreenDark)
                }
            }
        }
    }

    private var peggingPhaseView: some View {
        VStack(spacing: 12) {
            Text("Running total: \(game.peggingTotal)")
                .font(.title3.bold())
                .foregroundStyle(PegTheme.goldAccent)

            Text("Played pile:")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: -10) {
                    ForEach(game.peggingPile) { card in
                        CardView(card: card, size: 50)
                    }
                }
                .padding(.horizontal)
            }

            Divider().background(.white.opacity(0.3))

            Text("Your pegging hand:")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))

            handRow(cards: game.humanPeggingHand, selectable: false, pegMode: true)
        }
    }

    private var showHandView: some View {
        VStack(spacing: 16) {
            if let s = game.starter {
                VStack(spacing: 8) {
                    Text("Your Hand + Starter")
                        .font(PegTheme.headlineFont)
                        .foregroundStyle(.white)
                    handRow(cards: game.humanHand + [s], selectable: false)
                }
            }
            if !game.handBreakdown.isEmpty {
                VStack(spacing: 4) {
                    ForEach(game.handBreakdown, id: \.label) { item in
                        HStack {
                            Text(item.label)
                                .foregroundStyle(.white.opacity(0.8))
                            Spacer()
                            Text("+\(item.points)")
                                .foregroundStyle(PegTheme.goldAccent)
                                .font(.headline)
                        }
                        .padding(.horizontal, 30)
                    }
                }
            }
        }
    }

    private var gameOverView: some View {
        VStack(spacing: 20) {
            Image(systemName: game.winner == .human ? "trophy.fill" : "xmark.octagon.fill")
                .font(.system(size: 60))
                .foregroundStyle(game.winner == .human ? PegTheme.goldAccent : .red)
            Text(game.message)
                .font(PegTheme.titleFont)
                .foregroundStyle(.white)
            Text("You: \(game.humanScore) — AI: \(game.aiScore)")
                .foregroundStyle(.white.opacity(0.8))
            Button("Play Again") {
                updateStats(won: game.winner == .human)
                game.startGame()
            }
            .font(PegTheme.headlineFont)
            .foregroundStyle(PegTheme.feltGreenDark)
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
            .background(PegTheme.goldAccent)
            .clipShape(Capsule())
        }
    }

    private func handRow(cards: [Card], selectable: Bool, pegMode: Bool = false) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: -8) {
                ForEach(cards) { card in
                    CardView(card: card,
                             isSelected: selectable && game.selectedCards.contains(card),
                             size: 65)
                    .onTapGesture {
                        if selectable {
                            if settings.hapticFeedback { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
                            game.toggleCardSelection(card)
                        } else if pegMode && game.peggingTurn == .human {
                            if settings.hapticFeedback { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
                            game.humanPeg(card: card)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private func updateStats(won: Bool) {
        let stats = statsQuery.first ?? {
            let s = PegStats(); ctx.insert(s); return s
        }()
        stats.gamesPlayed += 1
        if won {
            stats.gamesWon += 1
            stats.currentStreak += 1
            stats.longestWinStreak = max(stats.longestWinStreak, stats.currentStreak)
        } else {
            stats.currentStreak = 0
        }
        stats.totalPoints += game.humanScore
        stats.highScore = max(stats.highScore, game.humanScore)
        try? ctx.save()
    }
}
