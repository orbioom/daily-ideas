import SwiftUI
import SwiftData

/// The full interactive play screen for a single puzzle.
///
/// `context` distinguishes a normal level from the Daily puzzle so completion is
/// recorded in the right store. The wall-clock timer is driven from a stored start
/// Date + TimelineView so it survives backgrounding, and is recomputed on scenePhase.
struct GameView: View {
    enum Context: Equatable {
        case level
        case daily(dayKey: String)
    }

    let puzzle: Puzzle
    var context: Context = .level
    /// Optional resume state (paths JSON + elapsed) restored from a SavedBoard.
    var resume: (paths: [PipeColor: [Cell]], elapsed: Int, moves: Int)? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @AppStorage("showTimer") private var showTimer: Bool = true
    @AppStorage("confirmReset") private var confirmReset: Bool = true
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    @AppStorage("animationsEnabled") private var animationsEnabled: Bool = true

    @State private var engine: ConduitEngine
    @State private var startDate: Date
    @State private var accumulatedSeconds: Int
    @State private var isPaused = false
    @State private var showWin = false
    @State private var recorded = false
    @State private var showResetConfirm = false
    @State private var finalSeconds = 0

    init(puzzle: Puzzle, context: Context = .level, resume: (paths: [PipeColor: [Cell]], elapsed: Int, moves: Int)? = nil) {
        self.puzzle = puzzle
        self.context = context
        self.resume = resume
        let eng = ConduitEngine(puzzle: puzzle)
        if let resume {
            eng.restore(paths: resume.paths, moves: resume.moves)
            _accumulatedSeconds = State(initialValue: resume.elapsed)
        } else {
            _accumulatedSeconds = State(initialValue: 0)
        }
        _engine = State(initialValue: eng)
        _startDate = State(initialValue: .now)
    }

