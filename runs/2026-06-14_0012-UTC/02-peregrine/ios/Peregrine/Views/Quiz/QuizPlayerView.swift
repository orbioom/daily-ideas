import SwiftUI
import SwiftData

/// The quiz player. Owns a `QuizViewModel` for the given config and renders the
/// question card, choices, immediate feedback, and the results screen on finish.
struct QuizPlayerView: View {
    let config: QuizConfig

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var model: QuizViewModel?

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            content
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let model, model.phase == .playing {
                    Text("\(model.index + 1) / \(model.total)")
                        .font(Theme.rounded(15, .semibold))
                        .foregroundStyle(Theme.inkSoft)
                        .monospacedDigit()
                        .accessibilityLabel("Question \(model.index + 1) of \(model.total)")
                }
            }
        }
        .onAppear(perform: setup)
    }

    private var title: String {
        config.isDaily ? "Daily Challenge" : config.mode.shortTitle
    }

    private func setup() {
        guard model == nil else { return }
        let store = ProgressStore(context: modelContext)
        let timerOn = UserDefaults.standard.object(forKey: "timerEnabled") as? Bool ?? false
        model = QuizViewModel(mode: config.mode,
                              continent: config.continent,
                              isDaily: config.isDaily,
                              timerEnabled: timerOn,
                              length: config.length,
                              store: store)
    }

    @ViewBuilder
    private var content: some View {
        if let model {
            switch model.phase {
            case .loading:
                LoadingStateView(message: "Building your quiz…")
            case .empty(let message):
                EmptyStateView(systemImage: "exclamationmark.triangle",
                               title: "Can't start this quiz",
                               message: message,
                               actionTitle: "Go back") { dismiss() }
            case .playing:
                playing(model)
            case .finished:
                ResultsView(model: model, onRetry: retry, onClose: { dismiss() })
            }
        } else {
            LoadingStateView()
        }
    }

    private func playing(_ model: QuizViewModel) -> some View {
        VStack(spacing: 0) {
            QuizProgressBar(progress: model.progress, timer: model.timerEnabled ? model.elapsed : nil)
                .padding(.horizontal, 20)
                .padding(.top, 8)

            ScrollView {
                VStack(spacing: 22) {
                    if let q = model.current {
                        QuestionCard(question: q)
                        choiceList(model, question: q)
                    }
                }
                .padding(20)
            }

            if model.answered {
                feedbackBar(model)
            }
        }
    }

    private func choiceList(_ model: QuizViewModel, question: QuizQuestion) -> some View {
        VStack(spacing: 12) {
            ForEach(Array(question.choices.enumerated()), id: \.element.id) { idx, choice in
                ChoiceButton(
                    choice: choice,
                    state: choiceState(model, index: idx, question: question),
                    action: {
                        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
                            model.select(idx)
                        }
                    }
                )
                .disabled(model.answered)
            }
        }
    }

    private func choiceState(_ model: QuizViewModel, index: Int, question: QuizQuestion) -> ChoiceButton.State {
        guard model.answered else { return .idle }
        if index == question.answerIndex { return .correct }
        if index == model.selectedChoice { return .wrong }
        return .dimmed
    }

    private func feedbackBar(_ model: QuizViewModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: model.isCurrentCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(model.isCurrentCorrect ? Theme.good : Theme.bad)
                Text(model.isCurrentCorrect ? "Correct" : "Not quite")
                    .font(Theme.rounded(17, .bold))
                    .foregroundStyle(model.isCurrentCorrect ? Theme.good : Theme.bad)
                Spacer()
            }
            if let fact = model.feedbackFact() {
                Text(fact)
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            PrimaryButton(title: model.index + 1 >= model.total ? "See results" : "Next",
                          systemImage: "arrow.right") {
                withAnimation(reduceMotion ? nil : .easeInOut) { model.advance() }
            }
            .padding(.top, 2)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Theme.surface)
                .shadow(color: Color.black.opacity(0.08), radius: 14, y: -2)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
    }

    private func retry() {
        let store = ProgressStore(context: modelContext)
        let timerOn = UserDefaults.standard.object(forKey: "timerEnabled") as? Bool ?? false
        model = QuizViewModel(mode: config.mode,
                              continent: config.continent,
                              isDaily: config.isDaily,
                              timerEnabled: timerOn,
                              length: config.length,
                              store: store)
    }
}

/// Top progress bar with optional timer readout.
private struct QuizProgressBar: View {
    let progress: Double
    let timer: Double?

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.surfaceAlt)
                    Capsule().fill(Theme.accent)
                        .frame(width: max(4, geo.size.width * min(max(progress, 0), 1)))
                }
            }
            .frame(height: 6)
            if let timer {
                HStack {
                    Spacer()
                    Label(String(format: "%.0fs", timer), systemImage: "timer")
                        .font(Theme.rounded(12, .medium))
                        .foregroundStyle(Theme.inkSoft)
                        .monospacedDigit()
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(progress * 100)) percent")
    }
}
