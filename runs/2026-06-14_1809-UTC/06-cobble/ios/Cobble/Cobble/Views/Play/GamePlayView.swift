import SwiftUI
import SwiftData

/// The shared playable surface used by both Classic and Daily. Owns the GameViewModel and
/// renders the header (score/best/combo), the board, the tray, and the controls (Undo,
/// New Game). Presents a paywall when the free Undo budget is exhausted.
struct GamePlayView: View {
    let mode: GameMode
    /// For daily, the date key to seed from; ignored for classic.
    var dateKey: String = ""
    /// For daily, the resolved best score for this date.
    var bestOverride: Int? = nil

    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("isPro") private var isPro = false

    @StateObject private var vm = GameViewModel()
    @State private var didStart = false
    @State private var paywall: PaywallReason?
    @State private var showRestartConfirm = false

    private var palette: BlockPalette { settings.palette(isPro: isPro) }

    private var best: Int {
        if let bestOverride { return max(bestOverride, vm.score) }
        return max(BestScores.classicBest, vm.score)
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 16) {
                header
                BoardView(vm: vm, palette: palette, showGhost: settings.showGhost)
                    .padding(.horizontal, 4)
                    .overlay(alignment: .top) { comboBanner }
                controls
                TrayView(vm: vm, palette: palette)
                    .padding(.bottom, 4)
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .disabled(vm.phase == .gameOver)

            if vm.phase == .gameOver {
                GameOverOverlay(score: vm.score,
                                best: best,
                                linesCleared: vm.linesCleared,
                                longestCombo: vm.longestCombo,
                                isNewBest: vm.score >= best && vm.score > 0,
                                onNewGame: restart)
                    .transition(.opacity)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: vm.phase)
        .sheet(item: $paywall) { PaywallView(reason: $0) }
        .confirmationDialog("Start a new game?",
                            isPresented: $showRestartConfirm,
                            titleVisibility: .visible) {
            Button("New game", role: .destructive) { restart() }
            Button("Keep playing", role: .cancel) {}
        } message: {
            Text("Your current game ends and won't be saved.")
        }
        .task(id: dateKey) { startIfNeeded() }
        .onChange(of: vm.flashingCells) { _, new in
            guard !new.isEmpty else { return }
            scheduleTransientClear()
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .center, spacing: 14) {
            scoreBlock(title: "Score", value: vm.score, big: true)
            scoreBlock(title: "Best", value: best, big: false)
            Spacer()
            if vm.combo >= 2 {
                Label("×\(vm.combo)", systemImage: "flame.fill")
                    .font(Theme.rounded(15, .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12).padding(.vertical, 7)
                    .background(Capsule().fill(Theme.accent))
                    .accessibilityLabel("Combo \(vm.combo)")
            }
        }
    }

    private func scoreBlock(title: String, value: Int, big: Bool) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title.uppercased())
                .font(Theme.rounded(11, .semibold))
                .foregroundStyle(Theme.inkFaint)
            Text("\(value)")
                .font(Theme.mono(big ? 30 : 20, .bold))
                .foregroundStyle(big ? Theme.ink : Theme.inkSoft)
                .contentTransition(.numericText())
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) \(value)")
    }

    @ViewBuilder
    private var comboBanner: some View {
        if let banner = vm.comboBanner, !reduceMotion {
            Text(banner)
                .font(Theme.rounded(20, .heavy))
                .foregroundStyle(.white)
                .padding(.horizontal, 16).padding(.vertical, 9)
                .background(Capsule().fill(Theme.good))
                .shadow(color: Theme.good.opacity(0.4), radius: 8, y: 3)
                .padding(.top, 12)
                .transition(.scale.combined(with: .opacity))
                .accessibilityHidden(true)
        }
    }

    // MARK: Controls

    private var controls: some View {
        HStack(spacing: 12) {
            Button(action: handleUndo) {
                Label(undoLabel, systemImage: "arrow.uturn.backward")
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(vm.canUndo ? Theme.accent : Theme.inkFaint)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                        .fill(Theme.surface))
                    .overlay(RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                        .strokeBorder(Theme.hairline, lineWidth: 1))
            }
            .disabled(!vm.canUndo)
            .accessibilityHint("Reverts your last placement")

            Button {
                showRestartConfirm = true
            } label: {
                Label("New", systemImage: "arrow.clockwise")
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.inkSoft)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                        .fill(Theme.surface))
                    .overlay(RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                        .strokeBorder(Theme.hairline, lineWidth: 1))
            }
        }
    }

    private var undoLabel: String {
        if isPro { return "Undo" }
        if let n = vm.remainingUndos { return "Undo (\(n))" }
        return "Undo"
    }

    // MARK: Actions

    private func startIfNeeded() {
        vm.configure(context: context, settings: settings, isPro: isPro)
        guard !didStart else { return }
        didStart = true
        if mode == .classic, let existing = fetchSavedClassic(), vm.resumeClassic(existing) {
            return
        }
        vm.startNew(mode: mode, dateKey: dateKey)
    }

    private func fetchSavedClassic() -> SavedGame? {
        let descriptor = FetchDescriptor<SavedGame>(predicate: #Predicate { $0.modeRaw == "classic" })
        return (try? context.fetch(descriptor))?.first
    }

    private func restart() {
        vm.startNew(mode: mode, dateKey: dateKey)
    }

    private func handleUndo() {
        if vm.hasUndoBudget {
            vm.undo()
        } else {
            paywall = .undo
        }
    }

    private func scheduleTransientClear() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            vm.clearTransients()
        }
    }
}
