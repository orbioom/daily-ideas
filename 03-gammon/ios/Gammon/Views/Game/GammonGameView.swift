import SwiftUI
import SwiftData

// MARK: - Gammon Game View
// Main game screen. Manages the BackgammonGame observable and drives AI turns.

struct GammonGameView: View {
    let boardScheme: BoardColorScheme
    let aiDifficulty: Int
    let gameMode: GameMode
    let hapticsEnabled: Bool

    @Environment(\.modelContext) private var modelContext

    @State private var game: BackgammonGame
    @State private var showWinBanner = false
    @State private var isAIThinking = false
    @State private var showNewGameConfirm = false
    @State private var lastAnimatedDice: DiceState? = nil
    @State private var diceRollScale: CGFloat = 1.0
    @State private var pipCountVisible = false

    init(boardScheme: BoardColorScheme, aiDifficulty: Int, gameMode: GameMode, hapticsEnabled: Bool) {
        self.boardScheme = boardScheme
        self.aiDifficulty = aiDifficulty
        self.gameMode = gameMode
        self.hapticsEnabled = hapticsEnabled
        _game = State(initialValue: BackgammonGame(mode: gameMode))
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            GammonTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top player info
                playerInfoBar(player: .black, isTop: true)

                // Board
                BackgammonBoardView(
                    game: game,
                    boardScheme: boardScheme,
                    onTapPoint: { idx in handlePointTap(idx) },
                    onTapBar: { handleBarTap() },
                    onTapBearOff: { handleBearOffTap() }
                )
                .aspectRatio(0.75, contentMode: .fit)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)

                // Dice + controls
                controlBar()

