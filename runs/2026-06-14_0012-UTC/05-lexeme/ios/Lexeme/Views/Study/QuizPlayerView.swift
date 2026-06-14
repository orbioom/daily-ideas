import SwiftUI
import SwiftData

/// The quiz player: shows the prompt, accepts an MC or typed answer, gives
/// immediate feedback (full entry on a miss), then a results screen at the end.
struct QuizPlayerView: View {
    let request: SessionRequest
    /// Called with the number of questions answered, for daily-cap accounting.
    var onFinish: (Int) -> Void

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var model = QuizViewModel()
    @State private var selectedOption: String?
    @State private var typedAnswer = ""
    @State private var didSubmit = false
    @FocusState private var typingFocused: Bool

    private var store: ProgressStore { ProgressStore(context: context) }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            switch model.phase {
            case .loading:
                LoadingView(message: "Building your session...")
            case .empty:
                emptyState
            case .playing:
                playing
            case .finished:
                ResultsView(correct: model.correctCount,
                            total: model.answeredCount,
                            accuracy: model.accuracy,
                            leveledUp: model.leveledUpWords,
                            onDone: { finishUp() })
            }
        }
        .navigationTitle(request.mode?.shortTitle ?? "Review")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if model.phase == .playing {
                ToolbarItem(placement: .topBarTrailing) {
                    Text("\(model.index + 1)/\(model.questions.count)")
                        .font(Theme.rounded(14, .medium))
                        .foregroundStyle(Theme.inkSoft)
                        .monospacedDigit()
                }
            }
        }
        .task {
            await model.start(store: store,
                              allowedModes: request.allowedModes,
                              singleMode: request.mode,
                              limit: request.limit,
                              typedFillBlank: request.typedFillBlank)
        }
    }

    private func finishUp() {
        onFinish(model.answeredCount)
        dismiss()
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack {
            EmptyStateView(systemImage: "tray",
                           title: "Nothing to study yet",
                           message: "There aren't enough words ready for this mode right now. Mark a few words as learning from Today or the Lexicon, then come back.",
                           actionTitle: "Go back") { dismiss() }
        }
        .padding()
    }

    // MARK: - Playing

    private var playing: some View {
        VStack(spacing: 0) {
            ProgressBar(fraction: model.progressFraction)
                .frame(height: 5)
                .padding(.horizontal, 18)
                .padding(.top, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    if let q = model.current {
                        promptCard(q)
                        if q.isTyped {
                            typedField(q)
                        } else {
                            optionsList(q)
                        }
                        if didSubmit, let r = model.lastResult {
                            feedback(r)
                        }
                    }
                }
                .padding(18)
            }

            bottomBar
        }
    }

    private func promptCard(_ q: QuizQuestion) -> some View {
        LexemeCard {
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(text: promptLabel(q.mode))
                Text(q.prompt)
                    .font(promptFont(q.mode))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(promptLabel(q.mode)): \(q.prompt)")
    }

    private func promptLabel(_ mode: QuizMode) -> String {
        switch mode {
        case .definitionToWord: return "Which word means"
        case .wordToDefinition: return "What does this mean"
        case .synonymMatch:     return "A synonym for"
        case .fillBlank:        return "Complete the sentence"
        }
    }

    private func promptFont(_ mode: QuizMode) -> Font {
        switch mode {
        case .wordToDefinition, .synonymMatch:
            return Theme.serif(30, .bold)
        default:
            return Theme.serif(19)
        }
    }

    private func optionsList(_ q: QuizQuestion) -> some View {
        VStack(spacing: 10) {
            ForEach(q.options, id: \.self) { option in
                OptionRow(text: option,
                          state: optionState(option, q: q),
                          isWord: q.mode != .wordToDefinition) {
                    guard !didSubmit else { return }
                    selectedOption = option
                    submit(option)
                }
            }
        }
    }

    private func optionState(_ option: String, q: QuizQuestion) -> OptionRow.State {
        guard didSubmit else {
            return selectedOption == option ? .selected : .idle
        }
        let isAnswer = QuizQuestion.normalize(option) == QuizQuestion.normalize(q.answer)
        if isAnswer { return .correct }
        if option == selectedOption { return .wrong }
        return .dimmed
    }

    private func typedField(_ q: QuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("Type the word", text: $typedAnswer)
                .font(Theme.serif(22))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .disabled(didSubmit)
                .focused($typingFocused)
                .padding(14)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(typedBorderColor, lineWidth: 1.5))
                .onSubmit { if !didSubmit && !typedAnswer.trimmingCharacters(in: .whitespaces).isEmpty { submit(typedAnswer) } }
            if !didSubmit {
                Text("Case and accents don't matter.")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkFaint)
            }
        }
        .onAppear { if !didSubmit { typingFocused = true } }
    }

    private var typedBorderColor: Color {
        guard didSubmit, let r = model.lastResult else { return Theme.hairline }
        return r.correct ? Theme.good : Theme.bad
    }

    private func feedback(_ r: AnswerResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: r.correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(r.correct ? Theme.good : Theme.bad)
                Text(r.correct ? "Correct" : "Not quite")
                    .font(Theme.rounded(17, .bold))
                    .foregroundStyle(r.correct ? Theme.good : Theme.bad)
                if r.leveledUp {
                    Spacer()
                    Label("Leveled up", systemImage: "arrow.up.circle.fill")
                        .font(Theme.rounded(13, .semibold))
                        .foregroundStyle(Theme.accent)
                }
            }
            // Show the full entry on a miss so the user actually learns it.
            if !r.correct {
                LexemeCard {
                    WordEntryView(word: r.question.word, showExample: true)
                }
            }
        }
        .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
    }

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider().overlay(Theme.hairline)
            Group {
                if didSubmit {
                    PrimaryButton(title: isLastQuestion ? "See results" : "Continue",
                                  systemImage: isLastQuestion ? "flag.checkered" : "arrow.right") {
                        advance()
                    }
                } else if model.current?.isTyped == true {
                    PrimaryButton(title: "Check",
                                  enabled: !typedAnswer.trimmingCharacters(in: .whitespaces).isEmpty) {
                        submit(typedAnswer)
                    }
                } else {
                    Text("Choose an answer")
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.inkFaint)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
        }
        .background(Theme.bg)
    }

    private var isLastQuestion: Bool { model.index + 1 >= model.questions.count }

    // MARK: - Actions

    private func submit(_ answer: String) {
        guard !didSubmit else { return }
        typingFocused = false
        let correct = model.submit(answer, store: store)
        if correct { Haptics.success() } else { Haptics.error() }
        withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8)) {
            didSubmit = true
        }
    }

    private func advance() {
        Haptics.tap()
        selectedOption = nil
        typedAnswer = ""
        didSubmit = false
        model.advance(store: store)
    }
}

