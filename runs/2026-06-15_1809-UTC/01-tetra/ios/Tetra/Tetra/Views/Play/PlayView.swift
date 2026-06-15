import SwiftUI
import SwiftData

struct PlayView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("isPro") private var isPro = false

    @StateObject private var game: GameViewModel
    @Query private var records: [GameRecord]

    @State private var didLoad = false
    @State private var paywallReason: PaywallReason?
    @State private var showNewGameConfirm = false
    @State private var showSettings = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init() {
        // Initial size is replaced on first load from settings; 4 is a safe default.
        _game = StateObject(wrappedValue: GameViewModel(boardSize: 4))
    }

    private let boardSizes = [4, 5, 6]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
                overlays
            }
            .navigationTitle("Tetra")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
            .confirmationDialog("Start a new game?", isPresented: $showNewGameConfirm, titleVisibility: .visible) {
                Button("New game", role: .destructive) { startFresh() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your current game on this board will be replaced.")
            }
        }
        .onAppear(perform: loadIfNeeded)
        .onReceive(timer) { _ in game.tick() }
    }

    private func loadIfNeeded() {
        guard !didLoad else { return }
        didLoad = true
        var size = settings.defaultBoardSize
        if !(Pro.boardSizeIsFree(size) || isPro) { size = 4 }
        game.loadOrStart(size: size, context: modelContext)
    }

    private var content: some View {
        VStack(spacing: 14) {
            header
            sizePicker
            boardSection
            controls
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.top, 6)
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 10) {
            StatChip(caption: "Score", value: "\(game.score)")
            StatChip(caption: "Best", value: "\(displayBest)")
            if settings.showBestOverlay {
                StatChip(caption: "Moves", value: "\(game.moves)")
            }
        }
    }

    private var displayBest: Int {
        let seeded = records.filter { $0.boardSize == game.boardSize }.map(\.score).max() ?? 0
        return max(game.best, seeded)
    }

    // MARK: Size picker

    private var sizePicker: some View {
        HStack(spacing: 8) {
            ForEach(boardSizes, id: \.self) { size in
                let locked = !(Pro.boardSizeIsFree(size) || isPro)
                Button {
                    selectSize(size)
                } label: {
                    HStack(spacing: 4) {
                        Text("\(size)×\(size)")
                            .font(Theme.rounded(15, .bold))
                        if locked {
                            Image(systemName: "lock.fill").font(.system(size: 10, weight: .bold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .foregroundStyle(game.boardSize == size ? .white : Theme.inkSoft)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                            .fill(game.boardSize == size ? AnyShapeStyle(Theme.heroGradient) : AnyShapeStyle(Theme.surface))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                            .strokeBorder(Theme.hairline, lineWidth: game.boardSize == size ? 0 : 1)
                    )
                }
                .buttonStyle(PressableScale())
                .accessibilityLabel("\(size) by \(size) board\(locked ? ", Pro" : "")")
                .accessibilityAddTraits(game.boardSize == size ? .isSelected : [])
            }
        }
    }

    private func selectSize(_ size: Int) {
        if !(Pro.boardSizeIsFree(size) || isPro) {
            paywallReason = .biggerBoards
            return
        }
        guard size != game.boardSize else { return }
        Haptics.selection(enabled: settings.hapticsEnabled)
        // Persist the current game, then switch (loads or starts the other size).
        game.persist()
        game.loadOrStart(size: size, context: modelContext)
    }

    // MARK: Board

    private var boardSection: some View {
        BoardView(game: game)
            .contentShape(Rectangle())
            .gesture(swipeGesture)
            .padding(.vertical, 2)
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 18)
            .onEnded { value in
                guard !game.isGameOver, !game.showWinOverlay else { return }
                let dx = value.translation.width
                let dy = value.translation.height
                guard abs(dx) > 12 || abs(dy) > 12 else { return }
                let direction: Direction = abs(dx) > abs(dy)
                    ? (dx > 0 ? .right : .left)
                    : (dy > 0 ? .down : .up)
                apply(direction)
            }
    }

    private func apply(_ direction: Direction) {
        let result = game.handle(direction)
        guard result.moved else { return }
        if result.merges > 0 {
            Haptics.tap(enabled: settings.hapticsEnabled)
        }
        if game.showWinOverlay {
            Haptics.success(enabled: settings.hapticsEnabled)
        }
    }

    // MARK: Controls

    private var controls: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Button(action: tryNewGame) {
                    controlLabel("New Game", "arrow.clockwise")
                }
                .buttonStyle(PressableScale())

                if settings.swipeToUndoEnabled {
                    Button(action: tryUndo) {
                        controlLabel(undoLabel, "arrow.uturn.backward")
                            .opacity(game.canUndo ? 1 : 0.5)
                    }
                    .buttonStyle(PressableScale())
                    .disabled(!game.canUndo)
                    .accessibilityHint(isPro ? "" : "You have \(game.remainingFreeUndos(isPro: false)) free undos left this game.")
                }
            }

            Button(action: tryDaily) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar.badge.clock").accessibilityHidden(true)
                    Text(dailyLabel).font(Theme.rounded(15, .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundStyle(Theme.accent)
                .background(
                    RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                        .fill(Theme.accentSoft)
                )
            }
            .buttonStyle(PressableScale())
            .accessibilityLabel(dailyAlreadyPlayed ? "Daily challenge, already played today" : "Play today's daily challenge")
        }
    }

    private func controlLabel(_ title: String, _ symbol: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol).accessibilityHidden(true)
            Text(title).font(Theme.rounded(15, .semibold))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .foregroundStyle(Theme.ink)
        .background(
            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                .fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                .strokeBorder(Theme.hairline, lineWidth: 1)
        )
    }

    private var undoLabel: String {
        if isPro { return "Undo" }
        return "Undo (\(game.remainingFreeUndos(isPro: false)))"
    }

    private func tryNewGame() {
        if game.isInProgress {
            showNewGameConfirm = true
        } else {
            startFresh()
        }
    }

    private func startFresh() {
        Haptics.selection(enabled: settings.hapticsEnabled)
        game.startNewGame(size: game.boardSize, mode: .classic, seed: nil)
    }

    private func tryUndo() {
        if game.hasFreeUndo(isPro: isPro) {
            if game.undo(unlimited: isPro) {
                Haptics.selection(enabled: settings.hapticsEnabled)
            }
        } else {
            paywallReason = .unlimitedUndo
        }
    }

    private var dailyAlreadyPlayed: Bool {
        DailyChallenge.alreadyPlayed(records: records, on: Date())
    }

    private var dailyLabel: String {
        let day = DailyChallenge.label(for: Date())
        return dailyAlreadyPlayed ? "Daily \(day) — replay" : "Daily Challenge · \(day)"
    }

    private func tryDaily() {
        Haptics.selection(enabled: settings.hapticsEnabled)
        let seed = DailyChallenge.seed(for: Date())
        // Daily always plays on the classic 4×4 so everyone shares the same board.
        game.persist()
        if game.boardSize != 4 {
            game.loadOrStart(size: 4, context: modelContext)
        }
        game.startNewGame(size: 4, mode: .daily, seed: seed)
    }

    // MARK: Overlays

    @ViewBuilder
    private var overlays: some View {
        if game.showWinOverlay {
            resultOverlay(
                symbol: "star.fill",
                title: "You made 2048!",
                message: "Beautiful run. Keep going for an even higher tile, or start fresh.",
                primaryTitle: "Keep going",
                primaryAction: { game.continuePlaying() },
                secondaryTitle: "New game",
                secondaryAction: { game.startNewGame(size: game.boardSize, mode: game.mode, seed: nil) }
            )
        } else if game.isGameOver {
            resultOverlay(
                symbol: "flag.checkered",
                title: "No moves left",
                message: "Final score \(game.score) · highest tile \(BoardEngine(size: game.boardSize, grid: game.grid).highestTile).",
                primaryTitle: "Play again",
                primaryAction: { game.startNewGame(size: game.boardSize, mode: .classic, seed: nil) },
                secondaryTitle: nil,
                secondaryAction: nil
            )
        }
    }

    private func resultOverlay(symbol: String, title: String, message: String,
                               primaryTitle: String, primaryAction: @escaping () -> Void,
                               secondaryTitle: String?, secondaryAction: (() -> Void)?) -> some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
                .accessibilityHidden(true)
            VStack(spacing: 18) {
                Image(systemName: symbol)
                    .font(.system(size: 46, weight: .light))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                Text(title)
                    .font(Theme.rounded(26, .bold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                Text(message)
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                VStack(spacing: 10) {
                    PrimaryButton(title: primaryTitle) {
                        Haptics.selection(enabled: settings.hapticsEnabled)
                        primaryAction()
                    }
                    if let secondaryTitle, let secondaryAction {
                        SecondaryButton(title: secondaryTitle) {
                            Haptics.selection(enabled: settings.hapticsEnabled)
                            secondaryAction()
                        }
                    }
                }
            }
            .padding(26)
            .frame(maxWidth: 340)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Theme.surface)
            )
            .padding(28)
            .transition(reduceMotion ? .opacity : .scale(scale: 0.92).combined(with: .opacity))
        }
        .animation(reduceMotion ? .easeInOut(duration: 0.15) : .spring(response: 0.3, dampingFraction: 0.8),
                   value: game.showWinOverlay || game.isGameOver)
    }
}
