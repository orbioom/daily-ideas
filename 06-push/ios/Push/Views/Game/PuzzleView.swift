import SwiftUI
import SwiftData

struct PuzzleView: View {
    let level: SokobanLevel

    @State private var game: SokobanGame
    @State private var showWin: Bool = false
    @State private var showReset: Bool = false

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Query private var records: [PushRecord]
    @Query private var prefs: [PushPrefs]

    private var controlScheme: String { prefs.first?.controlScheme ?? "swipe" }
    private var hapticsEnabled: Bool { prefs.first?.hapticsEnabled ?? true }
    private var showPar: Bool { prefs.first?.showParMoves ?? true }
    private var autoAdvance: Bool { prefs.first?.autoAdvance ?? true }

    init(level: SokobanLevel) {
        self.level = level
        _game = State(initialValue: SokobanGame(level: level))
    }

    var body: some View {
        ZStack {
            PushTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header stats
                statsBar
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)

                // Grid
                GridView(game: game, onMove: handleMove)
                    .padding(.horizontal, 16)
                    .frame(maxHeight: .infinity)

                // D-pad (shown when selected or always as option)
                if controlScheme == "dpad" {
                    ControlPadView(
                        onMove: handleMove,
                        onUndo: handleUndo,
                        canUndo: game.canUndo
                    )
                    .padding(.vertical, 12)
                } else {
                    // Swipe mode — show undo button row only
                    swipeUndoBar
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                }
            }
        }
        .navigationTitle(level.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showReset = true
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .foregroundColor(PushTheme.accent)
                }
                .accessibilityLabel("Reset puzzle")
            }
        }
        .confirmationDialog("Reset Puzzle?", isPresented: $showReset, titleVisibility: .visible) {
            Button("Reset", role: .destructive) { game.reset() }
            Button("Cancel", role: .cancel) { }
        }
        .onChange(of: game.isSolved) { _, solved in
            if solved {
                triggerWin()
            }
        }
        .sheet(isPresented: $showWin) {
            WinSheet(
                level: level,
                moves: game.moves,
                pushes: game.pushes,
                parMoves: level.parMoves,
                stars: game.stars(parMoves: level.parMoves),
                onNextLevel: handleNextLevel,
                onRetry: { showWin = false; game.reset() }
            )
            .presentationDetents([.medium])
        }
    }

    // MARK: - Stats Bar

    private var statsBar: some View {
        HStack(spacing: 0) {
            statCell(value: "\(game.moves)", label: "Moves")
            Divider().frame(height: 32)
            statCell(value: "\(game.pushes)", label: "Pushes")
            if showPar {
                Divider().frame(height: 32)
                statCell(value: "\(level.parMoves)", label: "Par")
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
        )
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundColor(PushTheme.wall)
                .monospacedDigit()
            Text(label)
                .font(.system(.caption2, design: .rounded))
                .foregroundColor(PushTheme.wall.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }

    // MARK: - Swipe mode undo bar

    private var swipeUndoBar: some View {
        HStack(spacing: 12) {
            Text("Swipe to move")
                .font(.system(.caption, design: .rounded))
                .foregroundColor(PushTheme.wall.opacity(0.4))

            Spacer()

            Button {
                handleUndo()
            } label: {
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
            .accessibilityLabel("Undo move")
        }
    }

    // MARK: - Actions

    private func handleMove(_ direction: Direction) {
        let moved = game.move(direction)
        if moved && hapticsEnabled {
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
        // Save record
        saveRecord()
        // Announce to VoiceOver
        UIAccessibility.post(notification: .announcement, argument: "Puzzle solved! \(game.moves) moves, \(game.pushes) pushes.")

        if autoAdvance, let next = nextLevel {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // Auto-advance handled by WinSheet
                showWin = true
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showWin = true
            }
        }
    }

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

    private var nextLevel: SokobanLevel? {
        let sorted = allLevels.filter { $0.packId == level.packId }.sorted { $0.id < $1.id }
        if let idx = sorted.firstIndex(where: { $0.id == level.id }), idx + 1 < sorted.count {
            return sorted[idx + 1]
        }
        return nil
    }

    private func handleNextLevel() {
        showWin = false
        if let next = nextLevel {
            game = SokobanGame(level: next)
            // Navigation is handled by pop + NavigationLink in parent — here we just prepare
            // In a full app we'd push a new PuzzleView
        } else {
            dismiss()
        }
    }
}

// MARK: - Win Sheet

struct WinSheet: View {
    let level: SokobanLevel
    let moves: Int
    let pushes: Int
    let parMoves: Int
    let stars: Int
    let onNextLevel: () -> Void
    let onRetry: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            // Stars
            HStack(spacing: 10) {
                ForEach(1...3, id: \.self) { s in
                    Image(systemName: s <= stars ? "star.fill" : "star")
                        .font(.system(size: 36))
                        .foregroundColor(s <= stars ? .yellow : PushTheme.wall.opacity(0.2))
                        .scaleEffect(s <= stars ? 1.15 : 1.0)
                }
            }
            .padding(.top, 24)

            VStack(spacing: 6) {
                Text("Solved!")
                    .font(.system(.largeTitle, design: .rounded, weight: .black))
                    .foregroundColor(PushTheme.wall)
                Text(level.title)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(PushTheme.wall.opacity(0.5))
            }

            // Stats
            HStack(spacing: 0) {
                winStatCell(value: "\(moves)", label: "Moves", highlight: moves <= parMoves)
                Divider().frame(height: 40)
                winStatCell(value: "\(pushes)", label: "Pushes", highlight: false)
                Divider().frame(height: 40)
                winStatCell(value: "\(parMoves)", label: "Par", highlight: false)
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(PushTheme.floor)
            )
            .padding(.horizontal, 32)

            // Actions
            HStack(spacing: 12) {
                Button {
                    onRetry()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Retry")
                    }
                    .font(.system(.callout, design: .rounded, weight: .semibold))
                    .foregroundColor(PushTheme.wall)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 13)
                    .background(
                        Capsule()
                            .strokeBorder(PushTheme.floor, lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)

                Button {
                    onNextLevel()
                } label: {
                    HStack(spacing: 6) {
                        Text("Next Level")
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(.callout, design: .rounded, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 13)
                    .background(Capsule().fill(PushTheme.accent))
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .presentationDragIndicator(.visible)
    }

    private func winStatCell(value: String, label: String, highlight: Bool) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundColor(highlight ? PushTheme.boxOnTarget : PushTheme.wall)
                .monospacedDigit()
            Text(label)
                .font(.system(.caption2, design: .rounded))
                .foregroundColor(PushTheme.wall.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
    }
}

#Preview {
    PuzzleView(level: allLevels[0])
        .modelContainer(for: [PushRecord.self, PushPrefs.self, PushDailyResult.self, PushOnboarding.self], inMemory: true)
}
