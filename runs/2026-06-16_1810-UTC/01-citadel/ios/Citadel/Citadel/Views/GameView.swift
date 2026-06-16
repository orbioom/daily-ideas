import SwiftUI
import SwiftData

/// The board screen. Owns the game view model, resumes the SavedGame on appear,
/// persists progress, and presents New Game + win overlay.
struct GameView: View {
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @AppStorage(SettingsKeys.hapticsEnabled) private var hapticsEnabled = true
    @AppStorage(SettingsKeys.autoMoveEnabled) private var autoMoveEnabled = true
    @AppStorage(SettingsKeys.confirmNewGame) private var confirmNewGame = true
    @AppStorage(SettingsKeys.leftHandLayout) private var leftHandLayout = false
    @AppStorage("isPro") private var isPro = false

    /// The single saved-game slot (at most one element).
    @Query private var savedGames: [SavedGame]

    @State private var model = GameViewModel()
    @State private var showNewGame = false
    @State private var didLoad = false
    @State private var showWinOverlay = false

    private var savedGame: SavedGame? { savedGames.first }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.feltGradient(for: colorScheme).ignoresSafeArea()

                GeometryReader { geo in
                    boardContent(in: geo.size)
                }

                if showWinOverlay {
                    WinOverlayView(
                        moveCount: model.moveCount,
                        elapsed: model.elapsedSeconds,
                        dealNumber: model.dealNumber,
                        reduceMotion: reduceMotion,
                        onNewGame: { requestNewGame() },
                        onDismiss: { showWinOverlay = false }
                    )
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale))
                }
            }
            .navigationTitle("Citadel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .safeAreaInset(edge: .bottom) { bottomBar }
            .sheet(isPresented: $showNewGame) {
                NewGameView(
                    isGameInProgress: model.isInProgress,
                    confirmBeforeAbandon: confirmNewGame,
                    onStart: { dealNumber in
                        recordAbandonIfNeeded()
                        model.startNewGame(dealNumber: dealNumber)
                        model.startTimer()
                        persist()
                        showWinOverlay = false
                    }
                )
            }
        }
        .onAppear { loadIfNeeded() }
        .onChange(of: model.hasWon) { _, won in
            if won { handleWin() }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                if didLoad && !model.hasWon { model.startTimer() }
            case .background, .inactive:
                model.stopTimer()
                persist()
            @unknown default:
                break
            }
        }
    }

    // MARK: - Board layout

    @ViewBuilder
    private func boardContent(in size: CGSize) -> some View {
        // Compute a card width that fits 8 columns with gaps and side padding.
        let horizontalPadding: CGFloat = 12
        let interColumnGap: CGFloat = 6
        let available = size.width - horizontalPadding * 2 - interColumnGap * 7
        let cardWidth = max(36, min(74, available / 8))

        VStack(spacing: 14) {
            topRow(cardWidth: cardWidth)
                .padding(.horizontal, horizontalPadding)

            cascadesRow(cardWidth: cardWidth, gap: interColumnGap, available: size)
                .padding(.horizontal, horizontalPadding)

            Spacer(minLength: 0)
        }
        .padding(.top, 8)
    }

    /// Foundations + free cells. Order swaps for left-hand layout.
    @ViewBuilder
    private func topRow(cardWidth: CGFloat) -> some View {
        HStack(alignment: .top, spacing: 6) {
            if leftHandLayout {
                freeCellsGroup(cardWidth: cardWidth)
                Spacer(minLength: 8)
                foundationsGroup(cardWidth: cardWidth)
            } else {
                foundationsGroup(cardWidth: cardWidth)
                Spacer(minLength: 8)
                freeCellsGroup(cardWidth: cardWidth)
            }
        }
    }

    @ViewBuilder
    private func foundationsGroup(cardWidth: CGFloat) -> some View {
        HStack(spacing: 5) {
            ForEach(Suit.allCases) { suit in
                let rank = model.board.foundationRank(suit)
                Button {
                    handleTap(.foundation(suit))
                } label: {
                    if rank > 0 {
                        CardView(card: Card(suit: suit, rank: rank),
                                 isSelected: false, width: cardWidth)
                    } else {
                        SlotView(width: cardWidth, symbol: suit.symbolName,
                                 symbolColor: suit.isRed ? Theme.redPip : Theme.blackPip,
                                 isHighlighted: isDropTarget(.foundation(suit)))
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(suit.displayName) foundation")
                .accessibilityValue(rank > 0 ? "Top card \(Card(suit: suit, rank: rank).rankSpoken)" : "Empty")
                .accessibilityHint("Builds \(suit.displayName) from Ace to King")
            }
        }
    }

    @ViewBuilder
    private func freeCellsGroup(cardWidth: CGFloat) -> some View {
        HStack(spacing: 5) {
            ForEach(0..<Board.freeCellCount, id: \.self) { i in
                let card = model.board.freeCells.indices.contains(i) ? model.board.freeCells[i] : nil
                Button {
                    handleTap(.freeCell(i))
                } label: {
                    if let card {
                        CardView(card: card,
                                 isSelected: model.selection == .freeCell(i),
                                 width: cardWidth)
                    } else {
                        SlotView(width: cardWidth, symbol: "square.dashed",
                                 isHighlighted: isDropTarget(.freeCell(i)))
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Free cell \(i + 1)")
                .accessibilityValue(card?.accessibilityName ?? "Empty")
                .accessibilityHint("Holds one card")
            }
        }
    }

    /// Eight fanned cascade columns.
    @ViewBuilder
    private func cascadesRow(cardWidth: CGFloat, gap: CGFloat, available: CGSize) -> some View {
        let cardHeight = cardWidth * 1.4
        // Overlap so long columns fit; tighter when many cards.
        let fan = max(cardHeight * 0.28, 18)

        HStack(alignment: .top, spacing: gap) {
            ForEach(0..<Board.cascadeCount, id: \.self) { c in
                cascadeColumn(c, cardWidth: cardWidth, fan: fan)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    private func cascadeColumn(_ c: Int, cardWidth: CGFloat, fan: CGFloat) -> some View {
        let column = model.board.cascades.indices.contains(c) ? model.board.cascades[c] : []
        let cardHeight = cardWidth * 1.4

        ZStack(alignment: .top) {
            if column.isEmpty {
                Button {
                    handleTap(.cascade(c))
                } label: {
                    SlotView(width: cardWidth, isHighlighted: isDropTarget(.cascade(c)))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Column \(c + 1)")
                .accessibilityValue("Empty")
            } else {
                ForEach(Array(column.enumerated()), id: \.element.id) { index, card in
                    let isTop = index == column.count - 1
                    let inSelectedRun = isCardInSelectedRun(column: c, index: index)
                    Button {
                        handleTap(.cascade(c))
                    } label: {
                        CardView(card: card, isSelected: inSelectedRun, width: cardWidth)
                    }
                    .buttonStyle(.plain)
                    .offset(y: CGFloat(index) * fan)
                    .zIndex(Double(index))
                    .accessibilityLabel(card.accessibilityName)
                    .accessibilityHint(isTop ? "Top of column \(c + 1). Tap to select or send home." : "In column \(c + 1)")
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: cardHeight + fan * CGFloat(max(0, column.count - 1)), alignment: .top)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: column.count)
    }

    // MARK: - Toolbar & bottom bar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                model.undo(isPro: isPro, hapticsEnabled: hapticsEnabled)
                persist()
            } label: {
                Label("Undo", systemImage: "arrow.uturn.backward")
            }
            .disabled(!model.canUndo(isPro: isPro))
            .accessibilityHint(isPro ? "Undo your last move" : "Undo. \(model.undosRemaining(isPro: isPro)) left in the free version")
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                requestNewGame()
            } label: {
                Label("New Game", systemImage: "plus.rectangle.on.rectangle")
            }
            .accessibilityHint("Start a new deal")
        }
    }

    @ViewBuilder
    private var bottomBar: some View {
        VStack(spacing: 6) {
            if let message = model.errorMessage {
                Text(message)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Theme.redPip.opacity(0.92)))
                    .transition(.opacity)
                    .onAppear { scheduleErrorClear() }
                    .accessibilityAddTraits(.isStaticText)
            }

            HStack(spacing: 18) {
                statChip(icon: "number", label: "Deal", value: "#\(model.dealNumber)")
                statChip(icon: "clock", label: "Time", value: formatDuration(model.elapsedSeconds))
                statChip(icon: "arrow.left.arrow.right", label: "Moves", value: "\(model.moveCount)")

                Spacer()

                Button {
                    model.autoCollect(hapticsEnabled: hapticsEnabled)
                    persist()
                } label: {
                    Label("Auto", systemImage: "wand.and.stars")
                        .font(.subheadline.weight(.semibold))
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)
                .controlSize(.small)
                .accessibilityLabel("Auto-collect")
                .accessibilityHint("Sends every safe card up to the foundations")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: model.errorMessage)
    }

    @ViewBuilder
    private func statChip(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.subheadline.weight(.bold).monospacedDigit())
                .foregroundStyle(Theme.feltText(for: colorScheme))
            Text(label)
                .font(.caption2)
                .foregroundStyle(Theme.feltTextSecondary(for: colorScheme))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(value)
    }

    // MARK: - Interaction helpers

    private func handleTap(_ location: Location) {
        let before = model.moveCount
        model.handleTap(on: location, hapticsEnabled: hapticsEnabled, autoMoveEnabled: autoMoveEnabled)
        if model.moveCount != before {
            persist()
        }
    }

    /// Whether a destination should be highlighted as a legal drop for the current selection.
    private func isDropTarget(_ location: Location) -> Bool {
        guard let source = model.selection, source != location else { return false }
        // Cheap legality probe via a trial apply.
        let count = trialRunCount(from: source, to: location)
        let move = Move(from: source, to: location, count: count)
        return (try? FreeCellEngine.apply(move, to: model.board)) != nil
    }

    private func trialRunCount(from: Location, to: Location) -> Int {
        guard case let .cascade(c) = from, case .cascade = to else { return 1 }
        return FreeCellEngine.movableRunLength(inCascade: c, board: model.board)
    }

    /// Whether a given cascade card is part of the currently selected movable run (for highlight).
    private func isCardInSelectedRun(column c: Int, index: Int) -> Bool {
        guard case let .cascade(selCol) = model.selection, selCol == c else { return false }
        let runLen = FreeCellEngine.movableRunLength(inCascade: c, board: model.board)
        let col = model.board.cascades[c]
        return index >= col.count - runLen
    }

    // MARK: - Lifecycle

    private func loadIfNeeded() {
        guard !didLoad else {
            if !model.hasWon { model.startTimer() }
            return
        }
        didLoad = true
        if let saved = savedGame, saved.decodedBoard != nil {
            if model.restore(from: saved) {
                if !model.hasWon { model.startTimer() }
                if model.hasWon { showWinOverlay = false }
                return
            }
        }
        // No valid saved game: start a fresh today's deal and persist.
        let today = FreeCellEngine.dealNumber(for: .now)
        model.startNewGame(dealNumber: today)
        model.startTimer()
        persist()
    }

    private func requestNewGame() {
        showWinOverlay = false
        showNewGame = true
    }

    private func handleWin() {
        recordResult(won: true)
        clearSavedGame()
        withAnimation(reduceMotion ? .none : .spring(response: 0.5, dampingFraction: 0.8)) {
            showWinOverlay = true
        }
    }

    private func recordAbandonIfNeeded() {
        guard model.isInProgress else { return }
        recordResult(won: false)
    }

    private func recordResult(won: Bool) {
        guard let result = model.makeResult(won: won) else { return }
        modelContext.insert(result)
        try? modelContext.save()
    }

    private func persist() {
        guard didLoad else { return }
        if model.hasWon {
            clearSavedGame()
            return
        }
        model.persist(into: modelContext, existing: savedGame)
    }

    private func clearSavedGame() {
        if let saved = savedGame {
            modelContext.delete(saved)
            try? modelContext.save()
        }
    }

    private func scheduleErrorClear() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            if model.errorMessage != nil {
                model.errorMessage = nil
            }
        }
    }
}
