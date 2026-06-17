import SwiftUI
import SwiftData

/// The full-screen exam/study player. Mock exams are exam-like (no feedback until
/// the end); study modes give instant feedback with explanations.
struct ExamSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var context
    @Environment(AppPreferences.self) private var prefs
    @Environment(SpeechManager.self) private var speech

    @State private var session: ExamSession
    /// Question ids whose stat has already been recorded (avoids double counting).
    @State private var recorded: Set<Int> = []
    @State private var confirmFinish = false
    @State private var confirmQuit = false

    init(session: ExamSession) {
        _session = State(initialValue: session)
    }

    private var instantFeedback: Bool { session.mode != .mock }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background(scheme).ignoresSafeArea()
                if session.finished {
                    ResultReviewView(session: session,
                                     onClose: { finishAndDismiss() },
                                     onRedoMissed: redoMissed)
                } else if let item = session.current {
                    player(for: item)
                } else {
                    EmptyStateCard(systemImage: "tray",
                                   title: "No questions",
                                   message: "There are no questions available for this session.")
                }
            }
            .navigationTitle(session.finished ? "Results" : session.mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !session.finished {
                        Button("Quit") { confirmQuit = true }
                            .tint(Theme.textSecondary(scheme))
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if !session.finished, let item = session.current {
                        Button {
                            session.toggleFlag()
                            Haptics.selection(enabled: prefs.hapticsEnabled)
                        } label: {
                            Image(systemName: item.flagged ? "flag.fill" : "flag")
                                .foregroundStyle(item.flagged ? Theme.gold : Theme.textSecondary(scheme))
                        }
                        .accessibilityLabel(item.flagged ? "Unflag question" : "Flag question")
                    }
                }
            }
            .confirmationDialog("Finish this exam now?", isPresented: $confirmFinish, titleVisibility: .visible) {
                Button("Finish & grade") { grade() }
                Button("Keep going", role: .cancel) {}
            } message: {
                let remaining = session.count - session.answeredCount
                Text(remaining > 0 ? "\(remaining) question(s) are unanswered and will be marked incorrect." : "All questions answered.")
            }
            .confirmationDialog("Quit without saving?", isPresented: $confirmQuit, titleVisibility: .visible) {
                Button("Quit", role: .destructive) { dismiss() }
                Button("Keep studying", role: .cancel) {}
            }
        }
        .interactiveDismissDisabled(!session.finished)
    }

    // MARK: Player

    @ViewBuilder
    private func player(for item: SessionItem) -> some View {
        VStack(spacing: 0) {
            header(for: item)
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    questionCard(item)
                    optionsList(item)
                    if instantFeedback && item.isAnswered {
                        explanationCard(item)
                    }
                }
                .padding(16)
            }
            controlBar(item)
        }
    }

    private func header(for item: SessionItem) -> some View {
        VStack(spacing: 8) {
            ProgressView(value: session.progress)
                .tint(Theme.accent)
            HStack {
                Text("Question \(session.index + 1) of \(session.count)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.textSecondary(scheme))
                Spacer()
                TopicChip(topic: item.question.topic)
                if session.mode.isTimed {
                    TimelineView(.periodic(from: session.startDate, by: 1)) { _ in
                        Label(timeString(session.elapsedSeconds), systemImage: "clock")
                            .font(.caption.weight(.medium).monospacedDigit())
                            .foregroundStyle(Theme.textSecondary(scheme))
                    }
                    .accessibilityLabel("Elapsed time \(session.elapsedSeconds) seconds")
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private func questionCard(_ item: SessionItem) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(item.question.prompt)
                .font(.system(.title3, design: .serif).weight(.semibold))
                .foregroundStyle(Theme.textPrimary(scheme))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            if prefs.readAloud {
                Button {
                    speech.speak(item.question.prompt + ". " + item.displayedOptions.joined(separator: ". "))
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .foregroundStyle(Theme.accent)
                }
                .accessibilityLabel("Read question aloud")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }

    private func optionsList(_ item: SessionItem) -> some View {
        VStack(spacing: 10) {
            ForEach(Array(item.displayedOptions.enumerated()), id: \.offset) { idx, text in
                OptionButton(
                    text: text,
                    letter: letter(idx),
                    state: optionState(item, idx),
                    locked: instantFeedback && item.isAnswered
                ) {
                    answer(idx)
                }
            }
        }
    }

    private func explanationCard(_ item: SessionItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(item.isCorrect ? "Correct" : "Not quite",
                  systemImage: item.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(item.isCorrect ? Theme.success(scheme) : Theme.danger(scheme))
            Text(item.question.explanation)
                .font(.subheadline)
                .foregroundStyle(Theme.textPrimary(scheme))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(secondary: true)
        .transition(.opacity)
    }

    private func controlBar(_ item: SessionItem) -> some View {
        HStack(spacing: 12) {
            Button {
                session.goPrev()
            } label: {
                Image(systemName: "chevron.left").font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .background(RoundedRectangle(cornerRadius: Theme.corner).strokeBorder(Theme.hairline(scheme)))
            .foregroundStyle(session.isFirst ? Theme.textSecondary(scheme).opacity(0.5) : Theme.accent)
            .disabled(session.isFirst)
            .accessibilityLabel("Previous question")

            if session.isLast {
                Button {
                    if session.allAnswered { grade() } else { confirmFinish = true }
                } label: {
                    Text("Finish").frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
            } else {
                Button { session.goNext() } label: {
                    Text("Next").frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
    }

    // MARK: Actions

    private func answer(_ presentationIdx: Int) {
        guard let item = session.current else { return }
        // In instant-feedback modes, lock after the first answer.
        if instantFeedback && item.isAnswered { return }
        session.select(presentationIdx)
        guard let updated = session.current else { return }
        if instantFeedback {
            recordIfNeeded(updated)
            Haptics.success(enabled: prefs.hapticsEnabled && updated.isCorrect)
            if !updated.isCorrect { Haptics.warning(enabled: prefs.hapticsEnabled) }
        } else {
            Haptics.selection(enabled: prefs.hapticsEnabled)
        }
    }

    private func recordIfNeeded(_ item: SessionItem) {
        guard !recorded.contains(item.id) else { return }
        recorded.insert(item.id)
        StatStore.record(questionId: item.id, correct: item.isCorrect, in: context)
    }

    private func optionState(_ item: SessionItem, _ idx: Int) -> OptionButton.State {
        guard item.isAnswered else { return .idle }
        let revealed = instantFeedback // mock hides correctness until end
        if !revealed {
            return item.selected == idx ? .selected : .idle
        }
        if idx == item.correctPresentationIndex { return .correct }
        if item.selected == idx { return .incorrect }
        return .idle
    }

    private func grade() {
        // For mock, record all answered questions now.
        if !instantFeedback {
            for item in session.items where item.isAnswered {
                if !recorded.contains(item.id) {
                    recorded.insert(item.id)
                    StatStore.record(questionId: item.id, correct: item.isCorrect, in: context)
                }
            }
        }
        session.finish()
        let result = ExamResult(
            modeRaw: session.mode.rawValue,
            topicRaw: session.topic?.rawValue,
            score: session.correctCount,
            total: session.count,
            durationSeconds: session.elapsedSeconds,
            passed: session.passed
        )
        context.insert(result)
        try? context.save()
        Haptics.success(enabled: prefs.hapticsEnabled && session.passed)
        speech.stop()
    }

    private func redoMissed() {
        let wrongIds = session.items.filter { $0.isAnswered && !$0.isCorrect }.map { $0.id }
        let bank = QuestionBank.all
        let pool = bank.filter { wrongIds.contains($0.id) }
        guard !pool.isEmpty else { dismiss(); return }
        let items = pool.map { q -> SessionItem in
            let order = prefs.shuffleOptions ? Array(0..<q.options.count).shuffled() : Array(0..<q.options.count)
            return SessionItem(id: q.id, question: q, order: order)
        }
        recorded.removeAll()
        session = ExamSession(mode: .review, topic: nil, passPercent: prefs.passPercent, items: items)
    }

    private func finishAndDismiss() {
        speech.stop()
        dismiss()
    }

    private func timeString(_ seconds: Int) -> String {
        let m = seconds / 60, s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }

    private func letter(_ idx: Int) -> String {
        let letters = ["A", "B", "C", "D", "E", "F"]
        return letters[safe: idx] ?? "?"
    }
}

/// A single answer option button with idle/selected/correct/incorrect states.
struct OptionButton: View {
    enum State { case idle, selected, correct, incorrect }

    let text: String
    let letter: String
    let state: State
    let locked: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var scheme

    private var fill: Color {
        switch state {
        case .idle: return Theme.card(scheme)
        case .selected: return Theme.accent.opacity(0.18)
        case .correct: return Theme.success(scheme).opacity(0.20)
        case .incorrect: return Theme.danger(scheme).opacity(0.18)
        }
    }
    private var border: Color {
        switch state {
        case .idle: return Theme.hairline(scheme)
        case .selected: return Theme.accent
        case .correct: return Theme.success(scheme)
        case .incorrect: return Theme.danger(scheme)
        }
    }
    private var symbol: String? {
        switch state {
        case .correct: return "checkmark.circle.fill"
        case .incorrect: return "xmark.circle.fill"
        default: return nil
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(letter)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(state == .idle ? Theme.textSecondary(scheme) : border)
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(border.opacity(0.15)))
                Text(text)
                    .font(.body)
                    .foregroundStyle(Theme.textPrimary(scheme))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                if let symbol {
                    Image(systemName: symbol)
                        .foregroundStyle(border)
                }
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous).fill(fill))
            .overlay(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous).strokeBorder(border, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
        .disabled(locked)
        .accessibilityLabel("Option \(letter): \(text)")
        .accessibilityAddTraits(state == .selected || state == .correct ? .isSelected : [])
    }
}
