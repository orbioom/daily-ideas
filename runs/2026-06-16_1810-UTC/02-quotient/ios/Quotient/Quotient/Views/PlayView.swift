import SwiftUI

/// The active puzzle screen: status bar, grid, and number pad. Drives the
/// GameViewModel and reports persistence/result events upward.
struct PlayView: View {
    @Bindable var game: GameViewModel

    let haptics: Bool
    let highlightConflicts: Bool
    let highlightRelated: Bool
    let autoRemoveNotes: Bool
    let checkMistakes: Bool
    let showTimer: Bool
    let onPersist: () -> Void
    let onRecordResult: (Bool) -> Void
    let onNewPuzzle: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showWinSheet = false
    @State private var recordedResult = false

    var body: some View {
        Group {
            switch game.phase {
            case .failed(let message):
                errorState(message)
            default:
                playContent
            }
        }
        .onChange(of: game.phase) { _, newPhase in
            handlePhaseChange(newPhase)
        }
        .sheet(isPresented: $showWinSheet) {
            WinView(
                time: game.formattedTime,
                mistakes: game.mistakes,
                hintsUsed: game.hintsUsed,
                difficulty: game.difficulty,
                onNewPuzzle: {
                    showWinSheet = false
                    onNewPuzzle()
                },
                onClose: { showWinSheet = false }
            )
            .presentationDetents([.medium, .large])
        }
    }

    // MARK: Content

    private var playContent: some View {
        VStack(spacing: 16) {
            statusBar

            if game.hasReachedMistakeLimit {
                mistakeLimitBanner
            }

            PuzzleGridView(
                puzzle: game.puzzle ?? Puzzle(size: 0, solution: [], cages: []),
                cells: game.cells,
                selected: game.selectedCell,
                related: relatedCells,
                conflicts: game.conflicts,
                highlightRelated: highlightRelated,
                highlightConflicts: highlightConflicts,
                onTap: { index in
                    game.select(index)
                    Haptics.selection(enabled: haptics)
                }
            )
            .padding(.horizontal, 4)

            Spacer(minLength: 0)

            NumberPadView(
                size: game.size,
                notesMode: game.notesMode,
                canUndo: game.canUndo,
                valueCounts: valueCounts,
                onNumber: handleNumber,
                onErase: {
                    game.erase()
                    onPersist()
                },
                onToggleNotes: { game.notesMode.toggle() },
                onHint: handleHint,
                onUndo: {
                    game.undo()
                    onPersist()
                }
            )
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var statusBar: some View {
        HStack(spacing: 12) {
            statusChip(icon: game.difficulty.systemImage, text: game.difficulty.displayName)
            if showTimer {
                statusChip(icon: "clock", text: game.formattedTime)
                    .accessibilityLabel("Time \(game.formattedTime)")
            }
            Spacer()
            mistakeIndicator
        }
    }

    private func statusChip(icon: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.caption).accessibilityHidden(true)
            Text(text).font(.subheadline.weight(.medium))
        }
        .foregroundStyle(Theme.textSecondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(Theme.surface))
    }

    private var mistakeIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: "xmark.circle").font(.caption).accessibilityHidden(true)
            if game.mistakeLimit > 0 {
                Text("\(game.mistakes)/\(game.mistakeLimit)")
            } else {
                Text("\(game.mistakes)")
            }
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(game.mistakes > 0 ? Theme.conflict : Theme.textSecondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(Theme.surface))
        .accessibilityLabel("Mistakes \(game.mistakes)" + (game.mistakeLimit > 0 ? " of \(game.mistakeLimit)" : ""))
    }

    private var mistakeLimitBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Theme.conflict)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Mistake limit reached")
                    .font(.subheadline.weight(.semibold))
                Text("Keep going, or start a fresh puzzle.")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Button("New") { onNewPuzzle() }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.accent)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Theme.conflictFill))
        .accessibilityElement(children: .combine)
    }

    private func errorState(_ message: String) -> some View {
        EmptyStateView(
            systemImage: "exclamationmark.triangle",
            title: "Something went wrong",
            message: message,
            actionTitle: "New Puzzle",
            action: onNewPuzzle
        )
    }

    // MARK: Derived

    private var relatedCells: Set<Int> {
        guard let selected = game.selectedCell else { return [] }
        return game.relatedCells(to: selected)
    }

    private var valueCounts: [Int: Int] {
        var counts: [Int: Int] = [:]
        for cell in game.cells {
            if let v = cell.value { counts[v, default: 0] += 1 }
        }
        return counts
    }

    // MARK: Actions

    private func handleNumber(_ number: Int) {
        let feedback = game.enter(number, autoRemoveNotes: autoRemoveNotes, checkMistakes: checkMistakes)
        switch feedback {
        case .mistake: Haptics.warning(enabled: haptics)
        case .won:     Haptics.success(enabled: haptics)
        case .placed:  Haptics.light(enabled: haptics)
        case .none:    break
        }
        onPersist()
    }

    private func handleHint() {
        if game.useHint() {
            Haptics.light(enabled: haptics)
            onPersist()
        }
    }

    private func handlePhaseChange(_ phase: GameViewModel.Phase) {
        if phase == .won, !recordedResult {
            recordedResult = true
            onRecordResult(true)
            Haptics.success(enabled: haptics)
            withAnimation(reduceMotion ? nil : .spring(duration: 0.4)) {
                showWinSheet = true
            }
        }
        if case .playing = phase {
            recordedResult = false
        }
    }
}
