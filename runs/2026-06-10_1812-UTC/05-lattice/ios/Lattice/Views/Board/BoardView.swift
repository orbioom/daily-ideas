import SwiftUI
import SwiftData

struct BoardView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var game: SavedGame
    @Query private var allStats: [GameStats]
    @Query private var allDaily: [DailyResult]

    @AppStorage("highlightConflicts") private var highlightConflicts = true
    @AppStorage("highlightSame") private var highlightSame = true
    @AppStorage("autoRemoveNotes") private var autoRemoveNotes = true
    @AppStorage("limitMistakes") private var limitMistakes = true
    @AppStorage("showRemaining") private var showRemaining = true

    @State private var selected: Int?
    @State private var notesMode = false
    @State private var paused = false
    @State private var outcome: Outcome?
    @State private var undoStack: [Snapshot] = []

    private struct Snapshot { let index: Int; let value: Int; let note: Int }
    private enum Outcome { case won, lost }

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var conflicts: Set<Int> {
        highlightConflicts ? SudokuEngine.conflicts(in: game.current) : []
    }
    private var selectedValue: Int? {
        guard let s = selected, game.current[s] != 0 else { return nil }
        return game.current[s]
    }

    var body: some View {
        ZStack {
            Brand.pageBackground
            VStack(spacing: 14) {
                statusBar
                SudokuGridView(
                    current: game.current, givens: game.givens, notes: game.notes,
                    selected: selected, conflicts: conflicts,
                    highlightValue: highlightSame ? selectedValue : nil,
                    onTap: { selected = $0 }
                )
                .padding(.horizontal, 4)
                controlRow
                numberPad
            }
            .padding(16)
            .disabled(paused || outcome != nil)
            .blur(radius: paused ? 8 : 0)

            if paused { pauseOverlay }
            if let outcome { outcomeOverlay(outcome) }
        }
        .navigationTitle(game.isDaily ? "Daily" : game.difficulty.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { withAnimation(Brand.ease()) { paused.toggle() } } label: {
                    Image(systemName: paused ? "play.fill" : "pause.fill")
                }
                .disabled(outcome != nil)
                .accessibilityLabel(paused ? "Resume" : "Pause")
            }
        }
        .onReceive(timer) { _ in
            guard !paused, outcome == nil, !game.isComplete else { return }
            game.elapsed += 1
        }
        .onDisappear { try? context.save() }
        .onAppear { if game.isComplete { outcome = .won } }
    }

    private var statusBar: some View {
        HStack {
            label("Time", timeString(game.elapsed), "clock")
            Spacer()
            if limitMistakes {
                label("Mistakes", "\(game.mistakes)/3", "xmark.circle",
                      tint: game.mistakes > 0 ? Brand.danger : Brand.text2)
            }
            Spacer()
            label("Hints", "\(game.hintsUsed)", "lightbulb")
        }
    }

    private func label(_ title: String, _ value: String, _ icon: String, tint: Color = Brand.text) -> some View {
        VStack(spacing: 2) {
            Text(title).font(Brand.mono(10)).foregroundStyle(Brand.text3)
            Text(value).font(Brand.mono(16, weight: .semibold)).foregroundStyle(tint)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(value)")
    }

    private var controlRow: some View {
        HStack(spacing: 10) {
            controlButton("arrow.uturn.backward", "Undo", enabled: !undoStack.isEmpty) { undo() }
            controlButton("eraser", "Erase", enabled: canEdit) { erase() }
            controlButton(notesMode ? "pencil.tip.crop.circle.fill" : "pencil.tip.crop.circle",
                          "Notes", active: notesMode) { notesMode.toggle(); Haptics.selection() }
            controlButton("lightbulb", "Hint", enabled: hasEmpty) { hint() }
        }
    }

    private func controlButton(_ icon: String, _ label: String, enabled: Bool = true,
                               active: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: { if enabled { action() } }) {
            VStack(spacing: 5) {
                Image(systemName: icon).font(.title3)
                Text(label).font(Brand.mono(10))
            }
            .foregroundStyle(active ? Brand.magic : (enabled ? Brand.text : Brand.text3.opacity(0.5)))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(active ? Brand.magic.opacity(0.6) : Brand.glassStroke.opacity(0.4), lineWidth: 1))
        }
        .disabled(!enabled)
        .accessibilityLabel(label)
        .accessibilityAddTraits(active ? .isSelected : [])
    }

    private var numberPad: some View {
        HStack(spacing: 8) {
            ForEach(1...9, id: \.self) { n in
                let remaining = 9 - game.current.filter { $0 == n }.count
                Button { input(n) } label: {
                    VStack(spacing: 2) {
                        Text("\(n)").font(.system(size: 26, weight: .semibold, design: .rounded))
                            .foregroundStyle(Brand.text)
                        if showRemaining {
                            Text("\(max(0, remaining))").font(Brand.mono(9)).foregroundStyle(Brand.text3)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Brand.glassStroke.opacity(0.4), lineWidth: 1))
                    .opacity(remaining <= 0 && !notesMode ? 0.4 : 1)
                }
                .disabled(!canEdit)
                .accessibilityLabel("Enter \(n), \(max(0, remaining)) remaining")
            }
        }
    }

    // MARK: - Overlays

    private var pauseOverlay: some View {
        VStack(spacing: 18) {
            Image(systemName: "pause.circle.fill").font(.system(size: 56)).foregroundStyle(Brand.text2)
            Text("Paused").font(.title2.weight(.semibold)).foregroundStyle(Brand.text)
            Button("Resume") { withAnimation(Brand.ease()) { paused = false } }
                .buttonStyle(InkButtonStyle()).frame(maxWidth: 220)
        }
    }

    private func outcomeOverlay(_ outcome: Outcome) -> some View {
        VStack(spacing: 16) {
            Image(systemName: outcome == .won ? "checkmark.seal.fill" : "xmark.octagon.fill")
                .font(.system(size: 60))
                .foregroundStyle(outcome == .won ? Brand.live : Brand.danger)
            Text(outcome == .won ? "Solved!" : "Out of mistakes")
                .font(.title.weight(.bold)).foregroundStyle(Brand.text)
            if outcome == .won {
                Text("\(game.difficulty.rawValue) · \(timeString(game.elapsed))")
                    .font(Brand.mono(15)).foregroundStyle(Brand.text2)
            } else {
                Text("That's 3 mistakes. Try resetting the board.")
                    .font(.subheadline).foregroundStyle(Brand.text2).multilineTextAlignment(.center)
            }
            VStack(spacing: 10) {
                if outcome == .lost {
                    Button("Reset board") { resetBoard() }
                        .buttonStyle(InkButtonStyle())
                }
                Button("Back to menu") { dismiss() }
                    .buttonStyle(GlassButtonStyle())
            }
            .frame(maxWidth: 260)
        }
        .padding(28)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
        .padding(24)
    }

    // MARK: - Game logic

    private var canEdit: Bool {
        guard let s = selected else { return false }
        return !game.isGiven(s)
    }
    private var hasEmpty: Bool { game.current.contains(0) }

    private func input(_ value: Int) {
        guard let index = selected, !game.isGiven(index) else { return }
        if notesMode {
            guard game.current[index] == 0 else { return }
            undoStack.append(Snapshot(index: index, value: game.current[index], note: game.notes[index]))
            game.notes[index] ^= (1 << (value - 1))
            Haptics.selection()
        } else {
            undoStack.append(Snapshot(index: index, value: game.current[index], note: game.notes[index]))
            game.current[index] = value
            game.notes[index] = 0
            if autoRemoveNotes {
                for p in SudokuEngine.peers(of: index) {
                    game.notes[p] &= ~(1 << (value - 1))
                }
            }
            if value != game.solution[index] {
                game.mistakes += 1
                Haptics.warning()
                if limitMistakes && game.mistakes >= 3 {
                    game.updatedAt = .now
                    GameService.recordLoss(game, context: context, allStats: allStats)
                    withAnimation(Brand.ease()) { outcome = .lost }
                    return
                }
            } else {
                Haptics.tap()
            }
            checkWin()
        }
        game.updatedAt = .now
        try? context.save()
    }

    private func erase() {
        guard let index = selected, !game.isGiven(index) else { return }
        undoStack.append(Snapshot(index: index, value: game.current[index], note: game.notes[index]))
        game.current[index] = 0
        game.notes[index] = 0
        try? context.save()
    }

    private func hint() {
        let index = selected.flatMap { game.current[$0] == 0 && !game.isGiven($0) ? $0 : nil }
            ?? game.current.firstIndex(of: 0)
        guard let target = index else { return }
        undoStack.append(Snapshot(index: target, value: game.current[target], note: game.notes[target]))
        game.current[target] = game.solution[target]
        game.notes[target] = 0
        game.hintsUsed += 1
        selected = target
        Haptics.success()
        checkWin()
        try? context.save()
    }

    private func undo() {
        guard let last = undoStack.popLast() else { return }
        game.current[last.index] = last.value
        game.notes[last.index] = last.note
        try? context.save()
        Haptics.tap()
    }

    private func checkWin() {
        guard game.current == game.solution else { return }
        game.isComplete = true
        game.updatedAt = .now
        GameService.recordCompletion(game, context: context, allStats: allStats, allDaily: allDaily)
        Haptics.success()
        withAnimation(Brand.ease()) { outcome = .won }
    }

    private func resetBoard() {
        game.current = game.givens
        game.notes = Array(repeating: 0, count: 81)
        game.mistakes = 0
        game.elapsed = 0
        game.hintsUsed = 0
        game.isComplete = false
        undoStack.removeAll()
        try? context.save()
        withAnimation(Brand.ease()) { outcome = nil }
    }

    private func timeString(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
