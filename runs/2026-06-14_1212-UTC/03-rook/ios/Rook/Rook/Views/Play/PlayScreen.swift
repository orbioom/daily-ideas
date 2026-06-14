import SwiftUI
import SwiftData

/// The interactive Play screen: board, controls, move list, AI, persistence.
struct PlayScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \SavedGame.updatedAt, order: .reverse) private var savedGames: [SavedGame]

    @StateObject private var game = GameViewModel()

    @State private var selected: Square?
    @State private var legalTargets: [Square] = []
    @State private var stagedTarget: Square?   // set when "confirm before moving" is on
    @State private var showNewGame = false
    @State private var showResignConfirm = false
    @State private var didRecordResult = false
    @State private var hasLoaded = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        statusBar
                        boardSection
                        controlBar
                        moveListCard
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Rook")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showNewGame = true
                    } label: {
                        Label("New game", systemImage: "plus.circle")
                    }
                }
            }
            .sheet(isPresented: $showNewGame) {
                NewGameSheet(defaultLevel: settings.defaultLevel) { vs, side, level in
                    startNewGame(vsComputer: vs, humanSide: side, level: level)
                }
            }
            .sheet(isPresented: promotionBinding) {
                PromotionSheet(color: game.sideToMove,
                               pieceStyle: settings.pieceStyle,
                               onPick: { piece in handlePromotion(piece) },
                               onCancel: { game.cancelPromotion() })
            }
            .confirmationDialog("Resign this game?", isPresented: $showResignConfirm, titleVisibility: .visible) {
                Button("Resign", role: .destructive) { resign() }
                Button("Keep playing", role: .cancel) { }
            } message: {
                Text("Your opponent will be awarded the win.")
            }
        }
        .task {
            guard !hasLoaded else { return }
            hasLoaded = true
            loadOrCreate()
        }
        .task(id: aiTrigger) {
            await driveAI()
        }
        .onChange(of: game.status.isTerminal) { _, terminal in
            if terminal { finishGame() }
        }
    }

    // MARK: Trigger for the AI turn

    private var aiTrigger: String {
        "\(game.history.count)-\(game.vsComputer)-\(game.humanSide.rawValue)"
    }

    private func driveAI() async {
        // Let any move animation settle, then ask the engine.
        if game.vsComputer && !game.isHumanTurn && !game.isGameOver {
            await game.makeAIMoveIfNeeded()
            persist()
        }
    }

    // MARK: Status bar

    private var statusBar: some View {
        HStack(spacing: 12) {
            turnIndicator
            Spacer()
            if game.isThinking {
                HStack(spacing: 6) {
                    ProgressView().controlSize(.small).tint(Theme.accent)
                    Text("Thinking…")
                        .font(Theme.rounded(14, .medium))
                        .foregroundStyle(Theme.inkSoft)
                }
                .accessibilityLabel("Computer is thinking")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.surface))
    }

    @ViewBuilder
    private var turnIndicator: some View {
        switch game.status {
        case .checkmate(let winner):
            label("Checkmate — \(winner == .white ? "White" : "Black") wins",
                  symbol: "crown.fill", tint: Theme.accent)
        case .stalemate:
            label("Stalemate — draw", symbol: "equal.circle.fill", tint: Theme.inkSoft)
        case .insufficientMaterial:
            label("Draw — insufficient material", symbol: "equal.circle.fill", tint: Theme.inkSoft)
        case .fiftyMoveRule:
            label("Draw — 50-move rule", symbol: "equal.circle.fill", tint: Theme.inkSoft)
        case .threefold:
            label("Draw — threefold repetition", symbol: "equal.circle.fill", tint: Theme.inkSoft)
        case .check(let c):
            label("\(c == .white ? "White" : "Black") to move — check!", symbol: "exclamationmark.triangle.fill", tint: Theme.bad)
        case .ongoing:
            label("\(game.sideToMove == .white ? "White" : "Black") to move", symbol: "circle.fill", tint: Theme.ink)
        }
    }

    private func label(_ text: String, symbol: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint)
            Text(text)
                .font(Theme.rounded(15, .semibold))
                .foregroundStyle(Theme.ink)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Board

    private var boardSection: some View {
        BoardView(board: game.board,
                  theme: settings.effectiveBoardTheme(isPro: isPro),
                  pieceStyle: settings.pieceStyle,
                  flipped: boardFlipped,
                  selectedSquare: stagedTarget ?? selected,
                  legalTargets: legalTargets,
                  lastMove: game.lastMove,
                  checkSquare: game.checkSquare,
                  showLegalDots: settings.showLegalDots,
                  onTapSquare: handleTap)
            .padding(4)
    }

    private var boardFlipped: Bool {
        game.vsComputer && game.humanSide == .black
    }

    // MARK: Controls

    private var controlBar: some View {
        HStack(spacing: 10) {
            controlButton("Undo", systemImage: "arrow.uturn.backward",
                          enabled: !game.history.isEmpty && !game.isThinking) {
                game.undo()
                clearSelection()
                didRecordResult = false
                persist()
            }
            controlButton("Resign", systemImage: "flag",
                          enabled: !game.isGameOver, tint: Theme.bad) {
                showResignConfirm = true
            }
            controlButton("New", systemImage: "plus", enabled: true) {
                showNewGame = true
            }
        }
    }

    private func controlButton(_ title: String, systemImage: String, enabled: Bool,
                               tint: Color = Theme.accent, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage).font(.system(size: 17, weight: .semibold))
                Text(title).font(Theme.rounded(12, .medium))
            }
            .foregroundStyle(enabled ? tint : Theme.inkFaint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.surface))
        }
        .disabled(!enabled)
        .accessibilityLabel(title)
    }

    private var moveListCard: some View {
        SectionCard(title: "Moves", symbol: "list.bullet") {
            MoveListView(moves: game.history)
                .frame(height: 150)
        }
    }

    // MARK: Interaction

    private func handleTap(_ sq: Square) {
        guard !game.isGameOver, game.isHumanTurn else { return }

        if let from = selected {
            if legalTargets.contains(sq) {
                // Confirm-before-moving: first tap stages, second tap on the same square commits.
                if settings.confirmMoves, stagedTarget != sq {
                    stagedTarget = sq
                    Haptics.tap(settings.hapticsEnabled)
                    return
                }
                commitMove(from: from, to: sq)
                return
            }
            // Tapped elsewhere: reselect or clear.
            selectIfOwnPiece(sq)
        } else {
            selectIfOwnPiece(sq)
        }
    }

    private func commitMove(from: Square, to: Square) {
        let outcome = game.attemptUserMove(from: from, to: to)
        switch outcome {
        case .applied(let captured):
            if captured { Haptics.capture(settings.hapticsEnabled) }
            else { Haptics.move(settings.hapticsEnabled) }
            clearSelection()
            persist()
        case .needsPromotion:
            clearSelection() // sheet drives the rest
        case .illegal:
            selectIfOwnPiece(to)
        }
    }

    private func selectIfOwnPiece(_ sq: Square) {
        stagedTarget = nil
        if let p = game.board.piece(at: sq), p.color == game.sideToMove {
            selected = sq
            legalTargets = game.legalDestinations(from: sq).map { $0.to }
            Haptics.tap(settings.hapticsEnabled)
        } else {
            clearSelection()
        }
    }

    private func clearSelection() {
        selected = nil
        legalTargets = []
        stagedTarget = nil
    }

    private var promotionBinding: Binding<Bool> {
        Binding(get: { game.pendingPromotion != nil },
                set: { if !$0 { game.cancelPromotion() } })
    }

    private func handlePromotion(_ piece: PieceType) {
        let outcome = game.completePromotion(piece)
        if case .applied(let captured) = outcome {
            if captured { Haptics.capture(settings.hapticsEnabled) }
            else { Haptics.success(settings.hapticsEnabled) }
            persist()
        }
        clearSelection()
    }

    private func resign() {
        game.resign()
        Haptics.warning(settings.hapticsEnabled)
    }

    // MARK: New game / persistence

    private func startNewGame(vsComputer: Bool, humanSide: HumanSide, level: AILevel) {
        game.newGame(vsComputer: vsComputer, humanSide: humanSide, level: level)
        clearSelection()
        didRecordResult = false
        persist()
        Haptics.tap(settings.hapticsEnabled)
    }

    /// On first appearance, resume the most recent in-progress game or start fresh.
    private func loadOrCreate() {
        if let resume = savedGames.first(where: { $0.result == .inProgress }) {
            game.load(moves: resume.moveList,
                      vsComputer: resume.vsComputer,
                      humanSide: resume.humanSide,
                      level: resume.aiLevel,
                      result: resume.result)
        }
        // Otherwise the default start position is already loaded.
    }

    /// Write the current game into SwiftData (create or update its SavedGame).
    private func persist() {
        let existing = savedGames.first(where: { $0.result == .inProgress })
        let target = existing ?? {
            let g = SavedGame(startFEN: game.startFEN)
            context.insert(g)
            return g
        }()
        target.movesUCI = game.movesUCI
        target.startFEN = game.startFEN
        target.vsComputer = game.vsComputer
        target.computerLevel = game.level.rawValue
        target.humanSide = game.humanSide
        target.updatedAt = Date()
        target.result = game.isGameOver ? game.humanResult : .inProgress
    }

    private func finishGame() {
        guard !didRecordResult else { return }
        didRecordResult = true
        persist()
        // Record for stats.
        let record = GameRecord(date: Date(),
                                result: game.humanResult == .inProgress ? .draw : game.humanResult,
                                vsComputer: game.vsComputer,
                                computerLevel: game.level.rawValue,
                                moveCount: game.history.count)
        context.insert(record)
        if game.humanResult == .win { Haptics.success(settings.hapticsEnabled) }
        else if game.humanResult == .loss { Haptics.error(settings.hapticsEnabled) }
        else { Haptics.warning(settings.hapticsEnabled) }
    }
}
