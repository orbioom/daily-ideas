import SwiftUI
import SwiftData

struct QuizContainerView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var session: QuizSession
    @State private var saved = false

    init(questions: [PlayableQuestion], mode: GameMode, category: TriviaCategory?) {
        _session = State(initialValue: QuizSession(questions: questions, mode: mode, category: category))
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            if session.finished {
                ResultsView(session: session, onDone: { dismiss() })
            } else {
                QuestionView(session: session)
            }
        }
        .onAppear { if !session.finished { session.start() } }
        .onChange(of: session.finished) { _, done in if done { saveResult() } }
        .interactiveDismissDisabled(!session.finished)
    }

    private func saveResult() {
        guard !saved else { return }
        saved = true
        let result = GameResult(mode: session.mode, category: session.category,
                                score: session.score, correct: session.correctCount,
                                total: session.questions.count)
        context.insert(result)
        try? context.save()
    }
}

private struct QuestionView: View {
    @Bindable var session: QuizSession
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("showFacts") private var showFacts = true

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: 20) {
                    Pill(text: session.current.category.label, color: Theme.accent)
                        .padding(.top, 8)
                    Text(session.current.prompt)
                        .font(Theme.serif(24, .bold))
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                        .accessibilityAddTraits(.isHeader)

                    VStack(spacing: 12) {
                        ForEach(session.current.choices.indices, id: \.self) { i in
                            ChoiceButton(
                                text: session.current.choices[i],
                                state: state(for: i),
                                action: { withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) { session.choose(i) } })
                            .disabled(session.revealed)
                        }
                    }

                    if session.revealed { feedback }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
        }
    }

    private func state(for i: Int) -> ChoiceState {
        guard session.revealed else { return .idle }
        if i == session.current.answerIndex { return .correct }
        if i == session.selected { return .wrong }
        return .dimmed
    }

    private var header: some View {
        VStack(spacing: 10) {
            HStack {
                Button { session.stop(); dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 16, weight: .bold)).foregroundStyle(Theme.inkSoft)
                }
                .accessibilityLabel("Quit quiz")
                Spacer()
                Text("Question \(session.questionNumber) of \(session.questions.count)")
                    .font(Theme.rounded(14, .bold)).foregroundStyle(Theme.inkSoft)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "star.fill").font(.system(size: 12)).foregroundStyle(Theme.gold)
                    Text("\(session.score)").font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                }
            }
            if session.timed {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.surfaceAlt)
                        Capsule().fill(timerColor)
                            .frame(width: CGFloat(session.secondsLeft) / CGFloat(QuizEngine.perQuestionSeconds) * geo.size.width)
                            .animation(reduceMotion ? nil : .linear(duration: 0.3), value: session.secondsLeft)
                    }
                }
                .frame(height: 8)
                .accessibilityLabel("\(session.secondsLeft) seconds left")
            } else {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.surfaceAlt)
                        Capsule().fill(Theme.accent).frame(width: session.progress * geo.size.width)
                    }
                }
                .frame(height: 8)
                .accessibilityLabel("Progress")
            }
        }
        .padding(.horizontal, 20).padding(.top, 14).padding(.bottom, 6)
    }

    private var timerColor: Color {
        if session.revealed { return Theme.inkFaint }
        return session.secondsLeft <= 5 ? Theme.bad : Theme.accent
    }

    private var feedback: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: session.selected == session.current.answerIndex ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(session.selected == session.current.answerIndex ? Theme.good : Theme.bad)
                Text(session.selected == nil ? "Time’s up!"
                     : (session.selected == session.current.answerIndex ? "Correct!" : "Not quite"))
                    .font(Theme.rounded(18, .bold)).foregroundStyle(Theme.ink)
            }
            if showFacts {
                Text(session.current.fact)
                    .font(Theme.rounded(14, .regular)).foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
            }
            Button { session.next() } label: {
                Text(session.index < session.questions.count - 1 ? "Next question" : "See results")
                    .font(Theme.rounded(17, .bold)).frame(maxWidth: .infinity).padding(.vertical, 15)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .foregroundStyle(.white)
            }
        }
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .transition(.opacity)
    }
}

enum ChoiceState { case idle, correct, wrong, dimmed }

private struct ChoiceButton: View {
    let text: String
    let state: ChoiceState
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(text).font(Theme.rounded(17, .semibold)).foregroundStyle(fg)
                    .multilineTextAlignment(.leading)
                Spacer()
                if state == .correct { Image(systemName: "checkmark.circle.fill").foregroundStyle(.white) }
                else if state == .wrong { Image(systemName: "xmark.circle.fill").foregroundStyle(.white) }
            }
            .padding(.horizontal, 18).padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(bg, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(border, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
        .opacity(state == .dimmed ? 0.5 : 1)
    }

    private var bg: Color {
        switch state {
        case .idle, .dimmed: return Theme.surface
        case .correct: return Theme.good
        case .wrong: return Theme.bad
        }
    }
    private var fg: Color {
        switch state {
        case .correct, .wrong: return .white
        default: return Theme.ink
        }
    }
    private var border: Color {
        switch state {
        case .idle, .dimmed: return Theme.hairline
        case .correct: return Theme.good
        case .wrong: return Theme.bad
        }
    }
}

private struct ResultsView: View {
    let session: QuizSession
    let onDone: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    private var accuracy: Double {
        session.questions.isEmpty ? 0 : Double(session.correctCount) / Double(session.questions.count)
    }
    private var message: String {
        switch accuracy {
        case 1.0: return "Flawless! A perfect round."
        case 0.8...: return "Brilliant work — nearly perfect."
        case 0.6..<0.8: return "Solid round. You know your stuff."
        case 0.4..<0.6: return "Not bad — room to climb."
        default: return "Tough one. Try again to bounce back."
        }
    }
    private var shareText: String {
        "Savant \(session.mode == .daily ? "Daily" : "Practice") — \(session.correctCount)/\(session.questions.count) for \(session.score) pts 🧠"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Image(systemName: accuracy >= 0.8 ? "trophy.fill" : "rosette")
                    .font(.system(size: 54)).foregroundStyle(Theme.gold)
                    .padding(.top, 36)
                    .scaleEffect(appeared || reduceMotion ? 1 : 0.6)
                    .accessibilityHidden(true)
                Text(message).font(Theme.serif(24, .bold)).foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center).padding(.horizontal, 20)

                Text("\(session.score)").font(Theme.rounded(56, .bold)).foregroundStyle(Theme.accent)
                Text("points").font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.inkSoft)

                HStack(spacing: 10) {
                    StatTile(value: "\(session.correctCount)/\(session.questions.count)", label: "Correct", accent: Theme.good)
                    StatTile(value: "\(Int(accuracy * 100))%", label: "Accuracy", accent: Theme.accent)
                    StatTile(value: "\(session.bestStreak)", label: "Best streak", accent: Theme.gold)
                }
                .padding(.horizontal, 20)

                VStack(spacing: 10) {
                    ShareLink(item: shareText) {
                        Label("Share result", systemImage: "square.and.arrow.up")
                            .font(Theme.rounded(16, .bold)).frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(Theme.surfaceAlt, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .foregroundStyle(Theme.ink)
                    }
                    Button { Haptics.tap(); onDone() } label: {
                        Text("Done").font(Theme.rounded(17, .bold)).frame(maxWidth: .infinity).padding(.vertical, 15)
                            .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .foregroundStyle(.white)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 30)
        }
        .onAppear { withAnimation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.6)) { appeared = true } }
    }
}
