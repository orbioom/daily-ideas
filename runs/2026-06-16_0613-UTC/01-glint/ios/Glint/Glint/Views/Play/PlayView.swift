import SwiftUI
import SwiftData

/// Configuration passed into a play session.
struct PlayConfig: Identifiable, Hashable {
    let id = UUID()
    let mode: GameMode
    let level: Level?
    let seed: UInt64
    var allowRestart: Bool = true
    var resumeSlot: String? = nil
}

struct PlayView: View {
    let config: PlayConfig
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var pro: ProStore

    @State private var game: GameViewModel
    @State private var paused = false
    @State private var showReshuffleToast = false
    @State private var didSaveOutcome = false

    init(config: PlayConfig, resume: SavedGame? = nil) {
        self.config = config
        _game = State(initialValue: GameViewModel(mode: config.mode, level: config.level, seed: config.seed, resume: resume))
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            VStack(spacing: 14) {
                hud
                goalBar
                ZStack {
                    BoardView(game: game, swapMode: settings.swapMode, showHints: settings.showHints)
                    comboOverlay
                }
                controls
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            if let outcome = game.outcome {
                ResultOverlay(
                    outcome: outcome,
                    score: game.score,
                    mode: config.mode,
                    level: config.level,
                    onRetry: config.allowRestart ? restart : nil,
                    onNext: nextLevel,
                    onExit: { dismiss() }
                )
                .transition(.opacity)
            }

            if paused {
                pauseOverlay
            }

            if showReshuffleToast {
                VStack {
                    Spacer()
                    Toast(text: "No moves left — board reshuffled", systemImage: "arrow.triangle.2.circlepath")
                        .padding(.bottom, 120)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationTitle(navTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { saveIfResumable(); dismiss() } label: {
                    Image(systemName: "chevron.left")
                }
                .accessibilityLabel("Back")
            }
        }
        .onAppear {
            game.reduceMotion = reduceMotion || settings.reducedEffects
            game.hapticsEnabled = settings.hapticsEnabled
        }
        .onChange(of: game.outcome) { _, newValue in
            if newValue != nil { handleOutcome() }
        }
        .onChange(of: game.didReshuffle) { _, newValue in
            if newValue {
                withAnimation { showReshuffleToast = true }
                game.clearReshuffleFlag()
                Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    withAnimation { showReshuffleToast = false }
                }
            }
        }
        .onChange(of: settings.reducedEffects) { _, newValue in
            game.reduceMotion = reduceMotion || newValue
        }
    }

    private var navTitle: String {
        switch config.mode {
        case .level: return config.level?.title ?? "Level"
        case .zen: return "Zen"
        case .daily: return "Daily Challenge"
        }
    }

    // MARK: - HUD

    private var hud: some View {
        HStack(spacing: 10) {
            StatPill(icon: "star.fill", label: "Score", value: "\(game.score)", tint: Theme.gold)
            if let left = game.movesLeft {
                StatPill(icon: "arrow.left.arrow.right", label: "Moves", value: "\(left)",
                         tint: left <= 3 ? Theme.bad : Theme.accent)
            } else {
                StatPill(icon: "infinity", label: "Mode", value: "Zen", tint: Theme.accent)
            }
            StatPill(icon: "flame.fill", label: "Best Combo", value: "×\(game.bestCombo)", tint: Theme.warn)
        }
    }

    @ViewBuilder
    private var goalBar: some View {
        if let goal = game.goal {
            GlintCard(padding: 12) {
                HStack(spacing: 10) {
                    Image(systemName: goal.icon)
                        .foregroundStyle(Theme.accent)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(game.goalProgressText)
                            .font(Theme.rounded(14, .semibold))
                            .foregroundStyle(Theme.ink)
                        ProgressView(value: game.goalProgress)
                            .tint(Theme.accent)
                    }
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Goal progress: \(game.goalProgressText)")
        }
    }

    @ViewBuilder
    private var comboOverlay: some View {
        if let banner = game.comboBanner {
            Text(banner.text)
                .font(Theme.rounded(34, .black))
                .foregroundStyle(.white)
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
                .background(Capsule().fill(Theme.heroGradient))
                .shadow(color: Theme.accent.opacity(0.5), radius: 12)
                .scaleEffect(game.reduceMotion ? 1 : 1.05)
                .transition(.scale.combined(with: .opacity))
                .accessibilityLabel(banner.chain >= 2 ? "Combo times \(banner.chain)" : "\(banner.points) points")
                .id(banner.id)
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button { paused = true } label: {
                controlLabel("Pause", "pause.fill")
            }
            if settings.showHints {
                Button { game.requestHint() } label: {
                    controlLabel("Hint", "lightbulb.fill")
                }
                .disabled(game.isResolving)
            }
        }
    }

    private func controlLabel(_ title: String, _ symbol: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
            Text(title).font(Theme.rounded(15, .semibold))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .foregroundStyle(Theme.accent)
        .background(
            RoundedRectangle(cornerRadius: Theme.rMed, style: .continuous)
                .fill(Theme.surface)
                .overlay(RoundedRectangle(cornerRadius: Theme.rMed, style: .continuous).stroke(Theme.hairline))
        )
    }

    // MARK: - Pause overlay

    private var pauseOverlay: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
                .onTapGesture { paused = false }
            VStack(spacing: 16) {
                Text("Paused")
                    .font(Theme.rounded(26, .bold))
                    .foregroundStyle(.white)
                PrimaryButton(title: "Resume", systemImage: "play.fill") { paused = false }
                if config.allowRestart {
                    Button { paused = false; restart() } label: {
                        secondaryLabel("Restart", "arrow.counterclockwise")
                    }
                }
                Button { saveIfResumable(); dismiss() } label: {
                    secondaryLabel("Quit to menu", "xmark")
                }
            }
            .padding(28)
            .frame(maxWidth: 320)
            .background(RoundedRectangle(cornerRadius: Theme.rLarge).fill(Theme.surface))
            .padding(40)
        }
        .transition(.opacity)
    }

