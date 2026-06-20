import SwiftUI
import SwiftData

struct DropGameView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("drop_difficulty") private var storedDifficulty: Int = 2
    @AppStorage("drop_haptics_enabled") private var hapticsEnabled: Bool = true
    @AppStorage("drop_first_player") private var firstPlayer: String = "human"

    @State private var game: DropGame = DropGame(difficulty: 2)
    @State private var isCPUThinking: Bool = false
    @State private var showResultBanner: Bool = false
    @State private var bannerScale: CGFloat = 0.5

    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let notificationFeedback = UINotificationFeedbackGenerator()

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(red: 0.06, green: 0.08, blue: 0.22),
                        Color(red: 0.10, green: 0.14, blue: 0.38)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Status header
                    statusHeader
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 12)

                    // Board
                    DropBoardView(game: game, onColumnTap: handleColumnTap)
                        .padding(.horizontal, 8)
                        .frame(maxWidth: .infinity)
                        .aspectRatio(CGFloat(DropGame.cols) / CGFloat(DropGame.rows), contentMode: .fit)
                        .padding(.bottom, 16)

                    // Bottom controls
                    bottomControls
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }

                // Result banner overlay
                if showResultBanner {
                    resultBanner
                        .scaleEffect(bannerScale)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Section("Difficulty") {
                            ForEach([1, 2, 3], id: \.self) { level in
                                Button {
                                    storedDifficulty = level
                                    game.difficulty = level
                                } label: {
                                    Label(
                                        DropTheme.difficultyName(level),
                                        systemImage: storedDifficulty == level ? "checkmark" : "circle"
                                    )
                                }
                            }
                        }
                    } label: {
                        Label("Difficulty", systemImage: "slider.horizontal.3")
                            .foregroundStyle(DropTheme.accent)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Drop")
                        .font(.title2.bold())
                        .foregroundStyle(DropTheme.accent)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            game = DropGame(difficulty: storedDifficulty)
            impactFeedback.prepare()
            notificationFeedback.prepare()
            if firstPlayer == "cpu" {
                scheduleCPUMove()
            }
        }
        .onChange(of: storedDifficulty) { _, newVal in
            game.difficulty = newVal
        }
    }

    // MARK: - Status Header

    private var statusHeader: some View {
        HStack {
            playerChip(player: .human)
            Spacer()
            turnIndicatorView
            Spacer()
            playerChip(player: .cpu)
        }
    }

    private func playerChip(player: DropPlayer) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(DropTheme.playerColor(player))
                .frame(width: 14, height: 14)
                .shadow(color: DropTheme.playerColor(player).opacity(0.6), radius: 4)
            Text(DropTheme.playerName(player))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.white.opacity(currentTurnPlayer == player ? 0.18 : 0.07))
                .overlay(
                    Capsule()
                        .stroke(
                            currentTurnPlayer == player
                                ? DropTheme.playerColor(player).opacity(0.6)
                                : Color.clear,
                            lineWidth: 1.5
                        )
                )
        )
        .animation(.easeInOut(duration: 0.3), value: game.currentPlayer)
    }

    private var currentTurnPlayer: DropPlayer {
        switch game.phase {
        case .won(let p): return p
        default: return game.currentPlayer
        }
    }

    private var turnIndicatorView: some View {
        VStack(spacing: 2) {
            switch game.phase {
            case .playing:
                if isCPUThinking {
                    HStack(spacing: 4) {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.7)
                        Text("Thinking…")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                } else {
                    Text(game.currentPlayer == .human ? "Your turn" : "CPU's turn")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.8))
                }
            case .won(let p):
                Text(p == .human ? "You win!" : "CPU wins!")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(DropTheme.playerColor(p))
            case .draw:
                Text("It's a draw!")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .frame(minWidth: 90)
        .animation(.easeInOut(duration: 0.25), value: isCPUThinking)
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        HStack(spacing: 16) {
            // Move count
            Label("\(game.moveCount) moves", systemImage: "arrow.down.circle")
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.6))

            Spacer()

            // New game button
            Button {
                startNewGame()
            } label: {
                Label("New Game", systemImage: "arrow.counterclockwise")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule().fill(DropTheme.accent)
                    )
                    .foregroundStyle(Color(red: 0.10, green: 0.14, blue: 0.38))
            }
        }
    }

    // MARK: - Result Banner

    private var resultBanner: some View {
        VStack(spacing: 16) {
            switch game.phase {
            case .won(let p):
                Text(p == .human ? "🎉 You Win!" : "CPU Wins!")
                    .font(.largeTitle.bold())
                    .foregroundStyle(DropTheme.playerColor(p))
            case .draw:
                Text("It's a Draw!")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
            case .playing:
                EmptyView()
            }

            Button {
                withAnimation(.spring(response: 0.4)) {
                    showResultBanner = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    startNewGame()
                }
            } label: {
                Text("Play Again")
                    .font(.headline.weight(.bold))
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(DropTheme.accent))
                    .foregroundStyle(Color(red: 0.10, green: 0.14, blue: 0.38))
            }
        }
        .padding(36)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(.white.opacity(0.15), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
        .padding(40)
    }

    // MARK: - Game Logic

    private func handleColumnTap(_ col: Int) {
        guard case .playing = game.phase else { return }
        guard game.currentPlayer == .human else { return }
        guard game.availableRow(col: col) != nil else { return }

        if hapticsEnabled {
            impactFeedback.impactOccurred()
        }

        game.dropHuman(col: col)
        checkGameEnd()

        if case .playing = game.phase {
            scheduleCPUMove()
        }
    }

    private func scheduleCPUMove() {
        guard case .playing = game.phase else { return }
        isCPUThinking = true

        Task {
            try? await Task.sleep(for: .milliseconds(500))
            await MainActor.run {
                guard case .playing = game.phase else {
                    isCPUThinking = false
                    return
                }
                if hapticsEnabled {
                    impactFeedback.impactOccurred(intensity: 0.7)
                }
                game.dropCPU()
                isCPUThinking = false
                checkGameEnd()
            }
        }
    }

    private func checkGameEnd() {
        switch game.phase {
        case .won(let p):
            saveResult(outcome: p == .human ? "win" : "loss")
            if hapticsEnabled {
                notificationFeedback.notificationOccurred(p == .human ? .success : .error)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    showResultBanner = true
                    bannerScale = 1.0
                }
            }
        case .draw:
            saveResult(outcome: "draw")
            if hapticsEnabled {
                notificationFeedback.notificationOccurred(.warning)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    showResultBanner = true
                    bannerScale = 1.0
                }
            }
        case .playing:
            break
        }
    }

    private func saveResult(outcome: String) {
        let result = DropResult(
            date: .now,
            outcome: outcome,
            difficulty: storedDifficulty,
            moves: game.moveCount
        )
        modelContext.insert(result)
        try? modelContext.save()
    }

    private func startNewGame() {
        withAnimation(.easeInOut(duration: 0.25)) {
            showResultBanner = false
            bannerScale = 0.5
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            game.reset()
            game.difficulty = storedDifficulty
            if firstPlayer == "cpu" {
                game.resetForCPUFirst()
                scheduleCPUMove()
            }
        }
    }
}
