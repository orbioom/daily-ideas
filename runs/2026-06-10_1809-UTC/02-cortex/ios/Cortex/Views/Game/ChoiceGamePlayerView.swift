import SwiftUI

/// Timed multiple-choice game player shared by Quick Math, Color Focus, and
/// Next in Line. Generates a fresh question after each answer; scores correct
/// answers with a streak bonus.
struct ChoiceGamePlayerView: View {
    let game: Game
    let difficulty: Difficulty
    let duration: Int
    let onComplete: (PlayResult) -> Void

    @State private var question: ChoiceQuestion
    @State private var timeRemaining: Int
    @State private var score = 0
    @State private var correct = 0
    @State private var attempted = 0
    @State private var streak = 0
    @State private var feedback: FeedbackBadge.Kind?
    @State private var lockedChoice: Int?
    @State private var timer: Timer?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(game: Game, difficulty: Difficulty, duration: Int, onComplete: @escaping (PlayResult) -> Void) {
        self.game = game
        self.difficulty = difficulty
        self.duration = duration
        self.onComplete = onComplete
        _question = State(initialValue: ChoiceGamePlayerView.generate(game, difficulty))
        _timeRemaining = State(initialValue: duration)
    }

    static func generate(_ game: Game, _ d: Difficulty) -> ChoiceQuestion {
        switch game {
        case .math: return QuestionGen.math(d)
        case .focus: return QuestionGen.focus(d)
        case .logic: return QuestionGen.logic(d)
        default: return QuestionGen.math(d)
        }
    }

    var body: some View {
        ZStack {
            Brand.pageBackground
            VStack(spacing: 0) {
                GameHUD(game: game, timeRemaining: timeRemaining, totalTime: duration,
                        score: score, onQuit: finish)
                Spacer()
                promptView
                Spacer()
                choicesGrid
                streakLine
            }
            .padding(.bottom, 24)

            if let feedback, !reduceMotion {
                FeedbackBadge(kind: feedback)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear(perform: startTimer)
        .onDisappear { timer?.invalidate() }
    }

    private var promptView: some View {
        VStack(spacing: 8) {
            Text(game == .focus ? "Tap the INK color" : (game == .logic ? "What comes next?" : "Solve"))
                .font(.subheadline)
                .foregroundStyle(Brand.text2)
            Text(question.prompt)
                .font(.system(size: game == .logic ? 30 : 56, weight: .bold, design: .rounded))
                .foregroundStyle(promptColor)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, 24)
                .accessibilityLabel(promptAccessibility)
        }
    }

    private var promptColor: Color {
        if game == .focus, let name = question.promptColorName {
            return GameColors.color(name)
        }
        return Brand.text
    }

    private var promptAccessibility: String {
        if game == .focus, let ink = question.promptColorName {
            return "The word \(question.prompt) shown in \(ink) ink"
        }
        return question.prompt
    }

    private var choicesGrid: some View {
        let cols = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        return LazyVGrid(columns: cols, spacing: 12) {
            ForEach(question.choices.indices, id: \.self) { i in
                Button { answer(i) } label: {
                    Text(question.choices[i])
                        .font(.title2.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 22)
                }
                .buttonStyle(ChoiceButtonStyle(state: stateFor(i), tint: game.tint))
                .disabled(lockedChoice != nil)
            }
        }
        .padding(.horizontal, 20)
    }

    private func stateFor(_ i: Int) -> ChoiceButtonStyle.State {
        guard let locked = lockedChoice else { return .idle }
        if i == question.answerIndex { return .right }
        if i == locked { return .wrong }
        return .idle
    }

    private var streakLine: some View {
        Text(streak >= 2 ? "🔥 \(streak) in a row" : " ")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Brand.magic)
            .padding(.top, 10)
            .accessibilityHidden(streak < 2)
    }

    // MARK: - Logic

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                finish()
            }
        }
    }

    private func answer(_ i: Int) {
        guard lockedChoice == nil else { return }
        attempted += 1
        lockedChoice = i
        let isRight = (i == question.answerIndex)
        if isRight {
            correct += 1
            streak += 1
            let base = 10
            let bonus = min(streak - 1, 5) * 2   // up to +10 streak bonus
            score += Int(Double(base + bonus) * difficulty.scoreMultiplier)
            feedback = .correct
            Haptics.tap()
        } else {
            streak = 0
            feedback = .wrong
            Haptics.warning()
        }
        // Brief pause to show feedback, then next question.
        DispatchQueue.main.asyncAfter(deadline: .now() + (isRight ? 0.32 : 0.6)) {
            withAnimation(reduceMotion ? nil : Brand.ease(0.25)) {
                feedback = nil
                lockedChoice = nil
                question = ChoiceGamePlayerView.generate(game, difficulty)
            }
        }
    }

    private func finish() {
        timer?.invalidate()
        timer = nil
        onComplete(PlayResult(game: game, score: score, correct: correct, attempted: attempted))
    }
}

struct ChoiceButtonStyle: ButtonStyle {
    enum State { case idle, right, wrong }
    let state: State
    let tint: Color
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(fg)
            .background(bg, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(border, lineWidth: 1.5))
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .animation(Brand.ease(0.2), value: configuration.isPressed)
    }

    private var fg: Color {
        switch state { case .idle: Brand.text; case .right: .white; case .wrong: .white }
    }
    private var bg: AnyShapeStyle {
        switch state {
        case .idle: AnyShapeStyle(.ultraThinMaterial)
        case .right: AnyShapeStyle(Brand.live)
        case .wrong: AnyShapeStyle(Brand.danger)
        }
    }
    private var border: Color {
        switch state { case .idle: Brand.glassStroke.opacity(0.5); default: .clear }
    }
}
