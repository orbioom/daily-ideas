import SwiftUI
import SwiftData

/// Full-screen game view for a single Sokoban level.
/// Hosts the grid, move/push counters, directional controls, and undo.
/// Shows VictoryView as a full-screen overlay when the puzzle is solved.
struct SokobanView: View {
    let level: SokobanLevel

    @State private var game: SokobanGame
    @State private var showVictory: Bool = false
    @State private var showResetConfirm: Bool = false
    @State private var playerFacingRight: Bool = true

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Query private var records: [PushRecord]
    @Query private var prefsQuery: [PushPrefs]

    private var prefs: PushPrefs? { prefsQuery.first }
    private var controlScheme: String { prefs?.controlScheme ?? "swipe" }
    private var hapticsEnabled: Bool { prefs?.hapticsEnabled ?? true }
    private var showPar: Bool { prefs?.showParMoves ?? true }
    private var autoAdvance: Bool { prefs?.autoAdvance ?? true }

    init(level: SokobanLevel) {
        self.level = level
        _game = State(initialValue: SokobanGame(level: level))
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            PushTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Level title + number
                levelHeader
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 4)

                // Move / push / par counters
                countersBar
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)

                // Puzzle grid — takes all available vertical space
                GridView(game: game, onMove: handleMove)
                    .padding(.horizontal, 16)
                    .frame(maxHeight: .infinity)

                // Controls
                if controlScheme == "dpad" {
                    ControlPadView(
                        onMove: handleMove,
                        onUndo: handleUndo,
                        canUndo: game.canUndo
                    )
                    .padding(.horizontal, 40)
                    .padding(.vertical, 14)
                } else {
                    swipeHintBar
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                }
            }

            // Victory overlay — slides up from bottom
            if showVictory {
                VictoryView(
                    level: level,
                    moves: game.moves,
                    pushes: game.pushes,
                    stars: game.stars(parMoves: level.parMoves),
                    parMoves: level.parMoves,
                    onNextLevel: handleNextLevel,
                    onReplay: handleReplay,
                    onBack: { dismiss() }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(10)
            }
        }
        .navigationTitle(level.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(showVictory)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !showVictory {
                    Button {
                        showResetConfirm = true
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundColor(PushTheme.accent)
                    }
                    .accessibilityLabel("Reset puzzle")
                }
            }
        }
        .confirmationDialog("Reset Puzzle?", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("Reset", role: .destructive) { game.reset() }
            Button("Cancel", role: .cancel) { }
        }
        .onChange(of: game.isSolved) { _, solved in
            if solved { triggerWin() }
        }
        .animation(reduceMotion ? nil : .spring(duration: 0.45), value: showVictory)
    }

    // MARK: - Level Header

    private var levelHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(level.title)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundColor(PushTheme.wall)
                Text("Level \(level.id)")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(PushTheme.wall.opacity(0.45))
            }
            Spacer()
            // Pack color badge
            Text(packName(for: level.packId))
                .font(.system(.caption2, design: .rounded, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(PushTheme.packColor(level.packId))
                )
        }
    }

    // MARK: - Counters Bar

    private var countersBar: some View {
        HStack(spacing: 0) {
            counterCell(
                value: "\(game.moves)",
                label: "Moves",
                icon: "arrow.up.arrow.down",
                highlight: false
            )
            Divider().frame(height: 36).opacity(0.4)
            counterCell(
                value: "\(game.pushes)",
                label: "Pushes",
                icon: "arrow.right.square",
                highlight: false
            )
            if showPar {
                Divider().frame(height: 36).opacity(0.4)
                counterCell(
                    value: "\(level.parMoves)",
                    label: "Par",
                    icon: "star",
                    highlight: game.moves <= level.parMoves && game.moves > 0
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.07), radius: 6, y: 2)
        )
    }

    private func counterCell(value: String, label: String, icon: String, highlight: Bool) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundColor(highlight ? PushTheme.boxOnTarget : PushTheme.wall)
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.spring(duration: 0.25), value: value)
            Text(label)
                .font(.system(.caption2, design: .rounded))
                .foregroundColor(PushTheme.wall.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }

    // MARK: - Swipe Hint + Undo Bar

    private var swipeHintBar: some View {
        HStack(spacing: 12) {
            Label("Swipe to move", systemImage: "hand.draw")
                .font(.system(.caption, design: .rounded))
                .foregroundColor(PushTheme.wall.opacity(0.35))

            Spacer()

            Button(action: handleUndo) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.uturn.backward")
                    Text("Undo")
                }
                .font(.system(.callout, design: .rounded, weight: .semibold))
                .foregroundColor(game.canUndo ? PushTheme.accent : PushTheme.wall.opacity(0.25))
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(game.canUndo ? PushTheme.accent.opacity(0.12) : PushTheme.floor)
                )
            }
            .disabled(!game.canUndo)
            .accessibilityLabel("Undo last move")
        }
    }

    // MARK: - Actions

    private func handleMove(_ direction: Direction) {
        let moved = game.move(direction)
        guard moved else { return }

        // Update facing direction for cosmetics
        if direction == .right { playerFacingRight = true }
        if direction == .left  { playerFacingRight = false }

        if hapticsEnabled {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    private func handleUndo() {
        game.undo()
        if hapticsEnabled {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
    }

    private func triggerWin() {
        if hapticsEnabled {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        saveRecord()
        UIAccessibility.post(
            notification: .announcement,
            argument: "Puzzle solved! \(game.moves) moves, \(game.pushes) pushes."
        )
        let delay: TimeInterval = autoAdvance ? 0.5 : 0.3
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation { showVictory = true }
        }
    }

    private func handleReplay() {
        withAnimation { showVictory = false }
        game.reset()
    }

    private func handleNextLevel() {
        withAnimation { showVictory = false }
        if let next = nextLevel {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                game = SokobanGame(level: next)
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                dismiss()
            }
        }
    }

    // MARK: - Persistence

    private func saveRecord() {
        if let existing = records.first(where: { $0.levelId == level.id }) {
            if game.moves < existing.bestMoves {
                existing.bestMoves = game.moves
                existing.bestPushes = game.pushes
                existing.completedAt = Date()
            }
        } else {
            let record = PushRecord(
                levelId: level.id,
                packId: level.packId,
                bestMoves: game.moves,
                bestPushes: game.pushes
            )
            modelContext.insert(record)
        }
        try? modelContext.save()
    }

    // MARK: - Helpers

    private var nextLevel: SokobanLevel? {
        let packLevels = allLevels
            .filter { $0.packId == level.packId }
            .sorted { $0.id < $1.id }
        guard let idx = packLevels.firstIndex(where: { $0.id == level.id }),
              idx + 1 < packLevels.count else { return nil }
        return packLevels[idx + 1]
    }

    private func packName(for packId: Int) -> String {
        allPacks.first(where: { $0.id == packId })?.name ?? "Pack \(packId)"
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SokobanView(level: allLevels[0])
    }
    .modelContainer(
        for: [PushRecord.self, PushPrefs.self, PushDailyResult.self, PushOnboarding.self],
        inMemory: true
    )
}
