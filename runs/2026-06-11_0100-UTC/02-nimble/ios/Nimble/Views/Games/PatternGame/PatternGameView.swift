import SwiftUI

// Simon-says: watch a color sequence, then repeat it
struct PatternGameView: View {
    let onComplete: (Int, Double, Int) -> Void

    @State private var phase: Phase = .intro
    @State private var sequence: [Int] = []
    @State private var userInput: [Int] = []
    @State private var highlightedIndex: Int? = nil
    @State private var roundsPlayed = 0
    @State private var correctRounds = 0
    @State private var level = 1
    @State private var startTime = Date()
    @State private var wrongIndex: Int? = nil

    enum Phase { case intro, showing, input, feedback(Bool), result }

    private let colors: [Color] = [.red, .blue, .green, .yellow]
    private let colorNames = ["Red","Blue","Green","Yellow"]

    var body: some View {
        VStack(spacing: 24) {
            switch phase {
            case .intro: introView
            case .showing: gameView(tappable: false)
            case .input: gameView(tappable: true)
            case .feedback(let correct): feedbackView(correct)
            case .result: resultView
            }
        }
        .padding()
        .navigationTitle("Pattern")
    }

    private var introView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "circle.grid.2x2")
                .font(.system(size: 60))
                .foregroundStyle(NimbleTheme.gamePink)
                .accessibilityHidden(true)
            Text("Pattern")
                .font(.system(size: 28, weight: .black, design: .rounded))
            Text("Watch the color sequence flash, then repeat it in the same order. 10 rounds.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
            Spacer()
            Button("Start") { startRound() }
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(NimbleTheme.gamePink)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    @ViewBuilder
    private func gameView(tappable: Bool) -> some View {
        VStack(spacing: 24) {
            if !tappable {
                Text("Watch the sequence…")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .accessibilityAddTraits(.isHeader)
            } else {
                VStack(spacing: 4) {
                    Text("Your turn! Tap in the same order.")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .accessibilityAddTraits(.isHeader)
                    Text("\(userInput.count) / \(sequence.count) tapped")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("\(userInput.count) of \(sequence.count) tapped")
                }
            }

            let cols = [GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: cols, spacing: 16) {
                ForEach(0..<4, id: \.self) { idx in
                    RoundedRectangle(cornerRadius: 16)
                        .fill(colors[idx].opacity(highlightedIndex == idx ? 1.0 : 0.35))
                        .aspectRatio(1.0, contentMode: .fit)
                        .overlay(
                            Text(colorNames[idx])
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        )
                        .scaleEffect(highlightedIndex == idx ? 0.93 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: highlightedIndex)
                        .onTapGesture {
                            guard tappable else { return }
                            handleInput(idx)
                        }
                        .accessibilityLabel(colorNames[idx])
                        .accessibilityAddTraits(tappable ? .isButton : [])
                }
            }
            .padding(.horizontal, 8)
        }
    }

    @ViewBuilder
    private func feedbackView(_ correct: Bool) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(correct ? .green : .red)
                .accessibilityLabel(correct ? "Correct" : "Wrong")
            Spacer()
        }
    }

    private var resultView: some View {
        VStack(spacing: 20) {
            Spacer()
            let score = min(100, Int(Double(correctRounds) / Double(roundsPlayed) * 100))
            Image(systemName: "circle.grid.2x2.fill")
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
            .background(NimbleTheme.gamePink)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: Logic

    private func startRound() {
        if startTime.timeIntervalSinceNow > -0.01 { startTime = Date() }
        let seqLength = max(2, level + 1)
        sequence = (0..<seqLength).map { _ in Int.random(in: 0..<4) }
        userInput = []
        playSequence()
    }

    private func playSequence() {
        phase = .showing
        var delay = 0.5
        for (i, idx) in sequence.enumerated() {
            let d = delay
            DispatchQueue.main.asyncAfter(deadline: .now() + d) {
                withAnimation { highlightedIndex = idx }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + d + 0.4) {
                withAnimation { highlightedIndex = nil }
            }
            delay += 0.65
            if i == sequence.count - 1 {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    phase = .input
                }
            }
        }
    }

    private func handleInput(_ idx: Int) {
        userInput.append(idx)
        let position = userInput.count - 1
        let expected = sequence[position]
        withAnimation { highlightedIndex = idx }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation { highlightedIndex = nil }
        }

        if idx != expected {
            // Wrong
            roundsPlayed += 1
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            phase = .feedback(false)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { advanceOrFinish() }
        } else if userInput.count == sequence.count {
            // Correct
            roundsPlayed += 1
            correctRounds += 1
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            phase = .feedback(true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { advanceOrFinish() }
        }
    }

    private func advanceOrFinish() {
        if roundsPlayed >= 10 {
            phase = .result
        } else {
            if correctRounds > 0 && correctRounds % 3 == 0 { level = min(10, level + 1) }
            startRound()
        }
    }
}
