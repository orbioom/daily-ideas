import SwiftUI
import SwiftData
import UIKit

struct GameView: View {
    @State private var game = DraughtsGame()
    @State private var showRules = false
    @State private var showNewGameAlert = false
    @State private var showResultSheet = false

    @Environment(\.modelContext) private var modelContext
    @Query private var statsList: [DraughtsStats]
    @Query private var settingsList: [DraughtsSettings]

    private var stats: DraughtsStats? { statsList.first }
    private var settings: DraughtsSettings? { settingsList.first }

    var body: some View {
        NavigationStack {
            ZStack {
                DraughtsTheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Top status bar
                    statusBar
                        .padding(.horizontal)
                        .padding(.top, 8)

                    Spacer(minLength: 12)

                    // Board
                    BoardView(game: game) { row, col in
                        handleTap(row: row, col: col)
                    }
                    .padding(.horizontal, 8)

                    Spacer(minLength: 12)

                    // Bottom action bar
                    bottomBar
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
            }
            .navigationTitle("Draughts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(DraughtsTheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showRules = true
                    } label: {
                        Image(systemName: "book.pages")
                            .foregroundStyle(DraughtsTheme.gold)
                    }
                    .accessibilityLabel("Rules")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showNewGameAlert = true
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundStyle(DraughtsTheme.gold)
                    }
                    .accessibilityLabel("New game")
                }
            }
            .sheet(isPresented: $showRules) {
                RulesView()
            }
            .sheet(isPresented: $showResultSheet) {
                gameResultSheet
            }
            .alert("New Game?", isPresented: $showNewGameAlert) {
                Button("Cancel", role: .cancel) {}
                Button("New Game", role: .destructive) {
                    startNewGame()
                }
            } message: {
                Text("Start a fresh game? Your current progress will be lost.")
            }
            .onChange(of: game.gameStatus) { _, newStatus in
                if newStatus != .playing {
                    recordResult(status: newStatus)
                    showResultSheet = true
                }
            }
            .onAppear {
                applySettings()
            }
        }
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack {
            playerIndicator(player: .red)
            Spacer()
            turnLabel
            Spacer()
            playerIndicator(player: .black)
        }
    }

    private func playerIndicator(player: Player) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(player == .red ? DraughtsTheme.redPiece : DraughtsTheme.blackPiece)
                .frame(width: 18, height: 18)
                .overlay(
                    Circle()
                        .strokeBorder(
                            game.board.currentPlayer == player && game.gameStatus == .playing
                                ? DraughtsTheme.gold : Color.clear,
                            lineWidth: 2
                        )
                )

            VStack(alignment: .leading, spacing: 1) {
                Text(player == .red ? "Red" : "Black")
                    .font(.caption.bold())
                    .foregroundStyle(DraughtsTheme.text)
                Text("\(game.board.pieceCount(for: player)) pieces")
                    .font(.caption2)
                    .foregroundStyle(DraughtsTheme.text.opacity(0.60))
            }

            if player == game.humanPlayer {
                Text("You")
                    .font(.caption2.bold())
                    .foregroundStyle(DraughtsTheme.gold)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(DraughtsTheme.gold.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
    }

    @ViewBuilder
    private var turnLabel: some View {
        if game.isAIThinking {
            HStack(spacing: 6) {
                ProgressView()
                    .tint(DraughtsTheme.gold)
                    .scaleEffect(0.75)
                Text("Thinking…")
                    .font(.caption)
                    .foregroundStyle(DraughtsTheme.text.opacity(0.70))
            }
        } else if game.gameStatus == .playing {
            VStack(spacing: 2) {
                Text(game.isHumanTurn ? "Your Turn" : "AI's Turn")
                    .font(.subheadline.bold())
                    .foregroundStyle(DraughtsTheme.text)
                if game.board.hasMandatoryJump && game.isHumanTurn {
                    Text("Jump required!")
                        .font(.caption2.bold())
                        .foregroundStyle(DraughtsTheme.redPiece)
                }
            }
        } else {
            Text(statusText)
                .font(.subheadline.bold())
                .foregroundStyle(DraughtsTheme.gold)
        }
    }

    private var statusText: String {
        switch game.gameStatus {
        case .playing: return ""
        case .humanWon: return "You won!"
        case .aiWon: return "AI wins"
        case .draw: return "Draw"
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack(spacing: 16) {
            // Difficulty chip
            Label(game.difficulty.displayName, systemImage: "brain")
                .font(.caption.bold())
                .foregroundStyle(DraughtsTheme.text.opacity(0.70))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(DraughtsTheme.cardBackground)
                .clipShape(Capsule())

            Spacer()

            // Move counter
            Label("Move \(game.moveCount)", systemImage: "arrow.right")
                .font(.caption)
                .foregroundStyle(DraughtsTheme.text.opacity(0.60))
        }
    }

    // MARK: - Result Sheet

    private var gameResultSheet: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: game.gameStatus == .humanWon ? "trophy.fill" : game.gameStatus == .aiWon ? "xmark.circle.fill" : "equal.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .foregroundStyle(game.gameStatus == .humanWon ? DraughtsTheme.gold : DraughtsTheme.text.opacity(0.60))

            VStack(spacing: 8) {
                Text(resultTitle)
                    .font(.title.bold())
                    .foregroundStyle(DraughtsTheme.text)

                Text(resultSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(DraughtsTheme.text.opacity(0.70))
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button {
                showResultSheet = false
                startNewGame()
            } label: {
                Label("Play Again", systemImage: "arrow.counterclockwise")
                    .font(.headline)
                    .foregroundStyle(DraughtsTheme.background)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(DraughtsTheme.gold)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal)

            Button("Dismiss") { showResultSheet = false }
                .foregroundStyle(DraughtsTheme.text.opacity(0.50))
                .padding(.bottom, 16)
        }
        .presentationDetents([.medium])
        .presentationBackground(DraughtsTheme.background)
        .presentationCornerRadius(24)
    }

    private var resultTitle: String {
        switch game.gameStatus {
        case .humanWon: return "You Won!"
        case .aiWon:    return "AI Wins"
        case .draw:     return "Draw!"
        case .playing:  return ""
        }
    }

    private var resultSubtitle: String {
        switch game.gameStatus {
        case .humanWon: return "Excellent play! You defeated the AI in \(game.moveCount) moves."
        case .aiWon:    return "Better luck next time. Try a lower difficulty or review the rules."
        case .draw:     return "No moves available for either player."
        case .playing:  return ""
        }
    }

    // MARK: - Helpers

    private func handleTap(row: Int, col: Int) {
        let feedbackEnabled = settings?.hapticsEnabled ?? true
        game.tap(row: row, col: col)
        if feedbackEnabled {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }

    private func startNewGame() {
        let diff = settings?.difficultyEnum ?? .medium
        let playsRed = settings?.humanPlaysRed ?? true
        game.newGame(humanPlayer: playsRed ? .red : .black, difficulty: diff)
    }

    private func applySettings() {
        let diff = settings?.difficultyEnum ?? .medium
        let playsRed = settings?.humanPlaysRed ?? true
        game.difficulty = diff
        game.humanPlayer = playsRed ? .red : .black
    }

    private func recordResult(status: GameStatus) {
        ensureStats()
        guard let s = stats else { return }
        let humanWon = status == .humanWon
        s.recordGame(humanWon: humanWon, moves: game.moveCount)
        try? modelContext.save()
    }

    private func ensureStats() {
        if statsList.isEmpty {
            let s = DraughtsStats()
            modelContext.insert(s)
        }
    }
}

#Preview {
    GameView()
        .modelContainer(for: [DraughtsStats.self, DraughtsSettings.self, DraughtsOnboarding.self], inMemory: true)
}
