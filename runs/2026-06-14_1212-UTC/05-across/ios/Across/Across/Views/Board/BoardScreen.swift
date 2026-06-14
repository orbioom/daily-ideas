import SwiftUI
import SwiftData

/// The interactive solver. Owns a BoardViewModel, persists progress continuously,
/// and records a DailyResult when the daily is solved.
struct BoardScreen: View {
    let puzzle: Puzzle
    /// The day key this play counts toward (nil = not the daily; archive replay).
    let dailyDateKey: String?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var vm: BoardViewModel
    @State private var showRevealConfirm: RevealScope?
    @State private var showWin = false

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    enum RevealScope: Identifiable {
        case cell, word, puzzle
        var id: String {
            switch self {
            case .cell: return "cell"
            case .word: return "word"
            case .puzzle: return "puzzle"
            }
        }
        var label: String {
            switch self {
            case .cell: return "this square"
            case .word: return "this word"
            case .puzzle: return "the whole puzzle"
            }
        }
    }

    init(puzzle: Puzzle, dailyDateKey: String?, progress: PuzzleProgress?, settings: AppSettings?) {
        self.puzzle = puzzle
        self.dailyDateKey = dailyDateKey
        _vm = StateObject(wrappedValue: BoardViewModel(puzzle: puzzle, progress: progress, settings: settings))
    }

