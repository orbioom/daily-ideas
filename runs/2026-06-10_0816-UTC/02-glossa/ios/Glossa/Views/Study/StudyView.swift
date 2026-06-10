import SwiftUI
import SwiftData

/// Full-screen study player: multiple choice for young cards, typed recall
/// for stronger ones, instant feedback with examples, and a summary.
struct StudyView: View {
    @Bindable var session: StudySession

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var typedAnswer = ""
    @State private var saved = false
    @FocusState private var typing: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if session.finished {
                    summary
                } else if let q = session.current {
                    question(q)
                } else {
                    // Defensive: an empty queue ends the session immediately.
                    EmptyStateView(icon: "checkmark.circle",
                                   title: "Nothing to study",
                                   message: "This deck has no cards ready right now.")
                }
            }
            .navigationTitle(session.deckName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        finishEarlyIfNeeded()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("End session")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Text("\(min(session.index + 1, session.total))/\(session.total)")
                        .font(Brand.mono(14, weight: .medium))
                        .foregroundStyle(Brand.text2)
                        .accessibilityLabel("Question \(min(session.index + 1, session.total)) of \(session.total)")
                }
            }
        }
        .interactiveDismissDisabled()
    }

    // MARK: Question

    private func question(_ q: StudyQuestion) -> some View {
        VStack(spacing: 16) {
            ProgressView(value: session.progress)
                .tint(Brand.live)
                .padding(.horizontal, 16)
                .accessibilityLabel("Session progress")

            Spacer()

            VStack(spacing: 10) {
                Eyebrow(text: q.isRelearn ? "Practice again" : (q.mode == .typed ? "Type the word" : "Pick the meaning"))
                Text(q.mode == .typed ? q.card.back : q.card.front)
                    .font(.system(size: 32, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Brand.text)
                    .minimumScaleFactor(0.5)
                if q.mode == .multipleChoice && !q.card.genderLabel.isEmpty {
                    Text(q.card.genderLabel)
                        .font(Brand.mono(12))
                        .foregroundStyle(Brand.text3)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            if let verdict = session.lastVerdict {
                feedback(verdict, for: q)
            } else if q.mode == .multipleChoice {
                choiceButtons(q)
            } else {
                typedField(q)
            }
        }
        .padding(.bottom, 24)
    }

    private func choiceButtons(_ q: StudyQuestion) -> some View {
        VStack(spacing: 10) {
            ForEach(q.options, id: \.self) { option in
                Button {
                    session.answer(choice: option)
                    haptic()
                } label: {
                    Text(option)
                        .font(.headline)
                        .foregroundStyle(Brand.text)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
    }

    private func typedField(_ q: StudyQuestion) -> some View {
        VStack(spacing: 10) {
            TextField("Type the \(languageName) word…", text: $typedAnswer)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($typing)
                .submitLabel(.done)
                .onSubmit { submitTyped() }
                .accessibilityHint("Enter your answer, then press done")
            Button("Check") { submitTyped() }
                .buttonStyle(InkButtonStyle())
                .disabled(typedAnswer.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 24)
        .onAppear { typing = true }
    }

    private var languageName: String {
        Lexicon.pack(code: session.languageCode)?.name ?? "target"
    }

    private func submitTyped() {
        guard !typedAnswer.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        session.answer(typed: typedAnswer)
        haptic()
    }

    private func haptic() {
        switch session.lastVerdict {
        case .correct, .almost: Haptics.success()
        case .wrong: Haptics.warning()
        case nil: break
        }
    }

    // MARK: Feedback

    private func feedback(_ verdict: AnswerVerdict, for q: StudyQuestion) -> some View {
        VStack(spacing: 12) {
            switch verdict {
            case .correct:
                Label("Correct", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundStyle(Brand.live)
            case .almost(let expected):
                VStack(spacing: 4) {
                    Label("Close — one letter off", systemImage: "checkmark.circle.badge.questionmark")
                        .font(.headline)
                        .foregroundStyle(Brand.warn)
                    Text(expected)
                        .font(Brand.mono(18, weight: .semibold))
                        .foregroundStyle(Brand.text)
                }
            case .wrong(let expected):
                VStack(spacing: 4) {
                    Label("Not quite", systemImage: "xmark.circle.fill")
                        .font(.headline)
                        .foregroundStyle(Brand.danger)
                    Text(expected)
                        .font(Brand.mono(18, weight: .semibold))
                        .foregroundStyle(Brand.text)
                }
            }

            if !q.card.exampleTarget.isEmpty {
                VStack(spacing: 4) {
                    Text(q.card.exampleTarget)
                        .font(.subheadline.italic())
                        .foregroundStyle(Brand.text2)
                    Text(q.card.exampleEnglish)
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                }
                .multilineTextAlignment(.center)
            }

            Button("Continue") {
                typedAnswer = ""
                withAnimation(reduceMotion ? nil : Brand.ease(0.3)) {
                    session.advance()
                }
                if session.finished { saveSession() }
            }
            .buttonStyle(InkButtonStyle())
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .strokeBorder(Brand.glassStroke.opacity(0.55), lineWidth: 1))
        .padding(.horizontal, 16)
        .accessibilityElement(children: .contain)
    }

    // MARK: Summary

    private var summary: some View {
        VStack(spacing: 20) {
            Spacer()
            StatusDot().scaleEffect(2)
            Text("Session complete")
                .font(.title.weight(.semibold))
                .foregroundStyle(Brand.text)
            VStack(spacing: 12) {
                row("Words reviewed", "\(session.correctCount + session.missedCount)")
                row("Correct", "\(session.correctCount)")
                row("To revisit", "\(session.missedCount)")
            }
            .glassCard()
            .padding(.horizontal, 24)
            Text(session.missedCount == 0
                 ? "Perfect run — every word moved up a box."
                 : "Missed words went back to box 1 and will review immediately.")
                .font(.subheadline)
                .foregroundStyle(Brand.text2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            Button("Done") { dismiss() }
                .buttonStyle(InkButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
        }
        .onAppear { saveSession() }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Brand.text2)
            Spacer()
            Text(value)
                .font(Brand.mono(16, weight: .semibold))
                .foregroundStyle(Brand.text)
        }
        .accessibilityElement(children: .combine)
    }

    private func saveSession() {
        guard !saved, session.correctCount + session.missedCount > 0 else { return }
        saved = true
        context.insert(ReviewSession(deckName: session.deckName,
                                     correct: session.correctCount,
                                     missed: session.missedCount))
    }

    private func finishEarlyIfNeeded() {
        // Leaving mid-session still records what was answered so far.
        saveSession()
    }
}
