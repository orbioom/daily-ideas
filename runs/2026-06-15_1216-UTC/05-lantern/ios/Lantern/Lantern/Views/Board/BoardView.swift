import SwiftUI
import SwiftData

/// The game screen: renders the layered board, toolbar, timer/counters, and the
/// win / dead-end / pause sheets. Owns a `GameViewModel`.
struct BoardView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("isPro") private var isPro = false

    @StateObject private var vm: GameViewModel

    @State private var showRestartConfirm = false
    @State private var paywall: PaywallReason?
    @State private var recordedOutcome = false

    init(viewModel: GameViewModel) {
        _vm = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                statusBar
                boardArea
                toolbar
            }
        }
        .navigationTitle(vm.layout.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { vm.pause() } label: {
                    Image(systemName: "pause.circle")
                }
                .disabled(vm.phase != .playing)
                .accessibilityLabel("Pause")
            }
        }
        .onAppear { startIfNeeded() }
        .onDisappear { persist() }
        .onChange(of: vm.phase) { _, newPhase in
            handlePhaseChange(newPhase)
        }
        .sheet(item: $paywall) { reason in
            PaywallView(reason: reason)
        }
        .alert("Restart this board?", isPresented: $showRestartConfirm) {
            Button("Restart", role: .destructive) { doRestart() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your current progress on this board will be lost.")
        }
        .overlay { overlays }
    }

    // MARK: Status bar

    private var statusBar: some View {
        HStack(spacing: 14) {
            stat(icon: "clock", value: TimeFormat.clock(vm.elapsedSec), label: "Time")
            Divider().frame(height: 26)
            stat(icon: "arrow.triangle.2.circlepath", value: "\(vm.moves)", label: "Moves")
            Divider().frame(height: 26)
            stat(icon: "square.stack.3d.up", value: "\(vm.remainingCount)", label: "Tiles")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Theme.surface)
        .overlay(Rectangle().fill(Theme.hairline).frame(height: 1), alignment: .bottom)
    }

    private func stat(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.caption).foregroundStyle(Theme.accent)
                Text(value).font(Theme.rounded(17, .semibold)).foregroundStyle(Theme.ink)
                    .monospacedDigit()
            }
            Text(label).font(Theme.rounded(11)).foregroundStyle(Theme.inkFaint)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    // MARK: Board area

    private var boardArea: some View {
        GeometryReader { geo in
            let geom = BoardGeometry(slots: vm.layout.slots, canvas: geo.size)
            ZStack(alignment: .topLeading) {
                if vm.phase == .generating {
                    generatingView
                        .frame(width: geo.size.width, height: geo.size.height)
                } else {
                    tileLayer(geom: geom)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .padding(8)
    }

    private func tileLayer(geom: BoardGeometry) -> some View {
        let ordered = geom.sortedDrawOrder(vm.board.tiles.filter { !$0.removed })
        return ZStack(alignment: .topLeading) {
            ForEach(ordered) { placed in
                let slot = vm.layout.slots[safe: placed.slotIndex]
                if let slot {
                    let frame = geom.frame(for: slot)
                    tile(placed, frame: frame)
                        .transition(reduceMotion ? .opacity : .scale(scale: 1.18).combined(with: .opacity))
                }
            }
        }
        // Animate insert/removal of tiles (match clears, undo restores, shuffle).
        .animation(reduceMotion ? nil : .easeOut(duration: 0.26), value: vm.remainingCount)
    }

    private func tile(_ placed: PlacedTile, frame: CGRect) -> some View {
        let isFree = vm.freeIDs.contains(placed.id)
        let isSelected = vm.selectedID == placed.id
        let isHinted = vm.hintPair?.0 == placed.id || vm.hintPair?.1 == placed.id

        return TileView(
            placed: placed,
            size: frame.size,
            isSelected: isSelected,
            isHinted: isHinted,
            isFree: isFree,
            showFreeHint: settings.showFreeHints,
            themeTint: themeTint
        )
        .position(x: frame.midX, y: frame.midY)
        .onTapGesture { handleTap(placed.id) }
        .accessibilityElement()
        .accessibilityLabel(placed.face.spokenName)
        .accessibilityValue(isFree ? "Free" : "Blocked")
        .accessibilityHint(isFree ? "Double tap to select. Match two identical free tiles to clear them." : "Covered or boxed in; not yet playable.")
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }

    private var themeTint: Color {
        settings.tileTheme(isPro: isPro).backColor
    }

    private var generatingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
                .tint(Theme.accent)
            Text("Lighting the lanterns…")
                .font(Theme.serif(18, .semibold))
                .foregroundStyle(Theme.inkSoft)
            Text("Building a board you can always finish.")
                .font(Theme.rounded(13))
                .foregroundStyle(Theme.inkFaint)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Generating a solvable board")
    }

    // MARK: Toolbar

    private var toolbar: some View {
        HStack(spacing: 8) {
            toolButton("lightbulb", "Hint", disabled: vm.phase != .playing) { useHint() }
            toolButton("arrow.uturn.backward", "Undo", disabled: !vm.canUndo) { _ = vm.undo() }
            toolButton("shuffle", "Shuffle", disabled: !(vm.phase == .playing || vm.phase == .deadEnd)) { useShuffle() }
            toolButton("arrow.clockwise", "Restart", disabled: vm.phase == .generating) { requestRestart() }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Theme.surface)
        .overlay(Rectangle().fill(Theme.hairline).frame(height: 1), alignment: .top)
    }

    private func toolButton(_ icon: String, _ label: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 18, weight: .medium))
                Text(label).font(Theme.rounded(11, .medium))
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(disabled ? Theme.inkFaint : Theme.accent)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                    .fill(disabled ? Color.clear : Theme.accentSoft.opacity(0.5))
            )
        }
        .disabled(disabled)
        .accessibilityLabel(label)
    }

    // MARK: Overlays (win / dead-end / pause)

    @ViewBuilder
    private var overlays: some View {
        switch vm.phase {
        case .won:
            GameResultOverlay(
                kind: .won,
                elapsedSec: vm.elapsedSec,
                moves: vm.moves,
                onPrimary: { dismiss() },
                onSecondary: { doRestart() }
            )
        case .deadEnd:
            GameResultOverlay(
                kind: .deadEnd(canShuffle: canShuffleMore),
                elapsedSec: vm.elapsedSec,
                moves: vm.moves,
                onPrimary: { useShuffleFromDeadEnd() },
                onSecondary: { doRestart() }
            )
        case .paused:
            PauseOverlay(
                onResume: { vm.resume() },
                onRestart: { requestRestart() },
                onExit: { saveAndExit() }
            )
        default:
            EmptyView()
        }
    }

    // MARK: Actions

    private func startIfNeeded() {
        if vm.phase == .generating { vm.generate() }
    }

    private func handleTap(_ id: Int) {
        let outcome = vm.tap(id)
        switch outcome {
        case .selected, .mismatch:
            Haptics.select(enabled: settings.hapticsEnabled)
        case .matched:
            Haptics.match(enabled: settings.hapticsEnabled)
        case .deselected, .ignored:
            break
        }
    }

    private func useHint() {
        guard let limit = Pro.hintLimit(isPro: isPro) else {
            _ = vm.hint(); return
        }
        if vm.hintsUsed >= limit {
            paywall = .outOfHints
            Haptics.warn(enabled: settings.hapticsEnabled)
            return
        }
        if !vm.hint() {
            // No hint available right now.
            Haptics.warn(enabled: settings.hapticsEnabled)
        }
    }

    private var canShuffleMore: Bool {
        guard let limit = Pro.shuffleLimit(isPro: isPro) else { return true }
        return vm.shufflesUsed < limit
    }

    private func useShuffle() {
        if !canShuffleMore {
            paywall = .outOfShuffles
            Haptics.warn(enabled: settings.hapticsEnabled)
            return
        }
        _ = vm.shuffle()
    }

    private func useShuffleFromDeadEnd() {
        if !canShuffleMore {
            paywall = .outOfShuffles
            return
        }
        _ = vm.shuffle()
    }

    private func requestRestart() {
        if settings.confirmOnRestart {
            showRestartConfirm = true
        } else {
            doRestart()
        }
    }

    private func doRestart() {
        recordedOutcome = false
        vm.restart()
    }

    private func handlePhaseChange(_ phase: GameViewModel.Phase) {
        switch phase {
        case .won:
            Haptics.win(enabled: settings.hapticsEnabled)
            recordOutcome(won: true)
            clearSavedGame()
        case .deadEnd:
            Haptics.warn(enabled: settings.hapticsEnabled)
        default:
            break
        }
    }

    // MARK: Persistence

    private func persist() {
        // Save in-progress games (not finished ones) for resume-on-relaunch.
        guard vm.phase == .playing || vm.phase == .paused else { return }
        guard let data = vm.snapshot().encoded() else { return }
        clearSavedGame()
        let saved = SavedGame(layout: vm.layout, stateData: data, isDaily: vm.isDaily)
        modelContext.insert(saved)
        try? modelContext.save()
    }

    private func saveAndExit() {
        persist()
        dismiss()
    }

    private func clearSavedGame() {
        let descriptor = FetchDescriptor<SavedGame>()
        if let existing = try? modelContext.fetch(descriptor) {
            for game in existing { modelContext.delete(game) }
            try? modelContext.save()
        }
    }

    private func recordOutcome(won: Bool) {
        guard !recordedOutcome else { return }
        recordedOutcome = true
        let record = GameRecord(layout: vm.layout, won: won, durationSec: vm.elapsedSec, moves: vm.moves)
        modelContext.insert(record)
        if vm.isDaily, let key = vm.dailyDateKey {
            // Record (or update) the daily result.
            let descriptor = FetchDescriptor<DailyResult>(
                predicate: #Predicate { $0.dateKey == key }
            )
            if let existing = try? modelContext.fetch(descriptor), let first = existing.first {
                first.won = first.won || won
                if won { first.durationSec = vm.elapsedSec }
            } else {
                let daily = DailyResult(dateKey: key, layout: vm.layout, won: won, durationSec: vm.elapsedSec)
                modelContext.insert(daily)
            }
        }
        try? modelContext.save()
    }
}
