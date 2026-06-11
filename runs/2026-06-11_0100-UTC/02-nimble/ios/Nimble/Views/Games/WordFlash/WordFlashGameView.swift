import SwiftUI

// Flash a word briefly, then answer a question about it
struct WordFlashGameView: View {
    let onComplete: (Int, Double, Int) -> Void

    @State private var phase: Phase = .intro
    @State private var flashWord = ""
    @State private var question = ""
    @State private var correctAnswer = ""
    @State private var choices: [String] = []
    @State private var flashDuration: Double = 1.5
    @State private var roundsPlayed = 0
    @State private var correctRounds = 0
    @State private var level = 1
    @State private var startTime = Date()

    enum Phase { case intro, flashing, question, feedback(Bool), result }

    private static let words = [
        "APPLE","BRIDGE","CLOUD","DANCE","EAGLE","FLAME","GHOST","HAPPY","IMAGE","JUMPY",
        "KNEEL","LAUGH","MAGIC","NIGHT","OCEAN","PIANO","QUEEN","RIVER","STORM","TIGER",
        "ULTRA","VIVID","WHALE","XENON","YOUTH","ZEBRA","BRAVE","CRISP","DEPTH","EARTH",
        "FLOCK","GRAIN","HASTE","ICING","JOUST","KINGS","LUNAR","MAPLE","NERVE","ORBIT",
        "PRISM","QUOTA","RESIN","SALVE","THYME","UNTIL","VENOM","WIDTH","EXACT","YOUNG",
        "ZONAL","BLAZE","CHESS","DIGIT","ENACT","FROTH","GLARE","HINGE","IRONY","JARRING"
    ]

    var body: some View {
        VStack(spacing: 24) {
            switch phase {
            case .intro: introView
            case .flashing: flashingView
            case .question: questionView
            case .feedback(let correct): feedbackView(correct: correct)
            case .result: resultView
            }
        }
        .padding()
        .navigationTitle("Words")
    }

    private var introView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "text.word.spacing")
                .font(.system(size: 60))
                .foregroundStyle(NimbleTheme.gameGreen)
                .accessibilityHidden(true)
            Text("Word Flash")
                .font(.system(size: 28, weight: .black, design: .rounded))
            Text("A word appears briefly. Then answer a question about it. 10 rounds.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
            Spacer()
            Button("Start") { nextRound() }
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(NimbleTheme.gameGreen)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var flashingView: some View {
        VStack(spacing: 0) {
            Spacer()
            Text(flashWord)
                .font(.system(size: 56, weight: .black, design: .rounded))
                .foregroundStyle(NimbleTheme.gameGreen)
                .transition(.opacity)
                .accessibilityLabel("Flash word: \(flashWord)")
            Spacer()
        }
    }

    private var questionView: some View {
        VStack(spacing: 20) {
            Spacer()
            Text(question)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            let cols = [GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: cols, spacing: 12) {
                ForEach(choices, id: \.self) { choice in
                    Button {
                        let correct = choice == correctAnswer
                        roundsPlayed += 1
                        if correct { correctRounds += 1 }
                        UINotificationFeedbackGenerator()
                            .notificationOccurred(correct ? .success : .error)
                        phase = .feedback(correct)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                            if roundsPlayed >= 10 {
                                phase = .result
                            } else {
                                if correctRounds > 0 && correctRounds % 3 == 0 {
                                    level = min(10, level + 1)
                                    flashDuration = max(0.6, flashDuration - 0.1)
                                }
                                nextRound()
                            }
                        }
                    } label: {
                        Text(choice)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Answer: \(choice)")
                }
            }
        }
    }

    @ViewBuilder
    private func feedbackView(correct: Bool) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(correct ? .green : .red)
                .accessibilityLabel(correct ? "Correct" : "Wrong. Answer was \(correctAnswer)")
            if !correct {
                Text("Answer: \(correctAnswer)")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var resultView: some View {
        VStack(spacing: 20) {
            Spacer()
            let score = min(100, Int(Double(correctRounds) / Double(roundsPlayed) * 100))
            Image(systemName: "text.magnifyingglass")
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
            .background(NimbleTheme.gameGreen)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: Logic

    private func nextRound() {
        if startTime.timeIntervalSinceNow > -0.01 { startTime = Date() }
        let word = Self.words.randomElement() ?? "APPLE"
        flashWord = word

        let (q, ans, opts) = makeQuestion(for: word)
        question = q
        correctAnswer = ans
        choices = opts

        phase = .flashing
        DispatchQueue.main.asyncAfter(deadline: .now() + flashDuration) {
            withAnimation(.easeInOut(duration: 0.2)) {
                phase = .question
            }
        }
    }

    private func makeQuestion(for word: String) -> (String, String, [String]) {
        let types = level <= 3 ? [0, 1] : level <= 6 ? [0, 1, 2] : [0, 1, 2, 3]
        let t = types.randomElement()!

        switch t {
        case 0: // How many letters?
            let ans = "\(word.count)"
            var opts = Set<String>([ans])
            while opts.count < 4 {
                let v = max(2, word.count + Int.random(in: -3...3))
                opts.insert("\(v)")
            }
            return ("How many letters?", ans, opts.shuffled())

        case 1: // Starts with which letter?
            let ans = String(word.prefix(1))
            var opts = Set<String>([ans])
            let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
            while opts.count < 4 {
                if let l = letters.randomElement() { opts.insert(String(l)) }
            }
            return ("What letter does it start with?", ans, opts.shuffled())

        case 2: // Does it contain a vowel?
            let vowels: Set<Character> = ["A","E","I","O","U"]
            let hasVowel = word.contains(where: { vowels.contains($0) })
            let ans = hasVowel ? "Yes" : "No"
            return ("Does it contain a vowel?", ans, ["Yes","No","Maybe","I forget"].shuffled())

        default: // Ends with which letter?
            let ans = String(word.suffix(1))
            var opts = Set<String>([ans])
            let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
            while opts.count < 4 {
                if let l = letters.randomElement() { opts.insert(String(l)) }
            }
            return ("What letter does it end with?", ans, opts.shuffled())
        }
    }
}
