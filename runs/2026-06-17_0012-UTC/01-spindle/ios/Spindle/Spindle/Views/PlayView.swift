import SwiftUI
import SwiftData

/// The board screen: foundations + stock row, HUD, ten tableau columns,
/// toolbar (New, Undo, Hint, Auto-collect, Menu), win overlay, resume banner.
struct PlayView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @AppStorage(PrefKey.feltTheme) private var feltRaw: String = FeltTheme.emerald.rawValue
    @AppStorage(PrefKey.cardBackStyle) private var backRaw: String = CardBackStyle.lattice.rawValue
    @AppStorage(PrefKey.showTimer) private var showTimer: Bool = true
    @AppStorage(PrefKey.confirmNewGame) private var confirmNewGame: Bool = true
    @AppStorage(PrefKey.leftHandedToolbar) private var leftHanded: Bool = false
    @AppStorage(PrefKey.isPro) private var isPro: Bool = false
    @AppStorage(PrefKey.lastSuitMode) private var lastSuitModeRaw: Int = SuitMode.one.rawValue

    /// The live game. Created lazily on appear (resumed or fresh).
    @State private var game: GameViewModel?
    @State private var showNewGame = false
    @State private var showConfirmNew = false
    @State private var hint: SpiderEngine.Hint?
    @State private var pendingResume: SavedGame?
    @State private var didCheckResume = false

    private var felt: FeltTheme {
        let candidate = FeltTheme(rawValue: feltRaw) ?? .emerald
        // A non-Pro user can't keep a Pro felt selected on the table.
        return (candidate.requiresPro && !isPro) ? .emerald : candidate
    }
    private var backStyle: CardBackStyle { CardBackStyle(rawValue: backRaw) ?? .lattice }

    var body: some View {
        NavigationStack {
            ZStack {
                felt.feltGradient.ignoresSafeArea()

                if let game {
                    boardContent(game)
                } else {
                    startState
                }

                if let pendingResume, game == nil {
                    resumeBanner(pendingResume)
                }
            }
            .navigationTitle("Spindle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(felt.feltTop, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showNewGame) {
                NewGameView { mode, kind in
                    startGame(mode: mode, kind: kind)
                }
            }
            .confirmationDialog("Start a new game?", isPresented: $showConfirmNew, titleVisibility: .visible) {
                Button("New Game", role: .destructive) { showNewGame = true }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your current game will be replaced.")
            }
            .onAppear {
                consumePendingRequest()
                checkForResume()
            }
            .onChange(of: scenePhase) { _, phase in
                handleScenePhase(phase)
            }
        }
        .tint(SpindleTheme.emerald)
    }

    // MARK: - States

    private var startState: some View {
        VStack(spacing: 18) {
            Image(systemName: "rectangle.portrait.on.rectangle.portrait.angled")
                .font(.system(size: 64))
                .foregroundStyle(.white.opacity(0.9))
                .accessibilityHidden(true)
            Text("Ready to play")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
            Text("Choose a difficulty and deal to begin.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
            Button("New Game") { showNewGame = true }
                .buttonStyle(SpindlePrimaryButtonStyle())
                .frame(maxWidth: 260)
            Button("Quick Start (Easy)") {
                startGame(mode: .one, kind: .random)
            }
            .buttonStyle(SpindleSecondaryButtonStyle())
            .frame(maxWidth: 260)
        }
        .padding(32)
    }

    private func resumeBanner(_ saved: SavedGame) -> some View {
        VStack {
            Spacer()
            SpindleCard {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Resume your game", systemImage: "arrow.uturn.backward.circle.fill")
                        .font(.headline)
                        .foregroundStyle(SpindleTheme.primaryText(scheme))
                    Text("\(saved.suitMode.title) · \(saved.moves) moves · score \(saved.score)")
                        .font(.subheadline)
                        .foregroundStyle(SpindleTheme.secondaryText(scheme))
                    HStack {
                        Button("Resume") { resume(saved) }
                            .buttonStyle(SpindlePrimaryButtonStyle())
                        Button("Discard") {
                            SavedGameStore.clear(in: context)
                            pendingResume = nil
                        }
                        .buttonStyle(SpindleSecondaryButtonStyle())
                    }
                }
            }
            .padding(20)
        }
        .transition(.move(edge: .bottom))
    }

    // MARK: - Board

    private func boardContent(_ game: GameViewModel) -> some View {
        GeometryReader { geo in
            // Fit ten columns plus gaps across the width.
            let gap: CGFloat = 6
            let usable = geo.size.width - 16 - gap * CGFloat(SpiderEngine.columnCount - 1)
            let cardWidth = max(28, usable / CGFloat(SpiderEngine.columnCount))

            VStack(spacing: 10) {
                hud(game)
                BoardTopRow(
                    foundations: game.foundations,
                    dealsRemaining: game.dealsRemaining,
                    canDeal: game.canDeal,
                    cardWidth: cardWidth,
                    backStyle: backStyle,
                    feltStroke: felt.feltStroke,
                    onDeal: { withAnimation(motionAnim) { game.deal() } }
                )
                .padding(.horizontal, 8)

                if let banner = game.banner {
                    bannerView(banner)
                }

                ScrollView {
                    HStack(alignment: .top, spacing: gap) {
                        ForEach(0..<SpiderEngine.columnCount, id: \.self) { col in
                            TableauColumnView(
                                columnIndex: col,
                                cards: game.columns[safe: col] ?? [],
                                cardWidth: cardWidth,
                                backStyle: backStyle,
                                feltStroke: felt.feltStroke,
                                hintedIndex: hintedIndex(for: col),
                                isSelected: { idx in game.isSelected(column: col, index: idx) },
                                onTap: { idx in withAnimation(motionAnim) { game.tapColumn(col, cardIndex: idx) }; clearHint() },
                                onDoubleTap: { idx in withAnimation(motionAnim) { game.autoMove(column: col, cardIndex: idx) }; clearHint() }
                            )
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 24)
                }
            }
            .overlay {
                if game.didWin {
                    WinOverlay(
                        score: game.score,
                        moves: game.moves,
                        time: game.elapsedString(),
                        onNewGame: { requestNewGame() }
                    )
                    .onAppear { game.recordResultIfFinished(into: context); SavedGameStore.clear(in: context) }
                }
            }
        }
    }

    private func hud(_ game: GameViewModel) -> some View {
        HStack(spacing: 14) {
            hudStat(title: "Score", value: "\(game.score)")
            hudStat(title: "Moves", value: "\(game.moves)")
            if showTimer {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    hudStat(title: "Time", value: game.elapsedString(at: context.date))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule().fill(Color.black.opacity(0.22))
        )
        .padding(.horizontal, 10)
    }

    private func hudStat(title: String, value: String) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.75))
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(value)")
    }

    private func bannerView(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(Capsule().fill(SpindleTheme.goldDeep))
            .padding(.horizontal, 16)
            .transition(.opacity)
            .accessibilityAddTraits(.isStaticText)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        let placement: ToolbarItemPlacement = leftHanded ? .topBarLeading : .topBarTrailing
        ToolbarItemGroup(placement: placement) {
            Button { requestNewGame() } label: {
                Image(systemName: "plus.rectangle.on.rectangle")
            }
            .accessibilityLabel("New game")

            Button { game?.undo() } label: {
                Image(systemName: "arrow.uturn.backward")
            }
            .disabled(!(game?.canUndo ?? false))
            .accessibilityLabel("Undo")

            Button { showHint() } label: {
                Image(systemName: "lightbulb")
            }
            .disabled(game == nil)
            .accessibilityLabel("Hint")

            Menu {
                Button {
                    withAnimation(motionAnim) { game?.autoCollect() }
                } label: { Label("Auto-collect", systemImage: "tray.and.arrow.down") }
                Button {
                    showHint()
                } label: { Label("Hint", systemImage: "lightbulb") }
                Button {
                    requestNewGame()
                } label: { Label("New Game", systemImage: "plus.rectangle.on.rectangle") }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .disabled(game == nil)
            .accessibilityLabel("More actions")
        }
    }

    // MARK: - Logic

    private var motionAnim: Animation? {
        reduceMotion ? nil : .easeInOut(duration: 0.2)
    }

    private func hintedIndex(for col: Int) -> Int? {
        guard let hint, case let .move(fromColumn, fromIndex, _) = hint.kind, fromColumn == col else { return nil }
        return fromIndex
    }

    private func clearHint() { hint = nil }

    private func showHint() {
        guard let game else { return }
        hint = game.hint()
    }

    private func requestNewGame() {
        if game != nil && confirmNewGame && !(game?.didWin ?? false) {
            showConfirmNew = true
        } else {
            showNewGame = true
        }
    }

    private func startGame(mode: SuitMode, kind: DealKind) {
        let resolvedMode: SuitMode = (mode.requiresPro && !isPro) ? .two : mode
        let vm = GameViewModel.newGame(suitMode: resolvedMode, kind: kind)
        game = vm
        lastSuitModeRaw = resolvedMode.rawValue
        pendingResume = nil
        clearHint()
        SavedGameStore.save(vm, in: context)
    }

    private func resume(_ saved: SavedGame) {
        guard let snapshot = saved.decodedSnapshot() else {
            // Corrupt save — discard gracefully.
            SavedGameStore.clear(in: context)
            pendingResume = nil
            return
        }
        let vm = GameViewModel(
            restored: snapshot.engine,
            dealKind: snapshot.dealKind,
            elapsedSeconds: snapshot.elapsedSeconds
        )
        game = vm
        pendingResume = nil
        clearHint()
    }

    private func checkForResume() {
        guard !didCheckResume else { return }
        didCheckResume = true
        if game == nil, let saved = SavedGameStore.fetch(in: context) {
            pendingResume = saved
        }
    }

    /// Consume a game request handed off from the "New" tab.
    private func consumePendingRequest() {
        if let (mode, kind) = PendingGameRequest.take() {
            startGame(mode: mode, kind: kind)
        }
    }

    private func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            game?.reanchorClock()
        case .background, .inactive:
            if let game, !game.didWin {
                SavedGameStore.save(game, in: context)
            }
        @unknown default:
            break
        }
    }
}
