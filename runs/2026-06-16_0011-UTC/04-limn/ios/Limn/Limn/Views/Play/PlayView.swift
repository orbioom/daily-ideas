import SwiftUI
import SwiftData

/// The board play screen for one puzzle. Restores an in-progress `SavedGame` on entry,
/// persists progress, applies hints from the line solver, and reveals the picture on win.
struct PlayView: View {
    let puzzle: Puzzle
    /// When non-nil, completing the puzzle records a daily result for this key.
    var dailyKey: String? = nil

    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("isPro") private var isPro = false

    @State private var model: GameViewModel
    @State private var tapMode: TapMode
    @State private var didLoad = false
    @State private var showWin = false
    @State private var hintNote: String?
    @State private var showRestartConfirm = false
    @State private var paywallReason: PaywallReason?

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(puzzle: Puzzle, dailyKey: String? = nil) {
        self.puzzle = puzzle
        self.dailyKey = dailyKey
        _model = State(initialValue: GameViewModel(puzzle: puzzle))
        _tapMode = State(initialValue: TapMode.fill)
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 12) {
                header
                progressBar
                BoardView(model: model, tapMode: tapMode, assist: settings.assistMode) { r, c in
                    handleTap(r, c)
                }
                .frame(maxHeight: .infinity)
                controls
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 10)

