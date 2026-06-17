import SwiftUI
import SwiftData

/// The Play screen for one level (or the daily puzzle). Builds the layout
/// asynchronously (loading spinner), then presents grid + wheel + controls.
struct LevelPlayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @AppStorage("relaxedMode") private var relaxedMode = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let level: Level
    /// When set, completion records a daily result instead of level progress.
    var isDaily: Bool = false
    var onCompleted: ((Int) -> Void)? = nil

    @State private var game: GameModel?
    @State private var loading = true
    @State private var loadFailed = false

    @State private var candidateText = ""
    @State private var toast: (text: String, kind: ToastKind)? = nil
    @State private var shakeTrigger = 0
    @State private var recentlyRevealed: Set<GridCoord> = []
    @State private var showWin = false
    @State private var earnedStars = 0
    @State private var confettiActive = false

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            if loading {
                loadingState
            } else if loadFailed || (game?.layout.isEmpty ?? true) {
                errorState
            } else if let game {
                content(game)
            }

            if let toast {
                VStack {
                    ToastView(text: toast.text, kind: toast.kind)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    Spacer()
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle(level.title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await buildIfNeeded() }
        .overlay {
            if showWin, let game {
                WinOverlayView(
                    stars: earnedStars,
                    bonusCount: game.bonusWords.count,
                    isDaily: isDaily,
                    onNext: handleNext,
                    onClose: { dismiss() }
                )
                .transition(.opacity)
            }
        }
        .overlay { ConfettiView(active: confettiActive) }
    }

    // MARK: - States

    private var loadingState: some View {
        VStack(spacing: 14) {
            ProgressView()
                .controlSize(.large)
                .tint(Theme.accent)
            Text("Weaving the puzzle…")
                .font(Theme.rounded(15, .medium))
                .foregroundStyle(Theme.inkSoft)
        }
    }

    private var errorState: some View {
        EmptyStateView(
            systemImage: "exclamationmark.triangle",
            title: "This puzzle couldn't be laid out",
            message: "We couldn't weave these letters into a crossword. Let's head back and try another level.",
            actionTitle: "Go Back",
            action: { dismiss() }
        )
    }

    // MARK: - Content

    private func content(_ game: GameModel) -> some View {
        VStack(spacing: 12) {
            header(game)

            CrosswordGridView(
                layout: game.layout,
                isVisible: { game.isVisible($0) },
                recentlyRevealed: recentlyRevealed
            )
            .frame(maxHeight: .infinity)
            .padding(.horizontal, 12)

            candidateBar(game)

            if settings.showFoundList {
                foundList(game)
            }

            controls(game)

            LetterWheelView(
                letters: game.wheelLetters,
                selection: game.selection,
                onBegin: { game.beginSelection(at: $0); SoundPlayer.tap(enabled: settings.soundEnabled) },
                onExtend: { game.extendSelection(to: $0) },
                onTap: { slot in
                    game.toggleTap(slot)
                    Haptics.selection(enabled: settings.hapticsEnabled)
                    SoundPlayer.tap(enabled: settings.soundEnabled)
                    syncCandidate(game)
                },
                onRelease: { handleSubmit(game) }
            )
            .frame(height: 240)
            .padding(.bottom, 8)
        }
        .padding(.vertical, 8)
        .onChange(of: game.selection) { _, _ in syncCandidate(game) }
    }

    private func header(_ game: GameModel) -> some View {
        HStack(spacing: 16) {
            counter(icon: "checkmark.circle.fill",
                    value: "\(game.foundGridCount)/\(game.totalGridWords)",
                    label: "Words found",
                    tint: Theme.good)
            counter(icon: "sparkles",
                    value: "\(game.bonusWords.count)",
                    label: "Bonus words",
                    tint: Theme.star)
            counter(icon: "lightbulb.fill",
                    value: game.hasUnlimitedHints ? "∞" : "\(game.hintsRemaining)",
                    label: "Hints remaining",
                    tint: Theme.accent)
        }
        .padding(.horizontal, 16)
    }

    private func counter(icon: String, value: String, label: String, tint: Color) -> some View {
        VStack(spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(tint)
                    .accessibilityHidden(true)
                Text(value)
                    .font(Theme.rounded(17, .bold))
                    .foregroundStyle(Theme.ink)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(value)
    }

    private func candidateBar(_ game: GameModel) -> some View {
        Text(candidateText.isEmpty ? " " : candidateText)
            .font(Theme.rounded(30, .heavy))
            .tracking(4)
            .foregroundStyle(Theme.accentDeep)
            .frame(height: 44)
            .modifier(ShakeEffect(animatableData: CGFloat(shakeTrigger)))
            .accessibilityLabel(candidateText.isEmpty ? "No letters selected" : "Spelling \(candidateText)")
    }

    @ViewBuilder
    private func foundList(_ game: GameModel) -> some View {
        let words = game.placedWords.filter { game.foundGridWords.contains($0) }.sorted()
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if words.isEmpty {
                    Text("Found words appear here")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                } else {
                    ForEach(words, id: \.self) { w in
                        Text(w)
                            .font(Theme.rounded(13, .bold))
                            .foregroundStyle(Theme.accentDeep)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(Theme.accentSoft))
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 30)
    }

    private func controls(_ game: GameModel) -> some View {
        HStack(spacing: 12) {
            circleControl(icon: "shuffle", label: "Shuffle letters") {
                game.shuffle()
                Haptics.impact(.light, enabled: settings.hapticsEnabled)
                syncCandidate(game)
            }
            circleControl(icon: "lightbulb.fill", label: "Use a hint",
                          disabled: !game.hasUnlimitedHints && game.hintsRemaining <= 0) {
                handleHint(game)
            }
        }
    }

    private func circleControl(icon: String, label: String, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(disabled ? Theme.inkSoft.opacity(0.4) : Theme.accentDeep)
                .frame(width: 52, height: 52)
                .background(Circle().fill(Theme.surface).overlay(Circle().strokeBorder(Theme.hairline, lineWidth: 1.5)))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .accessibilityLabel(label)
    }

    // MARK: - Actions

    private func buildIfNeeded() async {
        guard game == nil else { return }
        loading = true
        // Brief async build so the loading state is real and the UI stays responsive.
        try? await Task.sleep(nanoseconds: 350_000_000)
        let built = GameModel(level: level, isPro: isPro, hardMode: settings.hardMode)
        await MainActor.run {
            self.game = built
            self.loadFailed = built.layout.isEmpty
            self.loading = false
        }
    }

    private func syncCandidate(_ game: GameModel) {
        candidateText = game.currentCandidate
    }

    private func handleSubmit(_ game: GameModel) {
        let outcome = game.submit()
        candidateText = ""
        switch outcome {
        case .foundTarget(let word):
            markRecentReveal(game, word: word)
            showToast(word, .good)
            Haptics.success(enabled: settings.hapticsEnabled)
            SoundPlayer.found(enabled: settings.soundEnabled)
            if game.isComplete { finishLevel(game) }
        case .bonus(let word):
            ProgressStore(context: modelContext).recordBonus(word: word, levelID: level.id)
            showToast("Bonus: \(word)", .bonus)
            Haptics.impact(.medium, enabled: settings.hapticsEnabled)
            SoundPlayer.bonus(enabled: settings.soundEnabled)
        case .alreadyFound:
            showToast("Already found", .neutral)
        case .invalid:
            withAnimation(reduceMotion ? nil : .default) { shakeTrigger += 1 }
            Haptics.warning(enabled: settings.hapticsEnabled)
            SoundPlayer.invalid(enabled: settings.soundEnabled)
        }
    }

    private func markRecentReveal(_ game: GameModel, word: String) {
        let cells = game.layout.placed.filter { $0.word.uppercased() == word }.flatMap { $0.cells }
        recentlyRevealed = Set(cells)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            recentlyRevealed = []
        }
    }

    private func handleHint(_ game: GameModel) {
        if !game.hasUnlimitedHints && game.hintsRemaining <= 0 { return }
        if let _ = game.useHint() {
            Haptics.impact(.rigid, enabled: settings.hapticsEnabled)
            SoundPlayer.tap(enabled: settings.soundEnabled)
            if game.isComplete { finishLevel(game) }
        } else {
            showToast("No hint available", .neutral)
        }
    }

    private func finishLevel(_ game: GameModel) {
        let stars = game.computeStars(relaxed: relaxedMode && isPro)
        earnedStars = stars
        let store = ProgressStore(context: modelContext)
        if isDaily {
            store.recordDaily(dateKey: DateKey.key(), stars: stars)
        } else {
            store.recordCompletion(levelID: level.id, stars: stars, bonusFound: game.bonusWords.count)
        }
        Haptics.success(enabled: settings.hapticsEnabled)
        SoundPlayer.win(enabled: settings.soundEnabled)
        onCompleted?(stars)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showWin = true
        }
        confettiActive = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
            confettiActive = false
        }
    }

    private func handleNext() {
        dismiss()
    }

    private func showToast(_ text: String, _ kind: ToastKind) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            toast = (text, kind)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(.easeOut(duration: 0.25)) {
                if toast?.text == text { toast = nil }
            }
        }
    }
}

/// A horizontal shake used for invalid-word feedback.
struct ShakeEffect: GeometryEffect {
    var animatableData: CGFloat
    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = 8 * sin(animatableData * .pi * 4)
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}
