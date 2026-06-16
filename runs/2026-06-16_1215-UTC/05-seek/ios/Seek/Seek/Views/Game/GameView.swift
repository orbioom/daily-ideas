import SwiftUI
import SwiftData

/// The full puzzle-playing screen: grid, word list, timer, hints, pause, win overlay.
struct GameView: View {
    let puzzle: Puzzle
    let pack: WordPack
    let isDaily: Bool
    let dailyDateKey: String?

    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var pro: ProStore
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var allProgress: [PuzzleProgress]

    @State private var model: GameViewModel
    @State private var showWin = false
    @State private var showPaywall = false
    @State private var didStart = false

    init(puzzle: Puzzle, pack: WordPack, isDaily: Bool, dailyDateKey: String?) {
        self.puzzle = puzzle
        self.pack = pack
        self.isDaily = isDaily
        self.dailyDateKey = dailyDateKey
        _model = State(initialValue: GameViewModel(
            puzzle: puzzle,
            packName: pack.name,
            words: pack.words,
            difficulty: puzzle.difficulty,
            isDaily: isDaily,
            dailyDateKey: dailyDateKey,
            allowDiagonals: true,
            allowReverse: true,
            isPro: false
        ))
    }

    private var highlightColor: Color { settings.highlightTheme.color }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            if model.total == 0 {
                EmptyStateView(
                    icon: "exclamationmark.triangle",
                    title: "Couldn't build this puzzle",
                    message: "This pack didn't yield enough words for the grid. Try another puzzle.",
                    actionTitle: "Go back",
                    action: { dismiss() }
                )
            } else {
                content
            }

            if model.isPaused {
                pauseOverlay
            }

            if showWin {
                WinOverlay(
                    title: isDaily ? "Daily Solved!" : "Solved!",
                    timeSec: model.elapsedSec,
                    bestSec: model.bestTimeSec,
                    isNewBest: model.didSetNewBest,
                    shareText: shareText,
                    onNext: isDaily ? nil : { goNext() },
                    onClose: { dismiss() }
                )
                .transition(.opacity)
            }
        }
        .navigationTitle(isDaily ? "Daily" : puzzle.title(packName: pack.name))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    model.togglePause()
                } label: {
                    Image(systemName: model.isPaused ? "play.fill" : "pause.fill")
                }
                .disabled(model.isComplete)
                .accessibilityLabel(model.isPaused ? "Resume" : "Pause")
            }
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .onAppear { startup() }
        .onDisappear {
            model.stopTimer()
            model.persist(context: context)
        }
        .onChange(of: model.isComplete) { _, complete in
            if complete {
                model.persist(context: context)
                withAnimation { showWin = true }
            }
        }
    }

    // MARK: Content

    private var content: some View {
        VStack(spacing: 0) {
            statusBar
                .padding(.horizontal, 16)
                .padding(.top, 8)

            ScrollView {
                VStack(spacing: 16) {
                    WordGridView(
                        board: model.board,
                        highlightColor: highlightColor,
                        selectionPath: model.selectionPath,
                        foundCells: foundCells,
                        hintCell: model.hintCell,
                        reduceMotion: reduceMotion,
                        onDragChange: { start, current in
                            model.updateSelection(start: start, current: current)
                        },
                        onDragEnd: {
                            let before = model.foundCount
                            model.commitSelection(hapticsEnabled: settings.hapticsEnabled)
                            if model.foundCount == before {
                                Haptics.impact(.rigid, enabled: settings.hapticsEnabled)
                            }
                        }
                    )
                    .padding(.horizontal, 16)
                    .allowsHitTesting(!model.isPaused && !model.isComplete)

                    SeekCard {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Find \(model.foundCount)/\(model.total)")
                                    .font(Theme.rounded(15, .semibold))
                                    .foregroundStyle(Theme.ink)
                                Spacer()
                                hintButton
                            }
                            WordListView(
                                words: model.allWords,
                                found: model.foundWords,
                                highlightColor: highlightColor,
                                lastFoundFlash: model.lastFoundFlash,
                                reduceMotion: reduceMotion
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
        }
    }

    private var statusBar: some View {
        HStack(spacing: 12) {
            pill(icon: "clock", text: Formatters.clock(model.elapsedSec))
                .accessibilityLabel("Elapsed time \(Formatters.clock(model.elapsedSec))")
            pill(icon: model.puzzle.difficulty.symbolName, text: model.puzzle.difficulty.rawValue)
            Spacer()
            ProgressView(value: model.progress)
                .frame(width: 90)
                .tint(highlightColor)
        }
    }

    private func pill(icon: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
            Text(text)
                .font(Theme.rounded(14, .semibold))
        }
        .foregroundStyle(Theme.inkSoft)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(Theme.surfaceAlt))
    }

    private var hintButton: some View {
        Button {
            if model.canUseHint {
                model.useHint(hapticsEnabled: settings.hapticsEnabled)
            } else if !pro.isPro {
                showPaywall = true
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "lightbulb.fill")
                Text(hintLabel)
            }
            .font(Theme.rounded(14, .semibold))
            .foregroundStyle(model.canUseHint ? Theme.accent : Theme.inkSoft)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(Theme.surfaceAlt))
        }
        .disabled(model.isComplete)
        .accessibilityLabel("Hint")
        .accessibilityHint(model.canUseHint ? "Reveals the first letter of an unfound word" : "Unlock Pro for unlimited hints")
    }

    private var hintLabel: String {
        if pro.isPro { return "Hint" }
        return "Hint \(model.hintsRemaining)"
    }

    private var pauseOverlay: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)
                Text("Paused")
                    .font(Theme.rounded(24, .bold))
                    .foregroundStyle(.white)
                PrimaryButton(title: "Resume", systemImage: "play.fill") {
                    model.togglePause()
                }
                .frame(maxWidth: 240)
            }
        }
        .transition(.opacity)
    }

    // MARK: Helpers

    private var foundCells: Set<GridPoint> {
        var cells = Set<GridPoint>()
        for word in model.foundWords {
            if let path = model.board.placements[word] {
                cells.formUnion(path)
            }
        }
        return cells
    }

    private var shareText: String {
        let label = isDaily ? "the Seek Daily" : puzzle.title(packName: pack.name)
        return "I solved \(label) in \(Formatters.clock(model.elapsedSec)) on Seek 🔍"
    }

    private func startup() {
        guard !didStart else { return }
        didStart = true
        model.applyPro(pro.isPro)
        model.restore(from: allProgress.first { $0.puzzleKey == puzzle.key })
        if model.isComplete {
            showWin = true
        } else {
            model.start()
        }
    }

    private func goNext() {
        // Return to the puzzle list, where the next (now-unlocked) puzzle is one tap away.
        dismiss()
    }
}