            if showWin {
                WinOverlay(puzzle: puzzle,
                           timeLabel: model.timeLabel,
                           mistakes: model.mistakes,
                           showMistakes: settings.showMistakes,
                           onClose: { dismiss() },
                           onReplay: { replay() })
                .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.96)))
                .zIndex(2)
            }
        }
        .navigationTitle(dailyKey == nil ? puzzle.name : "Daily • \(puzzle.name)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Picker("Mode", selection: $tapMode) {
                    ForEach(TapMode.allCases) { m in
                        Image(systemName: m.systemImage).tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 96)
                .accessibilityLabel("Tap mode")
            }
        }
        .onAppear(perform: loadIfNeeded)
        .onReceive(timer) { _ in
            guard !showWin else { return }
            model.tick()
            // Persist roughly every 5 seconds while playing.
            if model.elapsedSeconds % 5 == 0 { persist() }
        }
        .onChange(of: model.isSolved) { _, solved in
            if solved { handleWin() }
        }
        .onDisappear { persist() }
        .sheet(item: $paywallReason) { PaywallView(reason: $0) }
        .confirmationDialog("Restart this puzzle?", isPresented: $showRestartConfirm, titleVisibility: .visible) {
            Button("Restart", role: .destructive) {
                model.restart()
                persist()
                Haptics.warning(enabled: settings.hapticsEnabled)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This clears all your marks on this puzzle. Your best time is kept.")
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            statPill(icon: "timer", value: model.timeLabel, label: "Time")
            if settings.showMistakes {
                statPill(icon: "exclamationmark.triangle",
                         value: mistakeText,
                         label: "Mistakes",
                         tint: model.mistakes > 0 ? Theme.bad : Theme.inkSoft)
            }
            statPill(icon: "square.grid.2x2", value: puzzle.sizeLabel, label: "Size")
        }
    }

    private var mistakeText: String {
        if isPro || !settings.assistMode { return "\(model.mistakes)" }
        return "\(model.mistakes)/\(Pro.freeMistakeCap)"
    }

    private func statPill(icon: String, value: String, label: String, tint: Color = Theme.inkSoft) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 12, weight: .semibold)).foregroundStyle(tint)
            Text(value).font(Theme.mono(15, .bold)).foregroundStyle(Theme.ink)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .cardSurface(fill: Theme.surface, corner: Theme.cornerSmall)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)")
    }

    private var progressBar: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.hairline)
                    Capsule().fill(Theme.heroGradient)
                        .frame(width: max(6, geo.size.width * model.progress))
                        .animation(reduceMotion ? nil : .easeOut(duration: 0.25), value: model.progress)
                }
            }
            .frame(height: 6)
            if let note = hintNote {
                Text(note)
                    .font(Theme.rounded(12, .medium))
                    .foregroundStyle(Theme.accentDeep)
                    .transition(.opacity)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress \(Int(model.progress * 100)) percent")
    }

    // MARK: - Controls

    private var controls: some View {
        HStack(spacing: 10) {
            controlButton(title: "Hint", icon: "lightbulb.fill") { requestHint() }
            controlButton(title: "Undo", icon: "arrow.uturn.backward",
                          enabled: model.canUndo) {
                model.undo()
                persist()
                Haptics.selection(enabled: settings.hapticsEnabled)
            }
            controlButton(title: "Restart", icon: "arrow.counterclockwise") {
                showRestartConfirm = true
            }
        }
    }

    private func controlButton(title: String, icon: String, enabled: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 17, weight: .semibold))
                Text(title).font(Theme.rounded(12, .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .foregroundStyle(enabled ? Theme.accent : Theme.inkFaint)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                    .fill(Theme.accentSoft.opacity(enabled ? 1 : 0.4))
            )
        }
        .buttonStyle(PressableScale())
        .disabled(!enabled)
        .accessibilityHint(title == "Hint" ? "Reveals one logically certain cell" : "")
    }

    // MARK: - Actions

    private func handleTap(_ r: Int, _ c: Int) {
        // Enforce the free mistake cap in assist mode.
        if !isPro && settings.assistMode && tapMode == .fill {
            let willBeMistake = !model.solutionFilled(r, c) && model.state(r, c) != .filled
            if willBeMistake && model.mistakes >= Pro.freeMistakeCap {
                paywallReason = .mistakeCap
                Haptics.warning(enabled: settings.hapticsEnabled)
                return
            }
        }

        model.lastHintCell = nil
        let result = model.tap(r, c, mode: tapMode, assist: settings.assistMode)
        guard let newState = result else { return }

        if settings.assistMode && tapMode == .fill && newState == .filled && !model.solutionFilled(r, c) {
            Haptics.warning(enabled: settings.hapticsEnabled)
        } else {
            Haptics.tap(enabled: settings.hapticsEnabled)
        }

        if settings.autoCrossCompletedLines && newState == .filled {
            model.autoCrossCompletedLines()
        }
        persist()
    }

    private func requestHint() {
        model.lastHintCell = nil
        let result = model.applyHint()
        switch result {
        case .applied(_, _, let state):
            Haptics.success(enabled: settings.hapticsEnabled)
            withAnimation(reduceMotion ? nil : .easeInOut) {
                hintNote = state == .filled ? "Hint: this cell must be filled." : "Hint: this cell must be empty."
            }
            scheduleHintNoteClear()
            persist()
        case .nothingForced:
            withAnimation(reduceMotion ? nil : .easeInOut) {
                hintNote = "No certain move from here — try another line."
            }
            scheduleHintNoteClear()
        case .alreadySolved:
            break
        }
    }

    private func scheduleHintNoteClear() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation { hintNote = nil }
        }
    }

    // MARK: - Lifecycle

    private func loadIfNeeded() {
        guard !didLoad else { return }
        didLoad = true
        // Restore an existing SavedGame for this puzzle if present.
        if let saved = fetchSavedGame(),
           let grid = GridCodec.decode(saved.gridState, rows: puzzle.rows, cols: puzzle.cols) {
            model = GameViewModel(puzzle: puzzle,
                                  restoredGrid: grid,
                                  elapsedSeconds: saved.elapsedSeconds,
                                  mistakes: saved.mistakes)
        }
        tapMode = settings.defaultTapMode
        if model.isSolved { showWin = true }
    }

    private func handleWin() {
        guard !showWin else { return }
        model.lastHintCell = nil
        Haptics.success(enabled: settings.hapticsEnabled)
        recordCompletion()
        clearSavedGame()
        withAnimation(reduceMotion ? .none : .spring(response: 0.4, dampingFraction: 0.8)) {
            showWin = true
        }
    }

    private func replay() {
        model.restart()
        showWin = false
        persist()
    }

    // MARK: - Persistence

    private func fetchSavedGame() -> SavedGame? {
        let id = puzzle.id
        let descriptor = FetchDescriptor<SavedGame>(predicate: #Predicate { $0.puzzleID == id })
        return (try? modelContext.fetch(descriptor))?.first
    }

    private func persist() {
        guard !model.isSolved else { return }
        if let saved = fetchSavedGame() {
            saved.gridState = model.encodedGrid
            saved.elapsedSeconds = model.elapsedSeconds
            saved.mistakes = model.mistakes
            saved.updatedAt = Date()
        } else {
            let saved = SavedGame(puzzleID: puzzle.id,
                                  gridState: model.encodedGrid,
                                  elapsedSeconds: model.elapsedSeconds,
                                  mistakes: model.mistakes)
            modelContext.insert(saved)
        }
        try? modelContext.save()
    }

    private func clearSavedGame() {
        if let saved = fetchSavedGame() {
            modelContext.delete(saved)
            try? modelContext.save()
        }
    }

    private func recordCompletion() {
        let id = puzzle.id
        let time = model.elapsedSeconds
        let mistakes = model.mistakes

        // PuzzleRecord (upsert; keep the best time).
        let recDescriptor = FetchDescriptor<PuzzleRecord>(predicate: #Predicate { $0.puzzleID == id })
        if let existing = (try? modelContext.fetch(recDescriptor))?.first {
            if !existing.completed || (existing.bestTimeSeconds == 0) || time < existing.bestTimeSeconds {
                existing.bestTimeSeconds = time
            }
            existing.completed = true
            existing.completedDate = Date()
            existing.mistakes = mistakes
        } else {
            modelContext.insert(PuzzleRecord(puzzleID: id,
                                             bestTimeSeconds: time,
                                             completedDate: Date(),
                                             mistakes: mistakes,
                                             completed: true))
        }

        // DailyResult, if this was a daily.
        if let key = dailyKey {
            let dailyDescriptor = FetchDescriptor<DailyResult>(predicate: #Predicate { $0.dateKey == key })
            if let existing = (try? modelContext.fetch(dailyDescriptor))?.first {
                existing.completed = true
                existing.timeSeconds = time
                existing.mistakes = mistakes
                existing.puzzleID = id
            } else {
                modelContext.insert(DailyResult(dateKey: key,
                                                puzzleID: id,
                                                completed: true,
                                                timeSeconds: time,
                                                mistakes: mistakes))
            }
        }

        try? modelContext.save()
    }
}
