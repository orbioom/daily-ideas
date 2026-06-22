import SwiftUI
import SwiftData

struct GameView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsQuery: [DominoSettings]
    @Bindable var engine: DominoEngine
    @State private var selectedTile: DominoTile? = nil
    @State private var showEndChoice: Bool = false
    @State private var pendingTile: DominoTile? = nil
    @State private var showNewMatchAlert = false
    @State private var guidanceMessage: String? = nil

    private var settings: DominoSettings? { settingsQuery.first }
    private var tileStyle: DominoTheme.TileStyle {
        DominoTheme.TileStyle(rawValue: settings?.tileStyle ?? "classic") ?? .classic
    }

    private var validMoves: [(tile: DominoTile, end: DominoEngine.ChainEnd)] {
        engine.isPlayerTurn ? engine.validMoves(hand: engine.playerHand) : []
    }

    private var canDraw: Bool {
        engine.isPlayerTurn && !engine.boneyard.isEmpty && !engine.hasValidMove(hand: engine.playerHand)
    }

    private var canPass: Bool {
        engine.isPlayerTurn &&
        engine.boneyard.isEmpty &&
        !engine.hasValidMove(hand: engine.playerHand)
    }

    var body: some View {
        ZStack {
            DominoTheme.mahogany.ignoresSafeArea()

            switch engine.phase {
            case .matchOver:
                MatchOverView(
                    engine: engine,
                    onNewMatch: {
                        engine.newMatch(
                            difficulty: engine.difficulty,
                            matchPointTarget: settings?.matchPointTarget ?? 100
                        )
                    },
                    onChangeSettings: {
                        showNewMatchAlert = true
                    }
                )
            case .setup:
                setupView
            default:
                gameplayView
            }

            // Round result overlay
            if engine.phase == .roundOver, let result = engine.roundResult {
                RoundResultView(
                    result: result,
                    playerScore: engine.playerScore,
                    aiScore: engine.aiScore,
                    matchPointTarget: engine.matchPointTarget,
                    onContinue: {
                        engine.newRound()
                        selectedTile = nil
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .zIndex(10)
            }

            // End choice picker
            if showEndChoice, let tile = pendingTile {
                EndChoiceOverlay(
                    tile: tile,
                    leftEnd: engine.leftEnd,
                    rightEnd: engine.rightEnd,
                    validMoves: validMoves,
                    onChoice: { chosenEnd in
                        withAnimation {
                            showEndChoice = false
                            pendingTile = nil
                        }
                        let success = engine.playerPlay(tile: tile, onEnd: chosenEnd)
                        if success {
                            selectedTile = nil
                            triggerHaptic(.light)
                        }
                    },
                    onCancel: {
                        withAnimation { showEndChoice = false }
                        pendingTile = nil
                    }
                )
                .zIndex(5)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: engine.phase)
        .onAppear {
            if engine.phase == .setup {
                startNewMatch()
            }
        }
        .alert("New Match", isPresented: $showNewMatchAlert) {
            Button("Easy") { engine.newMatch(difficulty: .easy, matchPointTarget: settings?.matchPointTarget ?? 100) }
            Button("Medium") { engine.newMatch(difficulty: .medium, matchPointTarget: settings?.matchPointTarget ?? 100) }
            Button("Hard") { engine.newMatch(difficulty: .hard, matchPointTarget: settings?.matchPointTarget ?? 100) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose difficulty for new match")
        }
    }

    // MARK: - Gameplay Layout

    private var gameplayView: some View {
        VStack(spacing: 10) {
            // Top: Score header
            ScoreHeader(
                playerScore: engine.playerScore,
                aiScore: engine.aiScore,
                matchPointTarget: engine.matchPointTarget
            )
            .padding(.horizontal, 12)
            .padding(.top, 8)

            // AI hand
            AIHandView(
                count: engine.aiHand.count,
                pipTotal: engine.aiHand.reduce(0) { $0 + $1.totalPips },
                showAIHand: engine.showAIHand,
                hand: engine.aiHand,
                tileStyle: tileStyle
            )
            .padding(.horizontal, 12)

            // Turn indicator
            TurnIndicator(
                isPlayerTurn: engine.isPlayerTurn,
                isAIThinking: engine.isAIThinking,
                boneyardCount: engine.boneyard.count
            )
            .padding(.horizontal, 12)

            // Open ends display
            if !engine.chain.isEmpty {
                HStack {
                    OpenEndBadge(pipValue: engine.leftEnd, side: "L")
                    Spacer()
                    Text("Open Ends")
                        .font(DominoTheme.captionFont)
                        .foregroundStyle(DominoTheme.ivory.opacity(0.5))
                    Spacer()
                    OpenEndBadge(pipValue: engine.rightEnd, side: "R")
                }
                .padding(.horizontal, 16)
            }

            // Board
            BoardView(
                chain: engine.chain,
                leftEnd: engine.leftEnd,
                rightEnd: engine.rightEnd,
                tileStyle: tileStyle
            )
            .frame(height: 130)
            .padding(.horizontal, 12)

            // Guidance message
            if let msg = guidanceMessage {
                Text(msg)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(DominoTheme.gold.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .transition(.opacity)
            }

            Spacer()

            // Player hand
            VStack(spacing: 8) {
                HStack {
                    Text("Your Hand")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(DominoTheme.gold.opacity(0.7))
                    Spacer()
                    if selectedTile != nil {
                        Text("Tap an end to play")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundStyle(DominoTheme.ivory.opacity(0.6))
                    }
                }
                .padding(.horizontal, 16)

                PlayerHandView(
                    hand: engine.playerHand,
                    validMoves: validMoves,
                    selectedTile: selectedTile,
                    tileStyle: tileStyle,
                    onSelectTile: { tile in
                        handleTileSelection(tile)
                    }
                )
                .padding(.horizontal, 12)

                // Action buttons
                HStack(spacing: 12) {
                    if canDraw {
                        Button(action: drawAction) {
                            Label("Draw", systemImage: "rectangle.stack.badge.plus")
                                .font(.system(.callout, design: .rounded).weight(.semibold))
                                .foregroundStyle(DominoTheme.mahogany)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 16)
                                .background(RoundedRectangle(cornerRadius: 10).fill(DominoTheme.gold))
                        }
                        .accessibilityLabel("Draw tile from boneyard")
                    }

                    if canPass {
                        Button(action: passAction) {
                            Label("Pass", systemImage: "arrow.uturn.right")
                                .font(.system(.callout, design: .rounded).weight(.semibold))
                                .foregroundStyle(DominoTheme.ivory)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(DominoTheme.ivory.opacity(0.5), lineWidth: 1)
                                )
                        }
                        .accessibilityLabel("Pass turn")
                    }

                    Spacer()

                    Button(action: { showNewMatchAlert = true }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 14))
                            .foregroundStyle(DominoTheme.gold.opacity(0.6))
                            .padding(10)
                            .background(Circle().fill(DominoTheme.mahoganyDark.opacity(0.5)))
                    }
                    .accessibilityLabel("New match")
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
    }

    // MARK: - Setup View

    private var setupView: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("Domino")
                .font(DominoTheme.titleFont)
                .foregroundStyle(DominoTheme.gold)
            Button("Start Match") {
                startNewMatch()
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
    }

    // MARK: - Actions

    private func startNewMatch() {
        let diff = DominoEngine.AIDifficulty(rawValue: settings?.difficulty ?? "medium") ?? .medium
        let target = settings?.matchPointTarget ?? 100
        engine.showAIHand = settings?.showAIHand ?? false
        engine.newMatch(difficulty: diff, matchPointTarget: target)
    }

    private func handleTileSelection(_ tile: DominoTile) {
        guard engine.isPlayerTurn, !engine.isAIThinking else { return }

        let moves = validMoves.filter { $0.tile == tile }
        guard !moves.isEmpty else { return }

        if engine.chain.isEmpty {
            // First tile — just play it
            let success = engine.playerPlay(tile: tile, onEnd: .right)
            if success {
                selectedTile = nil
                triggerHaptic(.light)
                updateGuidance()
            }
            return
        }

        // Check if both ends are valid
        let leftValid = moves.contains { $0.end == .left }
        let rightValid = moves.contains { $0.end == .right }

        if leftValid && rightValid {
            // Show choice
            pendingTile = tile
            selectedTile = tile
            withAnimation { showEndChoice = true }
        } else if leftValid {
            let success = engine.playerPlay(tile: tile, onEnd: .left)
            if success {
                selectedTile = nil
                triggerHaptic(.light)
                updateGuidance()
            }
        } else if rightValid {
            let success = engine.playerPlay(tile: tile, onEnd: .right)
            if success {
                selectedTile = nil
                triggerHaptic(.light)
                updateGuidance()
            }
        }
    }

    private func drawAction() {
        let drawn = engine.playerDraw()
        if drawn != nil {
            triggerHaptic(.medium)
            if !engine.hasValidMove(hand: engine.playerHand) && !engine.boneyard.isEmpty {
                showGuidance("No match yet — keep drawing!")
            } else if engine.hasValidMove(hand: engine.playerHand) {
                showGuidance("You can now play!")
            }
        }
    }

    private func passAction() {
        engine.playerPass()
        triggerHaptic(.light)
    }

    private func updateGuidance() {
        if !engine.hasValidMove(hand: engine.playerHand) {
            if !engine.boneyard.isEmpty {
                showGuidance("No valid moves — draw from boneyard")
            }
        } else {
            guidanceMessage = nil
        }
    }

    private func showGuidance(_ msg: String) {
        withAnimation {
            guidanceMessage = msg
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                if guidanceMessage == msg {
                    guidanceMessage = nil
                }
            }
        }
    }

    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard settings?.hapticsEnabled ?? true else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

// MARK: - End Choice Overlay

struct EndChoiceOverlay: View {
    let tile: DominoTile
    let leftEnd: Int
    let rightEnd: Int
    let validMoves: [(tile: DominoTile, end: DominoEngine.ChainEnd)]
    let onChoice: (DominoEngine.ChainEnd) -> Void
    let onCancel: () -> Void

    private var canPlayLeft: Bool { validMoves.contains { $0.tile == tile && $0.end == .left } }
    private var canPlayRight: Bool { validMoves.contains { $0.tile == tile && $0.end == .right } }

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture(perform: onCancel)

            VStack(spacing: 16) {
                Text("Which end?")
                    .font(DominoTheme.subtitleFont)
                    .foregroundStyle(DominoTheme.gold)

                HStack(spacing: 24) {
                    if canPlayLeft {
                        endButton(label: "Left (\(leftEnd))", end: .left)
                    }
                    if canPlayRight {
                        endButton(label: "Right (\(rightEnd))", end: .right)
                    }
                }

                Button("Cancel", action: onCancel)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(DominoTheme.ivory.opacity(0.6))
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(DominoTheme.mahogany)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(DominoTheme.gold.opacity(0.4), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 40)
            .dominoCardShadow()
        }
    }

    private func endButton(label: String, end: DominoEngine.ChainEnd) -> some View {
        Button(action: { onChoice(end) }) {
            Text(label)
                .font(.system(.body, design: .rounded).weight(.semibold))
                .foregroundStyle(DominoTheme.mahogany)
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(DominoTheme.gold)
                )
        }
        .accessibilityLabel("Play on \(end == .left ? "left" : "right") end, value \(end == .left ? leftEnd : rightEnd)")
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @Bindable var engine: DominoEngine
    let settings: DominoSettings

    var body: some View {
        TabView {
            GameView(engine: engine)
                .tabItem {
                    Label("Game", systemImage: "rectangle.on.rectangle")
                }

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }

            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }

            RulesView()
                .tabItem {
                    Label("Rules", systemImage: "book.fill")
                }

            SettingsView(settings: settings, engine: engine)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(DominoTheme.gold)
    }
}
