import SwiftUI
import SwiftData
import UIKit

struct GameView: View {
    @State private var game = PebbleGame()
    @Query private var statsQuery: [PebbleStats]
    @Query private var settingsQuery: [PebbleSettings]
    @Environment(\.modelContext) private var ctx

    private var settings: PebbleSettings { settingsQuery.first ?? PebbleSettings() }

    var body: some View {
        ZStack {
            PebbleTheme.backgroundGradient.ignoresSafeArea()
            VStack(spacing: 16) {
                scoreHeader
                messageBar
                BoardView(
                    game: game,
                    validMoves: game.isHumanTurn
                        ? game.board.validMoves(for: game.humanPlayer)
                        : [],
                    onTap: { pit in
                        if settings.hapticFeedback {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                        game.humanTap(pit: pit)
                    }
                )
                .padding(.horizontal)

                if game.board.isGameOver {
                    gameOverButtons
                }
                Spacer()
            }
            .padding(.top, 8)
        }
        .onAppear {
            game.difficulty = settings.difficulty
            game.newGame(stonesPerPit: settings.stonesPerPit)
        }
    }

    // MARK: - Sub-views

    private var scoreHeader: some View {
        HStack {
            VStack {
                Text("AI")
                    .font(PebbleTheme.headlineFont)
                    .foregroundStyle(.white.opacity(0.7))
                Text("\(game.board.playerTwoScore)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(PebbleTheme.stoneOrange)
            }
            Spacer()
            Image(systemName: "circle.grid.3x3.fill")
                .font(.title)
                .foregroundStyle(PebbleTheme.sandGold)
            Spacer()
            VStack {
                Text("You")
                    .font(PebbleTheme.headlineFont)
                    .foregroundStyle(.white.opacity(0.7))
                Text("\(game.board.playerOneScore)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(PebbleTheme.stoneTeal)
            }
        }
        .padding(.horizontal, 32)
    }

    private var messageBar: some View {
        Text(game.message)
            .font(PebbleTheme.headlineFont)
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(.black.opacity(0.35))
            .clipShape(Capsule())
            .animation(.easeInOut, value: game.message)
    }

    private var gameOverButtons: some View {
        Button("New Game") {
            if settings.hapticFeedback {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
            updateStats()
            game.difficulty = settings.difficulty
            game.newGame(stonesPerPit: settings.stonesPerPit)
        }
        .font(PebbleTheme.headlineFont)
        .foregroundStyle(PebbleTheme.woodBrown)
        .padding(.horizontal, 32)
        .padding(.vertical, 12)
        .background(PebbleTheme.sandGold)
        .clipShape(Capsule())
    }

    // MARK: - Helpers

    private func updateStats() {
        let stats: PebbleStats
        if let existing = statsQuery.first {
            stats = existing
        } else {
            let s = PebbleStats()
            ctx.insert(s)
            stats = s
        }

        stats.gamesPlayed += 1
        if let w = game.board.winner {
            if w == game.humanPlayer {
                stats.gamesWon += 1
                stats.currentStreak += 1
                stats.longestWinStreak = max(stats.longestWinStreak, stats.currentStreak)
            } else {
                stats.currentStreak = 0
            }
        } else {
            stats.gamesDrawn += 1
            stats.currentStreak = 0
        }
        stats.highScore = max(stats.highScore, game.board.playerOneScore)
        try? ctx.save()
    }
}
