import SwiftUI
import SwiftData

/// The full-screen active drill session.
struct DrillView: View {
    let language: Language
    let mode: AnswerMode
    let accentStrict: Bool
    let sessionLength: Int
    let enabledTenses: Set<String>
    let verbs: [Verb]
    let existingStats: [ItemStat]

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage(Prefs.haptics) private var haptics = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var engine = DrillEngine()
    @State private var started = false
    @State private var couldStart = true
    @State private var typedAnswer = ""
    @State private var feedback: GradeResult?
    @FocusState private var fieldFocused: Bool

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            content
        }
        .onAppear {
            guard !started else { return }
            started = true
            couldStart = engine.start(language: language,
                                      mode: mode,
                                      accentStrict: accentStrict,
                                      sessionLength: sessionLength,
                                      enabledTenses: enabledTenses,
                                      verbs: verbs,
                                      existingStats: existingStats)
            if mode == .type { fieldFocused = true }
        }
    }

    @ViewBuilder
    private var content: some View {
        if !couldStart {
            VStack(spacing: 16) {
                EmptyStateView(symbol: "tray",
                               title: "Nothing to drill",
                               message: "No verbs or tenses are available for this session. Adjust your settings and try again.")
                Button("Close") { dismiss() }
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.accent)
                    .padding(.bottom, 30)
            }
        } else if engine.isFinished {
            DrillSummaryView(correct: engine.correctCount,
                             total: engine.answered,
                             elapsed: Int(Date.now.timeIntervalSince(engine.startDate)),
                             reviewItems: engine.reviewItems,
                             onDone: {
                                 engine.finishSession(context: context)
                                 dismiss()
                             })
        } else {
            activeDrill
        }
    }

    private var activeDrill: some View {
        VStack(spacing: 0) {
            header
            Spacer(minLength: 12)
            if let q = engine.current {
                questionCard(q)
            }
            Spacer(minLength: 12)
            answerArea
        }
        .padding(20)
    }

    private var header: some View {
        VStack(spacing: 10) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.inkSoft)
                }
                .accessibilityLabel("End session")
                Spacer()
                Text("\(engine.answered)/\(engine.sessionLength)")
                    .font(Theme.rounded(15, .semibold).monospacedDigit())
                    .foregroundStyle(Theme.inkSoft)
            }
            ProgressView(value: engine.progress)
                .tint(Theme.accent)
        }
    }

    private func questionCard(_ q: DrillQuestion) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                Pill(text: q.tense.displayName, tint: Theme.accent)
                Pill(text: q.verb.language.displayName, systemImage: nil, tint: Theme.inkSoft)
            }
            VStack(spacing: 6) {
                Text(q.person.pronoun)
                    .font(Theme.serif(22, .semibold))
                    .foregroundStyle(Theme.accent)
                Text(q.verb.infinitive)
                    .font(Theme.serif(34, .bold))
                    .foregroundStyle(Theme.ink)
                Text(q.verb.meaning)
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
            }
            Text("Conjugate for \(q.person.pronoun)")
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.inkFaint)
        }
        .frame(maxWidth: .infinity)
        .padding(26)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.surface))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Conjugate \(q.verb.infinitive) for \(q.person.pronoun) in \(q.tense.displayName)")
    }

    @ViewBuilder
    private var answerArea: some View {
        if let fb = feedback {
            feedbackView(fb)
        } else if let q = engine.current {
            switch mode {
            case .type:
                typeArea(q)
            case .choice:
                choiceArea(q)
            }
        }
    }

    private func typeArea(_ q: DrillQuestion) -> some View {
        VStack(spacing: 14) {
            TextField("Type the conjugation", text: $typedAnswer)
                .font(Theme.rounded(22, .medium))
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .focused($fieldFocused)
                .padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.surfaceAlt))
                .onSubmit { grade(typedAnswer, q: q) }
            PrimaryButton(title: "Check", isEnabled: !typedAnswer.trimmingCharacters(in: .whitespaces).isEmpty) {
                grade(typedAnswer, q: q)
            }
        }
    }

    private func choiceArea(_ q: DrillQuestion) -> some View {
        VStack(spacing: 10) {
            ForEach(Array(q.choices.enumerated()), id: \.offset) { _, choice in
                Button {
                    grade(choice, q: q)
                } label: {
                    Text(choice)
                        .font(Theme.rounded(18, .medium))
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.surface))
                }
            }
        }
    }

    private func feedbackView(_ fb: GradeResult) -> some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: fb.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(fb.isCorrect ? Theme.good : Theme.bad)
                    .accessibilityHidden(true)
                Text(fb.isCorrect ? "Correct" : "Not quite")
                    .font(Theme.serif(20, .bold))
                    .foregroundStyle(fb.isCorrect ? Theme.good : Theme.bad)
            }
            if !fb.isCorrect {
                VStack(spacing: 4) {
                    Text("Correct answer")
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkSoft)
                    Text(fb.correctAnswer)
                        .font(Theme.rounded(24, .bold))
                        .foregroundStyle(Theme.ink)
                }
            }
            PrimaryButton(title: engine.answered >= engine.sessionLength ? "See results" : "Next") {
                advance()
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(fb.isCorrect ? Theme.good.opacity(0.12) : Theme.bad.opacity(0.12))
        )
        .transition(reduceMotion ? .identity : .opacity)
    }

    // MARK: - Actions

    private func grade(_ answer: String, q: DrillQuestion) {
        guard feedback == nil else { return }
        let trimmed = answer.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let result = engine.submit(trimmed, context: context)
        feedback = result
        fieldFocused = false
        if let result {
            if result.isCorrect { Haptics.success(haptics) } else { Haptics.error(haptics) }
        }
    }

    private func advance() {
        feedback = nil
        typedAnswer = ""
        if !engine.isFinished, mode == .type {
            fieldFocused = true
        }
    }
}