    var body: some View {
        ZStack {
            ConduitTheme.appBackground(scheme).ignoresSafeArea()
            VStack(spacing: 14) {
                statusBar
                BoardView(engine: engine) {
                    handleBoardChange()
                }
                .padding(.horizontal, 6)
                toolbar
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)
            .blur(radius: showWin && animationsEnabled && !reduceMotion ? 6 : 0)

            if showWin {
                winOverlay
                    .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
            }
        }
        .navigationTitle(puzzle.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    autosave()
                    dismiss()
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                // Resume timing from now; keep accumulated time.
                startDate = .now
                isPaused = false
            } else {
                pauseClock()
                autosave()
            }
        }
        .onChange(of: engine.isSolved) { _, solved in
            if solved { finishWin() }
        }
        .onAppear {
            ProgressStore.markPlayed(puzzle: puzzle, in: modelContext)
            if engine.isSolved { finishWin() }
        }
    }

    // MARK: - Status bar (timer + counts)

    private var statusBar: some View {
        HStack(spacing: 10) {
            statChip(icon: "link", value: "\(engine.connectedPairs)/\(engine.totalPairs)", label: "pipes")
            statChip(icon: "square.grid.2x2", value: "\(engine.coveragePercent)%", label: "filled")
            statChip(icon: "arrow.triangle.swap", value: "\(engine.moveCount)", label: "moves")
            if showTimer {
                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    statChip(icon: "clock", value: DailyPuzzle.formatTime(currentSeconds), label: "time")
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func statChip(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.caption2)
                Text(value).font(.subheadline.weight(.semibold).monospacedDigit())
            }
            .foregroundStyle(ConduitTheme.primaryText(scheme))
            Text(label).font(.caption2).foregroundStyle(ConduitTheme.secondaryText(scheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(ConduitTheme.subtleSurface(scheme))
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(value) \(label)")
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 12) {
            toolButton("Undo", systemImage: "arrow.uturn.backward", enabled: engine.canUndo) {
                engine.undo()
                autosave()
            }
            toolButton("Hint", systemImage: "lightbulb.fill", enabled: !engine.isSolved) {
                engine.hint()
                if hapticsEnabled { Haptics.connect() }
                handleBoardChange()
            }
            toolButton("Reset", systemImage: "arrow.counterclockwise", enabled: engine.moveCount > 0) {
                if confirmReset {
                    showResetConfirm = true
                } else {
                    performReset()
                }
            }
        }
        .padding(.top, 4)
        .alert("Reset this board?", isPresented: $showResetConfirm) {
            Button("Reset", role: .destructive) { performReset() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This clears all pipes you've drawn on this puzzle.")
        }
    }

    private func toolButton(_ title: String, systemImage: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage).font(.title3)
                Text(title).font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(ConduitTheme.subtleSurface(scheme))
            )
            .foregroundStyle(enabled ? ConduitTheme.accent : ConduitTheme.secondaryText(scheme).opacity(0.5))
        }
        .disabled(!enabled)
        .accessibilityLabel(title)
    }

    // MARK: - Win overlay

    private var winOverlay: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            ConduitCard {
                VStack(spacing: 16) {
                    Image(systemName: engine.isSolved ? "checkmark.seal.fill" : "link.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(ConduitTheme.accent)
                        .accessibilityHidden(true)
                    Text("Solved!")
                        .font(.title.weight(.bold))
                        .foregroundStyle(ConduitTheme.primaryText(scheme))
                    Text("Perfect coverage — every cell filled.")
                        .font(.subheadline)
                        .foregroundStyle(ConduitTheme.secondaryText(scheme))
                        .multilineTextAlignment(.center)

                    HStack(spacing: 24) {
                        resultStat("Time", DailyPuzzle.formatTime(finalSeconds))
                        resultStat("Moves", "\(engine.moveCount)")
                    }
                    .padding(.vertical, 4)

                    VStack(spacing: 10) {
                        if let next = nextPuzzle, context == .level {
                            NavigationLink {
                                GameView(puzzle: next, context: .level)
                            } label: {
                                Text("Next level")
                            }
                            .buttonStyle(ConduitPrimaryButtonStyle())
                        }
                        Button("Back to menu") {
                            ProgressStore.clearSavedBoards(in: modelContext)
                            dismiss()
                        }
                        .buttonStyle(ConduitSecondaryButtonStyle())
                    }
                }
                .padding(8)
            }
            .padding(.horizontal, 32)
        }
        .accessibilityAddTraits(.isModal)
    }

    private func resultStat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(ConduitTheme.primaryText(scheme))
            Text(label).font(.caption).foregroundStyle(ConduitTheme.secondaryText(scheme))
        }
    }

    // MARK: - Logic

    private var currentSeconds: Int {
        if isPaused { return accumulatedSeconds }
        return accumulatedSeconds + Int(Date.now.timeIntervalSince(startDate))
    }

    private var nextPuzzle: Puzzle? {
        let pack = PuzzleBank.puzzles(in: puzzle.packId)
        guard let idx = pack.firstIndex(where: { $0.id == puzzle.id }), idx + 1 < pack.count else { return nil }
        return pack[safe: idx + 1]
    }

    private func handleBoardChange() {
        if engine.isSolved {
            finishWin()
        } else {
            autosave()
        }
    }

    private func pauseClock() {
        guard !isPaused else { return }
        accumulatedSeconds = currentSeconds
        isPaused = true
    }

    private func finishWin() {
        guard !recorded else { return }
        recorded = true
        finalSeconds = currentSeconds
        pauseClock()
        if hapticsEnabled { Haptics.solved() }

        ProgressStore.recordSolve(
            puzzle: puzzle,
            moves: engine.moveCount,
            seconds: finalSeconds,
            perfect: engine.isSolved,
            in: modelContext
        )
        if case let .daily(dayKey) = context {
            ProgressStore.recordDaily(
                dayKey: dayKey,
                puzzleId: puzzle.id,
                seconds: finalSeconds,
                perfect: engine.isSolved,
                in: modelContext
            )
        }
        ProgressStore.clearSavedBoards(in: modelContext)

        if animationsEnabled && !reduceMotion {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { showWin = true }
        } else {
            showWin = true
        }
    }

    private func performReset() {
        engine.reset()
        accumulatedSeconds = 0
        startDate = .now
        isPaused = false
        recorded = false
        ProgressStore.clearSavedBoards(in: modelContext)
    }

    private func autosave() {
        guard !engine.isSolved else { return }
        // Only persist boards with actual progress.
        guard engine.moveCount > 0 || !engine.snapshot().isEmpty else {
            ProgressStore.clearSavedBoards(in: modelContext)
            return
        }
        ProgressStore.saveBoard(
            puzzleId: puzzle.id,
            paths: engine.snapshot(),
            elapsed: currentSeconds,
            moves: engine.moveCount,
            in: modelContext
        )
    }
}
