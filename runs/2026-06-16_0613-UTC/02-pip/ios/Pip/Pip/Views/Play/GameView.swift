import SwiftUI
import SwiftData

struct GameView: View {
    let config: GameConfig

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var settings: AppSettings

    @State private var vm: GameViewModel
    @State private var showQuitConfirm = false

    init(config: GameConfig) {
        self.config = config
        _vm = State(initialValue: GameViewModel(config: config))
    }

    private var rollDuration: Double {
        reduceMotion ? 0 : settings.rollSpeed.duration
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                ScrollView {
                    VStack(spacing: 16) {
                        feltTray
                        rollControls
                        ScorecardView(
                            engine: vm.engine,
                            sortByValue: settings.sortScorecardByValue,
                            canInteract: vm.humanCanInteract,
                            onScore: { cat in scoreTapped(cat) }
                        )
                    }
                    .padding(16)
                }
            }

            if let toast = vm.toast {
                VStack {
                    Spacer()
                    ToastView(text: toast, icon: vm.lastWasYahtzee ? "star.fill" : "checkmark.circle.fill")
                        .padding(.bottom, 28)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if vm.showWinner {
                WinnerOverlay(engine: vm.engine, onDone: { dismiss() }, onPlayAgain: nil)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: vm.toast != nil)
        .navigationBarBackButtonHidden(true)
        .task {
            vm.startIfCPUFirst(hapticsEnabled: settings.hapticsEnabled, saveAction: saveResult)
        }
        .confirmationDialog("Quit this game?", isPresented: $showQuitConfirm, titleVisibility: .visible) {
            Button("Quit game", role: .destructive) { dismiss() }
            Button("Keep playing", role: .cancel) {}
        } message: {
            Text("Your progress in this game won't be saved.")
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(spacing: 12) {
            Button {
                if vm.engine.isFinished { dismiss() } else { showQuitConfirm = true }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 38, height: 38)
                    .background(Theme.surface, in: Circle())
                    .overlay(Circle().strokeBorder(Theme.hairline, lineWidth: 1))
            }
            .accessibilityLabel("Close game")

            VStack(alignment: .leading, spacing: 1) {
                Text(config.mode.rawValue)
                    .font(Theme.rounded(13, .semibold))
                    .foregroundStyle(Theme.inkSoft)
                Text(turnText)
                    .font(Theme.rounded(18, .bold))
                    .foregroundStyle(Theme.ink)
            }
            Spacer()
            rollsIndicator
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(Theme.surface)
        .overlay(Divider().background(Theme.hairline), alignment: .bottom)
    }

    private var turnText: String {
        if vm.engine.isFinished { return "Game over" }
        guard let p = vm.engine.currentPlayer else { return "" }
        if p.isCPU { return vm.cpuThinking ? "\(p.name) is rolling…" : "\(p.name)'s turn" }
        return vm.engine.players.count > 1 ? "\(p.name)'s turn" : "Your turn"
    }

    private var rollsIndicator: some View {
        HStack(spacing: 5) {
            ForEach(0..<vm.engine.maxRolls, id: \.self) { i in
                Circle()
                    .fill(i < vm.engine.rollsRemaining ? Theme.accent : Theme.hairline)
                    .frame(width: 10, height: 10)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("\(vm.engine.rollsRemaining) of \(vm.engine.maxRolls) rolls left")
    }

    // MARK: - Felt tray

    private var feltTray: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                ForEach(0..<vm.engine.diceCount, id: \.self) { i in
                    DieView(
                        value: dieValue(i),
                        isHeld: vm.isHeld(i),
                        isRolling: vm.rollingDice.indices.contains(i) ? vm.rollingDice[i] : false,
                        size: 54,
                        rollDuration: rollDuration,
                        onTap: vm.engine.hasRolledThisTurn && vm.humanCanInteract
                            ? { vm.toggleHold(i, hapticsEnabled: settings.hapticsEnabled) }
                            : nil
                    )
                    .overlay(suggestionRing(for: i))
                }
            }

            if vm.engine.hasRolledThisTurn && vm.humanCanInteract && vm.engine.canRoll {
                Text("Tap dice to hold them, then roll again")
                    .font(Theme.rounded(12, .medium))
                    .foregroundStyle(.white.opacity(0.85))
            } else if !vm.engine.hasRolledThisTurn && vm.humanCanInteract {
                Text("Tap Roll to start your turn")
                    .font(Theme.rounded(12, .medium))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
        .background(
            RoundedRectangle(cornerRadius: Theme.rLarge, style: .continuous)
                .fill(Theme.feltGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.rLarge, style: .continuous)
                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func suggestionRing(for index: Int) -> some View {
        let suggested = settings.autoHoldSuggestions
            && vm.humanCanInteract
            && vm.engine.canRoll
            && vm.suggestedHolds.indices.contains(index)
            && vm.suggestedHolds[index]
            && !vm.isHeld(index)
        if suggested {
            RoundedRectangle(cornerRadius: 54 * 0.22 + 3, style: .continuous)
                .strokeBorder(Theme.accent, style: StrokeStyle(lineWidth: 2.5, dash: [5, 4]))
                .padding(-4)
                .accessibilityHidden(true)
        }
    }

    private func dieValue(_ i: Int) -> Int {
        vm.engine.dice.indices.contains(i) ? vm.engine.dice[i] : 1
    }

    // MARK: - Roll controls

    private var rollControls: some View {
        Group {
            if vm.engine.isCurrentPlayerCPU {
                HStack(spacing: 10) {
                    ProgressView().tint(Theme.accent)
                    Text("\(vm.engine.currentPlayer?.name ?? "CPU") is taking its turn…")
                        .font(Theme.rounded(15, .semibold))
                        .foregroundStyle(Theme.inkSoft)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .card()
            } else {
                PrimaryButton(
                    title: rollButtonTitle,
                    icon: "dice.fill",
                    enabled: vm.engine.canRoll && vm.humanCanInteract
                ) {
                    vm.roll(rollDuration: rollDuration,
                            hapticsEnabled: settings.hapticsEnabled,
                            reduceMotion: reduceMotion)
                }
            }
        }
    }

    private var rollButtonTitle: String {
        if !vm.engine.hasRolledThisTurn { return "Roll dice" }
        if vm.engine.rollsRemaining > 0 { return "Roll again (\(vm.engine.rollsRemaining) left)" }
        return "Pick a category to score"
    }

    // MARK: - Actions

    private func scoreTapped(_ category: ScoreCategory) {
        vm.score(category, hapticsEnabled: settings.hapticsEnabled, saveAction: saveResult)
    }

    private func saveResult() {
        guard let built = vm.buildRecord() else { return }
        context.insert(built.record)

        // Daily result: upsert best score for the day.
        if let key = built.dailyKey {
            let descriptor = FetchDescriptor<DailyResult>(
                predicate: #Predicate { $0.dayKey == key }
            )
            if let existing = try? context.fetch(descriptor).first {
                if built.dailyScore > existing.score {
                    existing.score = built.dailyScore
                    existing.yahtzees = built.dailyYahtzees
                    existing.date = .now
                }
            } else {
                context.insert(DailyResult(dayKey: key, date: .now,
                                           score: built.dailyScore, yahtzees: built.dailyYahtzees))
            }
        }
        try? context.save()
    }
}
