import SwiftUI
import SwiftData

struct GameContainerView: View {
    let gameMode: String
    @Query private var preferences: [AppPreferences]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var game = GinRummyGame()
    @State private var showingRoundSummary = false
    @State private var showingQuitConfirm = false
    @State private var savedRecord: GameRecord? = nil

    private var prefs: AppPreferences {
        preferences.first ?? AppPreferences()
    }

    var body: some View {
        ZStack {
            if game.phase == .gameOver {
                GameOverView(game: game, onNewGame: {
                    saveGameRecord()
                    game.startNewGame(mode: gameMode, winScore: prefs.winningScore)
                }, onMenu: {
                    saveGameRecord()
                    dismiss()
                })
            } else {
                GameView(game: game, prefs: prefs, onQuit: {
                    showingQuitConfirm = true
                })
                .sheet(isPresented: $showingRoundSummary) {
                    RoundSummaryView(game: game, onContinue: {
                        showingRoundSummary = false
                        game.nextRound()
                    })
                }
            }
        }
        .onAppear {
            let record = GameRecord(opponentName: gameMode == "singlePlayer" ? "CPU" : "Player 2", mode: gameMode)
            modelContext.insert(record)
            savedRecord = record
            game.startNewGame(mode: gameMode, winScore: prefs.winningScore)
        }
        .onChange(of: game.phase) { _, newPhase in
            if newPhase == .roundEnd {
                showingRoundSummary = true
            }
        }
        .confirmationDialog("Quit Game?", isPresented: $showingQuitConfirm, titleVisibility: .visible) {
            Button("Quit", role: .destructive) {
                saveGameRecord()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your progress in this game will be lost.")
        }
    }

    private func saveGameRecord() {
        guard let record = savedRecord else { return }
        record.playerScore = game.playerScore
        record.opponentScore = game.opponentScore
        record.roundsPlayed = game.roundNumber
        record.playerWon = game.humanPlayerWon
        record.gameDurationSeconds = game.elapsedSeconds
    }
}
