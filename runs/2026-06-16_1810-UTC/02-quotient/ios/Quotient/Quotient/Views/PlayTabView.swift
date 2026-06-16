import SwiftUI
import SwiftData

/// Hosts the Play experience: resumes a saved game on launch, or shows the
/// new-puzzle picker. Owns the GameViewModel and the navigation stack.
struct PlayTabView: View {
    @Environment(\.modelContext) private var modelContext

    // Most recent non-daily saved game (for resume).
    @Query(
        filter: #Predicate<SavedGame> { !$0.isDaily },
        sort: \SavedGame.updatedAt, order: .reverse
    )
    private var savedGames: [SavedGame]

    @State private var game = GameViewModel()
    @State private var showingNewPuzzle = false
    @State private var showingSettings = false
    @State private var hasLoaded = false

    // Settings prefs used during play.
    @AppStorage("haptics") private var haptics = true
    @AppStorage("mistakeLimit") private var mistakeLimit = 0
    @AppStorage("highlightConflicts") private var highlightConflicts = true
    @AppStorage("highlightRelated") private var highlightRelated = true
    @AppStorage("autoRemoveNotes") private var autoRemoveNotes = true
    @AppStorage("checkMistakes") private var checkMistakes = true
    @AppStorage("showTimer") private var showTimer = true

    var body: some View {
        NavigationStack {
            Group {
                switch game.phase {
                case .idle:
                    idleContent
                case .generating:
                    GeneratingView()
                default:
                    PlayView(
                        game: game,
                        haptics: haptics,
                        highlightConflicts: highlightConflicts,
                        highlightRelated: highlightRelated,
                        autoRemoveNotes: autoRemoveNotes,
                        checkMistakes: checkMistakes,
                        showTimer: showTimer,
                        onPersist: persist,
                        onRecordResult: recordResult,
                        onNewPuzzle: { showingNewPuzzle = true }
                    )
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Quotient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingNewPuzzle = true
                    } label: {
                        Label("New Puzzle", systemImage: "plus.circle")
                    }
                    .accessibilityLabel("New puzzle")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showingNewPuzzle) {
                NewPuzzleView { difficulty in
                    showingNewPuzzle = false
                    Task { await startNew(difficulty: difficulty) }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
        .task {
            guard !hasLoaded else { return }
            hasLoaded = true
            // Resume the most recent unfinished saved game, if any.
            if let resumable = savedGames.first(where: { !$0.isCompleted }) {
                game.resume(from: resumable, mistakeLimit: mistakeLimit)
            }
        }
    }

    private var idleContent: some View {
        EmptyStateView(
            systemImage: "square.grid.3x3",
            title: "Ready to play",
            message: "Start a new arithmetic puzzle. Fill the grid so every row and column has each number once, and every cage hits its target.",
            actionTitle: "New Puzzle",
            action: { showingNewPuzzle = true }
        )
    }

    // MARK: - Actions

    private func startNew(difficulty: Difficulty) async {
        let seed = SplitMix64.seed(forDateKey: "free-\(UUID().uuidString)")
        await game.startNew(
            difficulty: difficulty,
            isDaily: false,
            dateKey: "",
            seed: seed,
            mistakeLimit: mistakeLimit
        )
        persist()
    }

    /// Persists the current game state to SwiftData (insert or update).
    private func persist() {
        guard let puzzle = game.puzzle, game.phase != .generating else { return }
        let id = game.savedGameID
        // Fetch directly from the context so we never insert a duplicate even if
        // the reactive @Query hasn't refreshed between rapid persist() calls.
        let descriptor = FetchDescriptor<SavedGame>(predicate: #Predicate { $0.id == id })
        let existing = (try? modelContext.fetch(descriptor))?.first
        let isCompleted = (game.phase == .won)

        if let existing {
            existing.stateData = PuzzleService.encode(game.cells)
            existing.elapsedSeconds = game.elapsedSeconds
            existing.mistakes = game.mistakes
            existing.hintsUsed = game.hintsUsed
            existing.isCompleted = isCompleted
            existing.updatedAt = Date()
        } else {
            let saved = SavedGame(
                id: id,
                puzzleData: PuzzleService.encode(puzzle),
                stateData: PuzzleService.encode(game.cells),
                size: puzzle.size,
                difficulty: game.difficulty,
                elapsedSeconds: game.elapsedSeconds,
                mistakes: game.mistakes,
                hintsUsed: game.hintsUsed,
                isDaily: false,
                dateKey: "",
                isCompleted: isCompleted
            )
            modelContext.insert(saved)
        }
        try? modelContext.save()
    }

    /// Records a finished game into the stats store (called once on win/loss).
    private func recordResult(won: Bool) {
        guard let puzzle = game.puzzle else { return }
        let result = PuzzleResult(
            size: puzzle.size,
            difficulty: game.difficulty,
            durationSeconds: game.elapsedSeconds,
            mistakes: game.mistakes,
            hintsUsed: game.hintsUsed,
            won: won,
            isDaily: false,
            dateKey: ""
        )
        modelContext.insert(result)
        persist()
        try? modelContext.save()
    }
}