    private func secondaryLabel(_ title: String, _ symbol: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
            Text(title).font(Theme.rounded(16, .semibold))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .foregroundStyle(Theme.accent)
        .background(RoundedRectangle(cornerRadius: Theme.rMed).fill(Theme.surfaceRaised))
    }

    // MARK: - Actions

    private func restart() {
        didSaveOutcome = false
        game = GameViewModel(mode: config.mode, level: config.level, seed: config.seed)
        game.reduceMotion = reduceMotion || settings.reducedEffects
        game.hapticsEnabled = settings.hapticsEnabled
    }

    private func nextLevel() {
        guard let level = config.level,
              let next = LevelCatalog.level(id: level.id + 1) else {
            dismiss(); return
        }
        if ProGate.isLevelLocked(next, isPro: pro.isPro) {
            dismiss(); return
        }
        didSaveOutcome = false
        let newConfig = PlayConfig(mode: .level, level: next, seed: UInt64(next.id) &* 2654435761)
        game = GameViewModel(mode: .level, level: next, seed: newConfig.seed)
        game.reduceMotion = reduceMotion || settings.reducedEffects
        game.hapticsEnabled = settings.hapticsEnabled
    }

    // MARK: - Persistence

    private func handleOutcome() {
        guard !didSaveOutcome, let outcome = game.outcome else { return }
        didSaveOutcome = true
        clearResumeSave()

        let won: Bool
        let stars: Int
        switch outcome {
        case .won(let s): won = true; stars = s
        case .lost: won = false; stars = 0
        }

        // Record stats.
        let record = GameRecord(
            date: Date(),
            modeRaw: config.mode.rawValue,
            score: game.score,
            levelID: config.level?.id,
            stars: stars,
            bestCombo: game.bestCombo,
            gemsCleared: game.totalCleared
        )
        context.insert(record)

        switch config.mode {
        case .level:
            if let level = config.level { updateLevelProgress(level, stars: stars, won: won) }
        case .daily:
            updateDaily(won: won)
        case .zen:
            break
        }

        try? context.save()
    }

    private func updateLevelProgress(_ level: Level, stars: Int, won: Bool) {
        let id = level.id
        let descriptor = FetchDescriptor<LevelProgress>(predicate: #Predicate { $0.levelID == id })
        let existing = (try? context.fetch(descriptor))?.first
        let progress = existing ?? {
            let p = LevelProgress(levelID: id, unlocked: true)
            context.insert(p)
            return p
        }()
        if won {
            progress.completed = true
            progress.stars = max(progress.stars, stars)
            progress.bestScore = max(progress.bestScore, game.score)
            // Unlock the next level.
            if let next = LevelCatalog.level(id: id + 1) {
                let nid = next.id
                let nextDesc = FetchDescriptor<LevelProgress>(predicate: #Predicate { $0.levelID == nid })
                if let nextProg = (try? context.fetch(nextDesc))?.first {
                    nextProg.unlocked = true
                } else {
                    context.insert(LevelProgress(levelID: nid, unlocked: true))
                }
            }
        } else {
            progress.bestScore = max(progress.bestScore, game.score)
        }
    }

    private func updateDaily(won: Bool) {
        let key = Date().dayKey
        let descriptor = FetchDescriptor<DailyResult>(predicate: #Predicate { $0.dayKey == key })
        if let existing = (try? context.fetch(descriptor))?.first {
            existing.score = max(existing.score, game.score)
            existing.won = existing.won || won
        } else {
            context.insert(DailyResult(dayKey: key, date: Date(), score: game.score, moves: game.movesUsed, won: won))
        }
    }

    private func saveIfResumable() {
        guard config.mode == .zen, game.outcome == nil else { return }
        let snap = game.snapshot()
        let slot = "zen"
        let descriptor = FetchDescriptor<SavedGame>(predicate: #Predicate { $0.slot == slot })
        if let existing = (try? context.fetch(descriptor))?.first {
            existing.boardData = snap.board
            existing.rngState = snap.rng
            existing.score = snap.score
            existing.movesUsed = snap.moves
            existing.updatedAt = Date()
        } else {
            context.insert(SavedGame(slot: "zen", modeRaw: GameMode.zen.rawValue, levelID: nil,
                                     score: snap.score, movesUsed: snap.moves,
                                     boardData: snap.board, rngState: snap.rng))
        }
        // Persist Zen high score.
        let zenDesc = FetchDescriptor<ZenScore>(predicate: #Predicate { $0.key == "zen" })
        if let z = (try? context.fetch(zenDesc))?.first {
            z.highScore = max(z.highScore, game.score)
        } else {
            context.insert(ZenScore(key: "zen", highScore: game.score))
        }
        try? context.save()
    }

    private func clearResumeSave() {
        guard config.mode == .zen else { return }
        let slot = "zen"
        let descriptor = FetchDescriptor<SavedGame>(predicate: #Predicate { $0.slot == slot })
        if let existing = (try? context.fetch(descriptor))?.first {
            context.delete(existing)
        }
    }
}
