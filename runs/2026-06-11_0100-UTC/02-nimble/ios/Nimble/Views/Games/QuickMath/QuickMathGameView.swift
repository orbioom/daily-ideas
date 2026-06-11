import SwiftUI

// Arithmetic questions with 4 multiple-choice answers — speed + accuracy
struct QuickMathGameView: View {
    let onComplete: (Int, Double, Int) -> Void

    @State private var phase: Phase = .intro
    @State private var question = ""
    @State private var correctAnswer = 0
    @State private var choices: [Int] = []
    @State private var timeLeft: Double = 10
    @State private var roundsPlayed = 0
    @State private var correctRounds = 0
    @State private var level = 1
    @State private var startTime = Date()
    @State private var choiceResult: Int? = nil  // index of tapped choice
    @State private var timer: Timer? = nil

    enum Phase { case intro, question, feedback, result }

    var body: some View {
        VStack(spacing: 24) {
            switch phase {
            case .intro: introView
            case .question: questionView
            case .feedback: feedbackView
            case .result: resultView
            }
        }
        .padding()
        .navigationTitle("Math")
        .onDisappear { timer?.invalidate() }
    }

    // MARK: Intro
    private var introView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "plus.forwardslash.minus")
                .font(.system(size: 60))
                .foregroundStyle(NimbleTheme.gameOrange)
                .accessibilityHidden(true)
            Text("Quick Math")
                .font(.system(size: 28, weight: .black, design: .rounded))
            Text("Solve 10 arithmetic problems as fast as you can. Pick the right answer from 4 options.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
            Spacer()
            Button("Start") { nextQuestion() }
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(NimbleTheme.gameOrange)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: Question
    private var questionView: some View {
        VStack(spacing: 20) {
            ProgressView(value: timeLeft, total: 10)
                .tint(timeLeft > 5 ? NimbleTheme.gameOrange : .red)
                .scaleEffect(x: 1, y: 3, anchor: .center)
                .accessibilityLabel("\(Int(timeLeft)) seconds remaining")

            Text("Round \(roundsPlayed + 1)/10")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
            Text(question)
                .font(.system(size: 48, weight: .black, design: .rounded))
                .accessibilityLabel("Question: \(question)")

            Text("= ?")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
            Spacer()

            let cols = [GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: cols, spacing: 12) {
                ForEach(choices.indices, id: \.self) { i in
                    Button {
                        submitAnswer(choices[i])
                    } label: {
                        Text("\(choices[i])")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Answer: \(choices[i])")
                }
            }
        }
    }

    // MARK: Feedback
    private var feedbackView: some View {
        VStack(spacing: 16) {
            Spacer()
            if choiceResult == correctAnswer {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.green)
                    .accessibilityLabel("Correct!")
                Text("Correct!")
                    .font(.system(size: 28, weight: .black, design: .rounded))
            } else {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.red)
                    .accessibilityLabel("Wrong. Correct answer: \(correctAnswer)")
                VStack(spacing: 4) {
                    Text("Wrong!")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                    Text("Answer: \(correctAnswer)")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
    }

    // MARK: Result
    private var resultView: some View {
        VStack(spacing: 20) {
            Spacer()
            let score = min(100, Int(Double(correctRounds) / Double(roundsPlayed) * 100))
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 56))
                .foregroundStyle(NimbleTheme.scoreColor(score))
                .accessibilityHidden(true)
            Text("\(score)")
                .font(.system(size: 72, weight: .black, design: .rounded))
                .foregroundStyle(NimbleTheme.scoreColor(score))
                .accessibilityLabel("Score: \(score) out of 100")
            Text("\(correctRounds)/\(roundsPlayed) correct")
                .foregroundStyle(.secondary)
            Spacer()
            Button("Done") {
                let duration = Date().timeIntervalSince(startTime)
                onComplete(min(100, Int(Double(correctRounds) / Double(roundsPlayed) * 100)), duration, level)
            }
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(NimbleTheme.gameOrange)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: Logic

    private func nextQuestion() {
        startTime = startTime == Date() ? Date() : startTime
        let (q, ans) = generateQuestion()
        question = q
        correctAnswer = ans
        choices = generateChoices(correct: ans)
        choiceResult = nil
        timeLeft = 10
        phase = .question

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            timeLeft -= 0.1
            if timeLeft <= 0 {
                timer?.invalidate()
                submitAnswer(nil)
            }
        }
    }

    private func submitAnswer(_ choice: Int?) {
        timer?.invalidate()
        choiceResult = choice
        roundsPlayed += 1
        let correct = choice == correctAnswer
        if correct {
            correctRounds += 1
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }

        phase = .feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            if roundsPlayed >= 10 {
                phase = .result
            } else {
                if correctRounds > 0 && correctRounds % 3 == 0 {
                    level = min(10, level + 1)
                }
                nextQuestion()
            }
        }
    }

    private func generateQuestion() -> (String, Int) {
        let ops: [Character]
        if level <= 3 { ops = ["+", "-"] }
        else if level <= 6 { ops = ["+", "-", "*"] }
        else { ops = ["+", "-", "*", "/"] }

        let op = ops.randomElement()!
        let (a, b, ans): (Int, Int, Int)

        switch op {
        case "+":
            let max = level <= 3 ? 20 : level <= 6 ? 50 : 100
            a = Int.random(in: 1...max); b = Int.random(in: 1...max)
            ans = a + b
        case "-":
            let max = level <= 3 ? 20 : 50
            let big = Int.random(in: 1...max); let small = Int.random(in: 1...big)
            a = big; b = small; ans = a - b
        case "*":
            let max = level <= 6 ? 10 : 15
            a = Int.random(in: 2...max); b = Int.random(in: 2...max)
            ans = a * b
        default: // "/"
            b = Int.random(in: 2...10)
            ans = Int.random(in: 2...12)
            a = b * ans
        }
        return ("\(a) \(op) \(b)", ans)
    }

    private func generateChoices(correct: Int) -> [Int] {
        var set: Set<Int> = [correct]
        while set.count < 4 {
            let offset = Int.random(in: -10...10)
            let candidate = correct + offset
            if candidate != correct { set.insert(candidate) }
        }
        return set.shuffled()
    }
}
