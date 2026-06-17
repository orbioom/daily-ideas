import SwiftUI
import SwiftData

/// The shared playable screen: header + board + keyboard + end card. Used by the
/// daily Play tab, Archive puzzles, and Practice. It owns a `GameViewModel` created
/// from a `GameConfig`, restoring any saved progress and persisting on every move.
struct GameBoardScreen: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var context
    @AppStorage(PrefKey.hardMode) private var hardMode: Bool = false
    @AppStorage(PrefKey.highContrastColors) private var highContrast: Bool = false

    let config: GameConfig
    /// Title shown in the header (e.g. "Today", a date, or "Practice").
    let title: String
    let subtitle: String
    /// Whether this screen can start a fresh game when the current one ends
    /// (true for Practice). Daily/archive cannot be replayed.
    let allowReplay: Bool

    @State private var vm: GameViewModel
    @State private var showEndCard = false
    @State private var stats: StatsSummary = .empty
    @State private var loadFailed = false

    init(config: GameConfig, title: String, subtitle: String, allowReplay: Bool) {
        self.config = config
        self.title = title
        self.subtitle = subtitle
        self.allowReplay = allowReplay
        _vm = State(initialValue: config.makeViewModel())
    }

    var body: some View {
        ZStack {
            LexBackground()

            if loadFailed {
                errorState
            } else {
                content
            }

            if showEndCard {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture { showEndCard = false }
                    .transition(.opacity)
                VStack {
                    Spacer()
                    EndCardView(
                        vm: vm,
                        highContrast: highContrast,
                        stats: stats,
                        primaryTitle: allowReplay ? "Play Again" : "Done",
                        onPrimary: { endCardPrimary() },
                        onDismiss: { showEndCard = false }
                    )
                    .padding(.bottom, 24)
                }
                .transition(.move(edge: .bottom))
            }
        }
        .task { onLoad() }
        .onChange(of: vm.shakeToken) { _, _ in Haptics.warning() }
    }

    // MARK: - Content

    private var content: some View {
        VStack(spacing: 8) {
            header

            Spacer(minLength: 4)

            BoardView(vm: vm, highContrast: highContrast)
                .frame(maxWidth: 360)
                .padding(.horizontal, 24)

            // Calm transient message area (fixed height to avoid layout jumps).
            Text(vm.message ?? " ")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(LexTheme.primaryText(scheme))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(vm.message == nil ? Color.clear : LexTheme.subtleSurface(scheme))
                )
                .opacity(vm.message == nil ? 0 : 1)
                .animation(.easeInOut(duration: 0.15), value: vm.message)
                .accessibilityHidden(vm.message == nil)

            Spacer(minLength: 4)

            if vm.isFinished {
                finishedBar
            } else {
                KeyboardView(
                    keyStates: vm.keyboardStates(),
                    highContrast: highContrast,
                    disabled: false,
                    onLetter: { vm.typeLetter($0) },
                    onEnter: { submit() },
                    onDelete: { vm.deleteLetter() }
                )
                .padding(.bottom, 8)
            }
        }
        .padding(.top, 8)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(LexTheme.display(22, weight: .bold))
                    .foregroundStyle(LexTheme.primaryText(scheme))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(LexTheme.secondaryText(scheme))
            }
            Spacer()
            if hardMode {
                Label("Hard", systemImage: "flame.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(LexTheme.green)
                    .accessibilityLabel("Hard mode on")
            }
        }
        .padding(.horizontal, 20)
    }

    private var finishedBar: some View {
        VStack(spacing: 10) {
            Button {
                withAnimation { showEndCard = true }
            } label: {
                Label(vm.didWin ? "You solved it — view result" : "View result",
                      systemImage: "rosette")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(LexPrimaryButtonStyle())

            if allowReplay {
                Button("New Practice Word") { replay() }
                    .buttonStyle(LexSecondaryButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    private var errorState: some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(LexTheme.secondaryText(scheme))
                .accessibilityHidden(true)
            Text("Puzzle unavailable")
                .font(.title3.weight(.semibold))
                .foregroundStyle(LexTheme.primaryText(scheme))
            Text("The word list for this length couldn't be loaded. Try another length in Practice.")
                .font(.subheadline)
                .foregroundStyle(LexTheme.secondaryText(scheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    // MARK: - Behavior

    private func onLoad() {
        if config.answer.isEmpty {
            loadFailed = true
            return
        }
        restoreIfNeeded()
        // A restored game may have finished before its result was recorded
        // (e.g. app killed mid-reveal); recordResultIfNeeded de-dupes safely.
        if vm.isFinished {
            vm.recordResultIfNeeded(in: context)
        }
        refreshStats()
    }

    private func restoreIfNeeded() {
        guard let saved = SavedGameStore.fetch(key: config.savedKey, in: context),
              saved.answer == config.answer,
              let board = saved.decodedBoard() else { return }
        vm.restore(from: board, status: saved.status, currentRow: saved.currentRow)
    }

    private func submit() {
        guard let _ = vm.submit(hardMode: hardMode) else { return }
        vm.persist(in: context)
        if vm.isFinished {
            finishGame()
        }
    }

    private func finishGame() {
        vm.recordResultIfNeeded(in: context)
        refreshStats()
        if vm.didWin { Haptics.success() } else { Haptics.rigid() }
        // Reveal the end card after the row's flip animation completes.
        let revealDelay = 0.18 * Double(config.wordLength) + 0.4
        DispatchQueue.main.asyncAfter(deadline: .now() + revealDelay) {
            withAnimation { showEndCard = true }
        }
    }

    private func endCardPrimary() {
        if allowReplay {
            replay()
        } else {
            showEndCard = false
        }
    }

    private func replay() {
        guard allowReplay else { return }
        SavedGameStore.clear(key: config.savedKey, in: context)
        vm = config.makeFreshPracticeViewModel() ?? config.makeViewModel()
        showEndCard = false
    }

    private func refreshStats() {
        let descriptor = FetchDescriptor<GameResult>()
        let results = (try? context.fetch(descriptor)) ?? []
        stats = StatsSummary.make(from: results)
    }
}
