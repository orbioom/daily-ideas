import SwiftUI
import SwiftData

struct GamePlayerView: View {
    let config: GameConfig

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Query private var profiles: [Profile]
    @State private var model: GameViewModel
    @State private var typed = ""
    @State private var didPersist = false
    @State private var timeRemaining = 0
    @State private var showFeedbackFlash = false

    init(config: GameConfig) {
        self.config = config
        _model = State(initialValue: GameViewModel(config: config))
    }

    private var profile: Profile? {
        profiles.first { $0.id == config.profileID }
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            content
        }
        .task { startIfNeeded() }
    }

    @ViewBuilder
    private var content: some View {
        switch model.phase {
        case .loading:
            loadingView
        case .asking, .feedback:
            playingView
        case .finished:
            EndScreen(model: model, onPlayAgain: restart, onDone: finishAndDismiss)
                .task { persistIfNeeded() }
        }
    }

    // MARK: Loading

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
                .tint(Theme.accent)
            Text("Getting your questions ready…")
                .font(Theme.rounded(16, .medium))
                .foregroundStyle(Theme.inkSoft)
        }
    }

    // MARK: Playing

    private var playingView: some View {
        VStack(spacing: 0) {
            topBar
            ScrollView {
                VStack(spacing: 24) {
                    progressDots
                    if settings.timerEnabled {
                        timerBar
                    }
                    questionCard
                    answerArea
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                Haptics.tap(settings.hapticsEnabled)
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Theme.inkSoft.opacity(0.7))
            }
            .accessibilityLabel("Close practice")
            Spacer()
            Text(model.progressText)
                .font(Theme.rounded(16, .bold))
                .foregroundStyle(Theme.inkSoft)
            Spacer()
            // Balance spacer
            Image(systemName: "xmark.circle.fill").font(.system(size: 28)).opacity(0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var progressDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<model.total, id: \.self) { i in
                Circle()
                    .fill(dotColor(for: i))
                    .frame(width: i == model.index ? 12 : 9, height: i == model.index ? 12 : 9)
            }
        }
        .accessibilityHidden(true)
        .animation(reduceMotion ? nil : .spring(response: 0.3), value: model.index)
    }

    private func dotColor(for i: Int) -> Color {
        if i < model.index { return Theme.good }
        if i == model.index { return Theme.accent }
        return Theme.inkSoft.opacity(0.25)
    }

    private var timerBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "timer").foregroundStyle(Theme.warn)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.surfaceAlt)
                    Capsule().fill(timeRemaining <= 3 ? Theme.bad : Theme.warn)
                        .frame(width: geo.size.width * timerFraction)
                }
            }
            .frame(height: 8)
            Text("\(max(0, timeRemaining))s")
                .font(Theme.rounded(14, .bold))
                .foregroundStyle(Theme.inkSoft)
                .frame(width: 32, alignment: .trailing)
        }
        .accessibilityLabel("Time remaining \(max(0, timeRemaining)) seconds")
    }

    private var timerFraction: Double {
        let limit = perQuestionSeconds
        guard limit > 0 else { return 0 }
        return min(1, max(0, Double(timeRemaining) / Double(limit)))
    }

    private var perQuestionSeconds: Int { 15 }

    private var questionCard: some View {
        let isFeedback: Bool = { if case .feedback = model.phase { return true } else { return false } }()
        return VStack(spacing: 16) {
            if let q = model.current {
                Text(q.prompt + " =")
                    .font(Theme.rounded(64, .bold))
                    .foregroundStyle(Theme.ink)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .accessibilityLabel("What is \(q.a) \(spoken(q.op)) \(q.b)?")

                if settings.answerMode == .numberPad {
                    answerDisplay(isFeedback: isFeedback)
                }
            }
            feedbackBanner
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(feedbackBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.rLarge, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Theme.rLarge, style: .continuous)
            .stroke(feedbackStroke, lineWidth: 2))
        .scaleEffect(showFeedbackFlash && !reduceMotion ? 1.02 : 1)
        .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.6), value: showFeedbackFlash)
    }

    private func answerDisplay(isFeedback: Bool) -> some View {
        Text(typed.isEmpty ? " " : typed)
            .font(Theme.rounded(40, .bold))
            .foregroundStyle(isFeedback ? (model.lastWasCorrect ? Theme.good : Theme.bad) : Theme.accent)
            .frame(minWidth: 100, minHeight: 56)
            .padding(.horizontal, 24)
            .background(Theme.surfaceAlt)
            .clipShape(RoundedRectangle(cornerRadius: Theme.rMedium, style: .continuous))
            .accessibilityLabel("Your answer: \(typed.isEmpty ? "empty" : typed)")
    }

    @ViewBuilder
    private var feedbackBanner: some View {
        if case .feedback(let correct) = model.phase {
            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 30))
                    Text(correct ? encouragement : "Not quite!")
                        .font(Theme.rounded(24, .bold))
                }
                .foregroundStyle(correct ? Theme.good : Theme.bad)
                if !correct {
                    Text("The answer is \(model.lastCorrectAnswer)")
                        .font(Theme.rounded(17, .semibold))
                        .foregroundStyle(Theme.ink)
                }
            }
            .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
            .accessibilityElement(children: .combine)
            .accessibilityLabel(correct ? "Correct!" : "Not quite. The answer is \(model.lastCorrectAnswer)")
        }
    }

    private var feedbackBackground: Color {
        if case .feedback(let correct) = model.phase {
            return (correct ? Theme.good : Theme.bad).opacity(0.10)
        }
        return Theme.surface
    }

    private var feedbackStroke: Color {
        if case .feedback(let correct) = model.phase {
            return correct ? Theme.good : Theme.bad
        }
        return Theme.hairline
    }

    // MARK: Answer area

    @ViewBuilder
    private var answerArea: some View {
        let asking: Bool = { if case .asking = model.phase { return true } else { return false } }()
        if settings.answerMode == .numberPad {
            NumberPad(text: $typed, isEnabled: asking, onEnter: submitTyped,
                      hapticsEnabled: settings.hapticsEnabled)
        } else if let q = model.current {
            MultipleChoiceGrid(choices: q.choices,
                               isEnabled: asking,
                               selectedAnswer: choiceFeedbackAnswer,
                               correctAnswer: q.answer) { choice in
                submit(value: choice)
            }
        }
    }

    /// When showing feedback, which choice the child picked (for highlight).
    private var choiceFeedbackAnswer: Int? {
        if case .feedback = model.phase {
            return model.lastWasCorrect ? model.lastCorrectAnswer : lastChoice
        }
        return nil
    }

    @State private var lastChoice: Int? = nil

    // MARK: Actions

    private func startIfNeeded() {
        guard case .loading = model.phase else { return }
        guard let profile else {
            // The profile vanished (e.g. deleted while presenting): close gracefully.
            dismiss()
            return
        }
        model.start(profile: profile, answerMode: settings.answerMode)
        resetTimer()
    }

    private func submitTyped() {
        guard let value = Int(typed) else { return }
        submit(value: value)
    }

    private func submit(value: Int) {
        guard case .asking = model.phase else { return }
        lastChoice = value
        let correct = model.submit(value)
        flashFeedback()
        if correct {
            Haptics.success(settings.hapticsEnabled)
            SoundPlayer.correct(settings.soundEnabled)
        } else {
            Haptics.warning(settings.hapticsEnabled)
            SoundPlayer.wrong(settings.soundEnabled)
        }
        // Auto-advance after a short, kid-friendly pause.
        Task {
            try? await Task.sleep(for: .seconds(correct ? 0.9 : 1.6))
            await MainActor.run {
                typed = ""
                lastChoice = nil
                model.advance()
                if case .asking = model.phase { resetTimer() }
            }
        }
    }

    private func flashFeedback() {
        showFeedbackFlash = true
        Task {
            try? await Task.sleep(for: .seconds(0.3))
            await MainActor.run { showFeedbackFlash = false }
        }
    }

    private func restart() {
        guard let profile else { return }
        didPersist = false
        typed = ""
        lastChoice = nil
        model.start(profile: profile, answerMode: settings.answerMode)
        resetTimer()
    }

    private func finishAndDismiss() {
        persistIfNeeded()
        Haptics.tap(settings.hapticsEnabled)
        dismiss()
    }

    private func persistIfNeeded() {
        guard !didPersist, let profile else { return }
        didPersist = true
        model.persist(profile: profile, context: context)
        SoundPlayer.finish(settings.soundEnabled)
        Haptics.celebrate(settings.hapticsEnabled)
    }

    // MARK: Timer

    private func resetTimer() {
        guard settings.timerEnabled else { return }
        timeRemaining = perQuestionSeconds
        tick()
    }

    private func tick() {
        guard settings.timerEnabled else { return }
        Task {
            try? await Task.sleep(for: .seconds(1))
            await MainActor.run {
                guard case .asking = model.phase, settings.timerEnabled else { return }
                if timeRemaining > 0 {
                    timeRemaining -= 1
                    tick()
                } else {
                    // Time's up — count as an attempt with no correct answer (gentle).
                    if Int(typed) == nil { _ = model.submit(-1) } else { submitTyped() }
                    flashFeedback()
                    Haptics.warning(settings.hapticsEnabled)
                    Task {
                        try? await Task.sleep(for: .seconds(1.6))
                        await MainActor.run {
                            typed = ""; lastChoice = nil
                            model.advance()
                            if case .asking = model.phase { resetTimer() }
                        }
                    }
                }
            }
        }
    }

    // MARK: Helpers

    private var encouragement: String {
        ["Great!", "Nice!", "You got it!", "Awesome!", "Yes!", "Brilliant!"]
            .randomElement() ?? "Great!"
    }

    private func spoken(_ op: MathOp) -> String {
        switch op {
        case .add: return "plus"
        case .sub: return "minus"
        case .mul: return "times"
        case .div: return "divided by"
        }
    }
}