                // Bottom player info
                playerInfoBar(player: .white, isTop: false)
            }

            // Win banner overlay
            if showWinBanner {
                winBannerOverlay()
            }

            // AI thinking indicator
            if isAIThinking {
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        ProgressView()
                            .tint(GammonTheme.accent)
                        Text("AI is thinking...")
                            .font(.caption)
                            .foregroundStyle(GammonTheme.textSecondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(GammonTheme.surface)
                    .cornerRadius(20)
                    .padding(.bottom, 100)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    pipCountVisible.toggle()
                } label: {
                    Image(systemName: "number.circle")
                        .foregroundStyle(GammonTheme.accent)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showNewGameConfirm = true
                } label: {
                    Image(systemName: "arrow.counterclockwise.circle")
                        .foregroundStyle(GammonTheme.accent)
                }
            }
        }
        .confirmationDialog("Start a new game?", isPresented: $showNewGameConfirm, titleVisibility: .visible) {
            Button("New Game", role: .destructive) {
                startNewGame()
            }
            Button("Cancel", role: .cancel) { }
        }
        .onChange(of: game.phase) { _, newPhase in
            handlePhaseChange(newPhase)
        }
        .onChange(of: game.dice) { _, newDice in
            if newDice != nil {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    diceRollScale = 1.2
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.spring(response: 0.2)) {
                        diceRollScale = 1.0
                    }
                }
            }
        }
    }

    // MARK: - Player Info Bar

    @ViewBuilder
    private func playerInfoBar(player: PieceColor, isTop: Bool) -> some View {
        let isCurrentPlayer = game.currentPlayer == player
        let isRolling = (isCurrentPlayer && game.phase == BGPhase.rolling)
        let isMoving: Bool
        if case .moving = game.phase { isMoving = isCurrentPlayer } else { isMoving = false }

        HStack(spacing: 12) {
            // Piece indicator
            Circle()
                .fill(player == .white ? GammonTheme.whitePiece : GammonTheme.blackPiece)
                .overlay(Circle().stroke(isCurrentPlayer ? GammonTheme.accent : Color.clear, lineWidth: 2))
                .frame(width: 24, height: 24)
                .shadow(color: isCurrentPlayer ? GammonTheme.accent.opacity(0.6) : .clear, radius: 6)

            // Player name + status
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(playerName(player))
                        .font(.headline)
                        .fontWeight(isCurrentPlayer ? .bold : .regular)
                        .foregroundStyle(isCurrentPlayer ? GammonTheme.textPrimary : GammonTheme.textSecondary)

                    if isCurrentPlayer {
                        if isAIThinking {
                            // nothing — shown in overlay
                        } else if isRolling {
                            Text("• Roll")
                                .font(.caption)
                                .foregroundStyle(GammonTheme.accent)
                        } else if isMoving {
                            Text("• Move")
                                .font(.caption)
                                .foregroundStyle(GammonTheme.legalDot)
                        }
                    }
                }

                if pipCountVisible {
                    Text("Pips: \(game.pipCount(for: player))")
                        .font(.caption2)
                        .foregroundStyle(GammonTheme.textMuted)
                }
            }

            Spacer()

            // Bar / off counts
            if barCount(for: player) > 0 {
                Label("\(barCount(for: player)) on bar", systemImage: "exclamationmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(Color.red)
            }

            Text("Off: \(offCount(for: player))/15")
                .font(.caption)
                .foregroundStyle(GammonTheme.textSecondary)
                .monospacedDigit()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isCurrentPlayer ? GammonTheme.surface : GammonTheme.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isCurrentPlayer ? GammonTheme.accentDark : Color.clear, lineWidth: 1)
                )
        )
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .animation(.easeInOut(duration: 0.3), value: isCurrentPlayer)
    }

    // MARK: - Control Bar

    @ViewBuilder
    private func controlBar() -> some View {
        VStack(spacing: 12) {
            // Dice display
            if let dice = game.dice {
                DiceView(die1: dice.die1, die2: dice.die2, usedDice: dice.movesLeft)
                    .scaleEffect(diceRollScale)
            }

            // Action buttons
            HStack(spacing: 12) {
                // Roll button
                if case .rolling = game.phase {
                    let isHumanTurn = isHumanPlayer(game.currentPlayer)
                    if isHumanTurn {
                        RollDiceButton {
                            rollDice()
                        }
                    }
                }

                // Pass / Forfeit button (when no moves available)
                if case .moving = game.phase {
                    let isHumanTurn = isHumanPlayer(game.currentPlayer)
                    let hasLegalMoves = !game.generateAllLegalMoves(for: game.currentPlayer, diceState: game.dice ?? DiceState(d1: 1, d2: 1)).isEmpty
                    if isHumanTurn && !hasLegalMoves {
                        Button("Pass Turn") {
                            haptic(.medium)
                            game.forfeitTurn()
                        }
                        .gammonButton()
                    }
                }

                // Clear selection button
                if game.selectedFrom != nil {
                    Button("Cancel") {
                        game.clearSelection()
                    }
                    .font(.subheadline)
                    .foregroundStyle(GammonTheme.textSecondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(GammonTheme.surface)
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 100)
        .background(GammonTheme.background)
    }

    // MARK: - Win Banner

    @ViewBuilder
    private func winBannerOverlay() -> some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()

            VStack(spacing: 24) {
                // Trophy icon
                ZStack {
                    Circle()
                        .fill(GammonTheme.accent.opacity(0.2))
                        .frame(width: 100, height: 100)
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(GammonTheme.accent)
                }

                VStack(spacing: 8) {
                    Text(winTitle)
                        .font(GammonTheme.titleFont)
                        .foregroundStyle(GammonTheme.textPrimary)

                    if let winner = game.winner {
                        Text(winSubtitle(winner: winner))
                            .font(.subheadline)
                            .foregroundStyle(GammonTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }

                HStack(spacing: 16) {
                    Button("New Game") {
                        startNewGame()
                    }
                    .gammonButton(large: true)
                }
            }
            .padding(32)
            .background(GammonTheme.surface)
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(GammonTheme.accent.opacity(0.4), lineWidth: 1.5)
            )
            .padding(40)
            .shadow(color: .black.opacity(0.5), radius: 30, y: 10)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }

    // MARK: - Actions

    private func rollDice() {
        haptic(.light)
        game.rollDice()
    }

    private func handlePointTap(_ idx: Int) {
        guard isHumanPlayer(game.currentPlayer) else { return }
        guard case .moving = game.phase else { return }
        haptic(.selection)
        game.tapPoint(idx)
    }

    private func handleBarTap() {
        guard isHumanPlayer(game.currentPlayer) else { return }
        guard case .moving = game.phase else { return }
        haptic(.selection)
        game.tapBar()
    }

    private func handleBearOffTap() {
        guard isHumanPlayer(game.currentPlayer) else { return }
        guard case .moving = game.phase else { return }
        haptic(.medium)
        game.tapBearOff()
    }

    private func handlePhaseChange(_ phase: BGPhase) {
        switch phase {
        case .gameOver(let winner):
            saveResult(winner: winner)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showWinBanner = true
            }
            haptic(.success)

        case .rolling:
            // Check if it's AI's turn
            if case .vsAI = game.mode {
                if game.currentPlayer == .black {
                    scheduleAITurn()
                }
            }

        case .moving:
            // Check if AI needs to move (shouldn't normally reach here if AI auto-moves)
            break
        }
    }

    private func scheduleAITurn() {
        isAIThinking = true
        Task {
            // Roll delay
            try? await Task.sleep(nanoseconds: 800_000_000)  // 0.8s
            await MainActor.run {
                game.rollDice()
            }
            // Move delay
            try? await Task.sleep(nanoseconds: 600_000_000)  // 0.6s
            await MainActor.run {
                game.makeAITurn()
                isAIThinking = false
            }
        }
    }

    private func startNewGame() {
        withAnimation(.easeOut(duration: 0.2)) {
            showWinBanner = false
        }
        isAIThinking = false
        game.newGame(mode: gameMode)
    }

    private func saveResult(winner: PieceColor) {
        let isAIMode: Bool
        if case .vsAI = game.mode { isAIMode = true } else { isAIMode = false }

        let outcome: String
        if case .vsAI = game.mode {
            outcome = winner == .white ? "win" : "loss"
        } else {
            outcome = winner == .white ? "white" : "black"
        }

        let diff: Int
        if case .vsAI(let d) = game.mode { diff = d } else { diff = 0 }

        let result = GammonResult(
            date: .now,
            outcome: outcome,
            difficulty: diff,
            gameMoves: game.moveCount,
            mode: isAIMode ? "ai" : "2player",
            durationSeconds: Int(Date.now.timeIntervalSince(game.gameStartDate))
        )
        modelContext.insert(result)
        try? modelContext.save()
    }

    // MARK: - Helpers

    private func isHumanPlayer(_ player: PieceColor) -> Bool {
        switch game.mode {
        case .twoPlayer: return true
        case .vsAI: return player == .white
        }
    }

    private func playerName(_ player: PieceColor) -> String {
        switch game.mode {
        case .twoPlayer:
            return player == .white ? "Player 1 (White)" : "Player 2 (Black)"
        case .vsAI:
            return player == .white ? "You (White)" : "AI (Black)"
        }
    }

    private func barCount(for player: PieceColor) -> Int {
        player == .white ? game.whiteBar : game.blackBar
    }

    private func offCount(for player: PieceColor) -> Int {
        player == .white ? game.whiteOff : game.blackOff
    }

    private var winTitle: String {
        guard let winner = game.winner else { return "Game Over" }
        switch game.mode {
        case .twoPlayer:
            return "\(winner.displayName) Wins!"
        case .vsAI:
            return winner == .white ? "You Win!" : "AI Wins!"
        }
    }

    private func winSubtitle(winner: PieceColor) -> String {
        var parts: [String] = []
        if game.isBackgammon {
            parts.append("Backgammon! (3x points)")
        } else if game.isGammon {
            parts.append("Gammon! (2x points)")
        }
        parts.append("\(game.moveCount) moves played")
        return parts.joined(separator: " • ")
    }

    private func haptic(_ style: HapticStyle) {
        guard hapticsEnabled else { return }
        switch style {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .selection:
            UISelectionFeedbackGenerator().selectionChanged()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

enum HapticStyle {
    case light, medium, selection, success
}

// BGPhase Equatable conformance is declared in BackgammonGame.swift

#Preview {
    NavigationStack {
        GammonGameView(
            boardScheme: .classic,
            aiDifficulty: 2,
            gameMode: .vsAI(difficulty: 2),
            hapticsEnabled: false
        )
    }
    .modelContainer(for: GammonResult.self, inMemory: true)
    .preferredColorScheme(.dark)
}
