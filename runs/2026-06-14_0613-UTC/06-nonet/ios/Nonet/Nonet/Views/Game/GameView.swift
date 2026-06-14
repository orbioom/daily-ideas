import SwiftUI
import SwiftData

/// The playable game screen. Hosts the board, pad and controls, plus the generating
/// loading state, the win celebration, the game-over state, and the error fallback.
struct GameView: View {
    let launch: GameLaunch

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var settings: AppSettings

    @StateObject private var vm = GameViewModel()
    @State private var paywall: PaywallReason? = nil
    @State private var didStart = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                content
                overlays
            }
            .navigationTitle(titleText)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Label("Close", systemImage: "chevron.left")
                    }
                }
                ToolbarItem(placement: .principal) {
                    if settings.showTimer && showsTimer {
                        Text(vm.elapsedFormatted)
                            .font(Theme.mono(16, .semibold))
                            .foregroundStyle(Theme.textSecondary)
                            .accessibilityLabel("Time \(vm.elapsedFormatted)")
                    }
                }
            }
        }
        .task {
            guard !didStart else { return }
            didStart = true
            vm.configure(context: context, settings: settings)
            start()
        }
        .sheet(item: $paywall) { reason in PaywallView(reason: reason) }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active: vm.resumeFromForeground()
            case .background, .inactive: vm.pauseForBackground()
            @unknown default: break
            }
        }
    }

    // MARK: Start / resume

    private func start() {
        if let resumeId = launch.resumeId,
           let game = fetchSaved(id: resumeId) {
            vm.resume(game, settings: settings)
            return
        }
        switch launch.mode {
        case .daily:
            // Resume today's daily if it already exists and is active.
            if let existing = fetchActiveDaily() {
                vm.resume(existing, settings: settings)
            } else {
                vm.startNew(difficulty: dailyDifficulty, isDaily: true, settings: settings)
            }
        case .casual(let diff):
            vm.startNew(difficulty: diff, isDaily: false, settings: settings)
        }
    }

    /// Daily difficulty is fixed at Medium so it's free for everyone, every day.
    private var dailyDifficulty: Difficulty { .medium }

    private func fetchSaved(id: UUID) -> SavedGame? {
        let descriptor = FetchDescriptor<SavedGame>(predicate: #Predicate { $0.id == id })
        return (try? context.fetch(descriptor))?.first
    }

    private func fetchActiveDaily() -> SavedGame? {
        let key = DailySeed.dateKey(for: Date())
        let descriptor = FetchDescriptor<SavedGame>(
            predicate: #Predicate { $0.isDaily == true && $0.isActive == true && $0.completed == false }
        )
        return (try? context.fetch(descriptor))?.first { $0.dateKey == key }
    }

    private var titleText: String {
        switch launch.mode {
        case .daily: return "Daily"
        case .casual(let d): return d.title
        }
    }

    /// Show the timer while playing or paused (so the player keeps context on pause).
    private var showsTimer: Bool {
        vm.phase == .playing || vm.isPaused
    }

    // MARK: Main content per phase

    @ViewBuilder
    private var content: some View {
        switch vm.phase {
        case .loading:
            LoadingStateView()
        case .error(let message):
            errorState(message)
        default:
            playingLayout
        }
    }

    private var playingLayout: some View {
        VStack(spacing: 14) {
            statusBar
            BoardView(vm: vm)
                .environmentObject(settings)
                .padding(.horizontal, 4)
            if let msg = vm.hintMessage {
                hintBanner(msg)
            }
            NumberPadView(vm: vm)
            GameControlsView(vm: vm) {
                paywall = .hints
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .opacity(vm.isPaused ? 0.08 : 1)
        .allowsHitTesting(!vm.isPaused)
    }

    private var statusBar: some View {
        HStack {
            Label(difficultyTitle, systemImage: difficultySymbol)
                .font(Theme.rounded(14, .medium))
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            if settings.mistakeLimitOn {
                Label("\(vm.mistakes)/\(settings.mistakeLimit)", systemImage: "xmark.circle")
                    .font(Theme.rounded(14, .medium))
                    .foregroundStyle(vm.mistakes > 0 ? Theme.error : Theme.textSecondary)
                    .accessibilityLabel("Mistakes \(vm.mistakes) of \(settings.mistakeLimit)")
            } else if vm.mistakes > 0 {
                Label("\(vm.mistakes)", systemImage: "xmark.circle")
                    .font(Theme.rounded(14, .medium))
                    .foregroundStyle(Theme.error)
                    .accessibilityLabel("\(vm.mistakes) mistakes")
            }
        }
    }

    private var difficultyTitle: String {
        switch launch.mode {
        case .daily: return "Daily"
        case .casual(let d): return d.title
        }
    }
    private var difficultySymbol: String {
        switch launch.mode {
        case .daily: return "calendar"
        case .casual(let d): return d.symbol
        }
    }

    private func hintBanner(_ msg: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "lightbulb.fill").foregroundStyle(Theme.accent)
            Text(msg)
                .font(Theme.rounded(13))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
        }
        .padding(10)
        .background(Theme.accent.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous))
        .transition(.opacity)
        .accessibilityLabel("Hint: \(msg)")
    }

    // MARK: Overlays (win / lost / pause)

    @ViewBuilder
    private var overlays: some View {
        switch vm.phase {
        case .won:
            WinOverlay(time: vm.elapsedFormatted, mistakes: vm.mistakes,
                       hints: vm.hintsUsed, difficulty: vm.difficulty,
                       reduceMotion: reduceMotion) { dismiss() }
        case .lost:
            LostOverlay(difficulty: vm.difficulty) { dismiss() }
        default:
            if vm.isPaused {
                PausedOverlay { vm.togglePause() }
            }
        }
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 16) {
            EmptyStateView(icon: "exclamationmark.triangle",
                           title: "Generation Hiccup",
                           message: message)
            Button("Try Again") { start() }
                .buttonStyle(PrimaryButtonStyle())
                .frame(maxWidth: 240)
            Button("Back") { dismiss() }
                .font(Theme.rounded(15, .medium))
                .foregroundStyle(Theme.accent)
        }
        .padding()
    }
}

/// A real loading state shown while a puzzle is generated off the main thread.
struct LoadingStateView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var spin = false
    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .stroke(Theme.separator, lineWidth: 4)
                    .frame(width: 56, height: 56)
                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(Theme.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(spin ? 360 : 0))
                    .animation(reduceMotion ? nil : .linear(duration: 0.9).repeatForever(autoreverses: false),
                               value: spin)
            }
            Text("Generating…")
                .font(Theme.rounded(18, .semibold))
                .foregroundStyle(Theme.textPrimary)
            Text("Crafting a puzzle with a single solution.")
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.textSecondary)
        }
        .onAppear { spin = true }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Generating a puzzle")
    }
}