// MARK: - Option row

struct OptionRow: View {
    enum State { case idle, selected, correct, wrong, dimmed }
    let text: String
    let state: State
    var isWord: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .font(isWord ? Theme.serif(18, .medium) : Theme.serif(15))
                    .foregroundStyle(foreground)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                if state == .correct { Image(systemName: "checkmark").foregroundStyle(Theme.good) }
                if state == .wrong { Image(systemName: "xmark").foregroundStyle(Theme.bad) }
            }
            .padding(15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(border, lineWidth: 1.5))
            .opacity(state == .dimmed ? 0.5 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(state == .correct ? [.isSelected] : [])
    }

    private var foreground: Color {
        switch state {
        case .correct: return Theme.good
        case .wrong:   return Theme.bad
        default:       return Theme.ink
        }
    }
    private var background: Color {
        switch state {
        case .selected: return Theme.accentSoft
        case .correct:  return Theme.good.opacity(0.12)
        case .wrong:    return Theme.bad.opacity(0.12)
        default:        return Theme.surface
        }
    }
    private var border: Color {
        switch state {
        case .selected: return Theme.accent
        case .correct:  return Theme.good
        case .wrong:    return Theme.bad
        default:        return Theme.hairline
        }
    }
}

// MARK: - Progress bar

struct ProgressBar: View {
    let fraction: Double
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.hairline)
                Capsule().fill(Theme.accent)
                    .frame(width: max(0, min(1, fraction)) * geo.size.width)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(fraction * 100)) percent")
    }
}