    var body: some View {
        Group {
            if vm.isValid {
                solver
            } else {
                errorState
            }
        }
        .navigationTitle(puzzle.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .onReceive(ticker) { _ in vm.tick() }
        .onAppear { vm.resume() }
        .onDisappear { persist() ; vm.pause() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { vm.resume() } else { vm.pause(); persist() }
        }
        .onChange(of: vm.justSolved) { _, solved in
            if solved {
                persist()
                recordDailyIfNeeded()
                showWin = true
                vm.justSolved = false
            }
        }
        .confirmationDialog("Reveal \(showRevealConfirm?.label ?? "")?",
                            isPresented: revealConfirmBinding,
                            titleVisibility: .visible) {
            Button("Reveal", role: .destructive) { performReveal() }
            Button("Cancel", role: .cancel) { showRevealConfirm = nil }
        } message: {
            Text("This fills in the correct letters.")
        }
    }

    // MARK: Solver layout

    private var solver: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                if settings.showTimer {
                    timerStrip
                }
                Spacer(minLength: 8)
                GridView(vm: vm)
                    .padding(.horizontal, 14)
                    .frame(maxHeight: .infinity)
                Spacer(minLength: 8)
                ClueBar(vm: vm)
                KeyboardView(
                    onKey: { vm.type($0); afterEntry() },
                    onDelete: { vm.deleteBackward() },
                    onNext: { vm.nextClue() }
                )
            }
        }
        .overlay {
            if showWin {
                WinOverlay(elapsedSeconds: vm.elapsedSeconds,
                           usedReveal: vm.usedReveal,
                           onDone: { showWin = false },
                           onArchive: { showWin = false; dismiss() })
                .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale))
            }
        }
        .animation(reduceMotion ? nil : .easeInOut, value: showWin)
    }

    private var timerStrip: some View {
        HStack {
            Label(TimeFormat.clock(vm.elapsedSeconds), systemImage: "clock")
                .font(Theme.mono(16, .semibold))
                .foregroundStyle(Theme.ink)
                .monospacedDigit()
                .accessibilityLabel("Elapsed time \(TimeFormat.compact(vm.elapsedSeconds))")
            Spacer()
            if vm.isComplete {
                Label("Solved", systemImage: "checkmark.seal.fill")
                    .font(Theme.rounded(14, .semibold))
                    .foregroundStyle(Theme.good)
            } else {
                DifficultyTag(difficulty: puzzle.difficulty)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
    }

    // MARK: Toolbar (Check / Reveal menus)

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Section("Check") {
                    Button { vm.checkCell(vm.selected) } label: { Label("Square", systemImage: "square") }
                    Button { vm.checkCurrentSlot() } label: { Label("Word", systemImage: "text.word.spacing") }
                    Button { vm.checkPuzzle() } label: { Label("Puzzle", systemImage: "square.grid.3x3") }
                }
                Section("Reveal") {
                    Button(role: .destructive) { requestReveal(.cell) } label: { Label("Square", systemImage: "eye") }
                    Button(role: .destructive) { requestReveal(.word) } label: { Label("Word", systemImage: "eye") }
                    Button(role: .destructive) { requestReveal(.puzzle) } label: { Label("Puzzle", systemImage: "eye.fill") }
                }
            } label: {
                Image(systemName: "checkmark.circle")
                    .accessibilityLabel("Check or reveal")
            }
        }
    }

    // MARK: Actions

    private func afterEntry() {
        persist()
    }

    private func requestReveal(_ scope: RevealScope) {
        if settings.confirmReveal {
            showRevealConfirm = scope
        } else {
            showRevealConfirm = scope
            performReveal()
        }
    }

    private var revealConfirmBinding: Binding<Bool> {
        Binding(
            get: { settings.confirmReveal && showRevealConfirm != nil },
            set: { if !$0 { showRevealConfirm = nil } }
        )
    }

    private func performReveal() {
        guard let scope = showRevealConfirm else { return }
        switch scope {
        case .cell: vm.revealCell(vm.selected)
        case .word: vm.revealCurrentSlot()
        case .puzzle: vm.revealPuzzle()
        }
        showRevealConfirm = nil
        persist()
        if vm.isComplete {
            recordDailyIfNeeded()
            showWin = true
        }
    }

    // MARK: Persistence

    private func persist() {
        let id = puzzle.id
        let descriptor = FetchDescriptor<PuzzleProgress>(predicate: #Predicate { $0.puzzleID == id })
        let existing = (try? context.fetch(descriptor))?.first
        if let existing {
            existing.enteredLetters = vm.encodedEntered()
            existing.revealedMask = vm.encodedRevealed()
            existing.checkedMask = vm.encodedChecked()
            existing.completed = vm.isComplete
            existing.elapsedSeconds = vm.elapsedSeconds
            existing.lastPlayedAt = .now
            if vm.isComplete && existing.solvedAt == nil { existing.solvedAt = .now }
        } else {
            let p = PuzzleProgress(puzzleID: puzzle.id,
                                   enteredLetters: vm.encodedEntered(),
                                   revealedMask: vm.encodedRevealed(),
                                   checkedMask: vm.encodedChecked(),
                                   completed: vm.isComplete,
                                   elapsedSeconds: vm.elapsedSeconds,
                                   solvedAt: vm.isComplete ? .now : nil)
            context.insert(p)
        }
        try? context.save()
    }

    private func recordDailyIfNeeded() {
        guard vm.isComplete, let key = dailyDateKey else { return }
        let descriptor = FetchDescriptor<DailyResult>(predicate: #Predicate { $0.dateKey == key })
        if let existing = (try? context.fetch(descriptor))?.first {
            existing.solved = true
            existing.elapsedSeconds = vm.elapsedSeconds
            existing.usedCheck = existing.usedCheck || vm.usedCheck
            existing.usedReveal = existing.usedReveal || vm.usedReveal
        } else {
            let r = DailyResult(dateKey: key,
                                puzzleID: puzzle.id,
                                solved: true,
                                elapsedSeconds: vm.elapsedSeconds,
                                usedCheck: vm.usedCheck,
                                usedReveal: vm.usedReveal,
                                difficultyRaw: puzzle.difficulty.rawValue)
            context.insert(r)
        }
        try? context.save()
    }

    // MARK: Error state

    private var errorState: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            EmptyStateView(symbol: "exclamationmark.triangle",
                           title: "This puzzle couldn't load",
                           message: "Its grid failed validation. Pick another puzzle from the archive.",
                           actionTitle: "Go back") { dismiss() }
        }
    }
}
