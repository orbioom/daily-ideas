import SwiftUI

/// Word Scramble: scrambled letter tiles; tap them in order to rebuild the word.
/// Auto-checks when the build reaches full length. Runs for a fixed time.
struct AnagramGameView: View {
    let difficulty: Difficulty
    let duration: Int
    let onComplete: (PlayResult) -> Void

    private let game = Game.anagram

    @State private var scrambled: [Character] = []
    @State private var answer: String = ""
    @State private var used: [Bool] = []
    @State private var built: [Int] = []   // indices into scrambled, in tap order
    @State private var score = 0
    @State private var correct = 0
    @State private var attempted = 0
    @State private var timeRemaining: Int
    @State private var timer: Timer?
    @State private var feedback: FeedbackBadge.Kind?
    @State private var revealed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(difficulty: Difficulty, duration: Int, onComplete: @escaping (PlayResult) -> Void) {
        self.difficulty = difficulty
        self.duration = duration
        self.onComplete = onComplete
        _timeRemaining = State(initialValue: duration)
    }

    private var builtString: String { String(built.map { scrambled[$0] }) }

    var body: some View {
        ZStack {
            Brand.pageBackground
            VStack(spacing: 0) {
                GameHUD(game: game, timeRemaining: timeRemaining, totalTime: duration,
                        score: score, onQuit: finish)
                Spacer()
                Text(revealed ? "The word was" : "Unscramble")
                    .font(.subheadline).foregroundStyle(Brand.text2)
                builtRow
                Spacer().frame(height: 28)
                tileRow
                controls
                Spacer()
            }
            .padding(.bottom, 24)

            if let feedback, !reduceMotion {
                FeedbackBadge(kind: feedback).transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear { startTimer(); newWord() }
        .onDisappear { timer?.invalidate() }
    }

    private var builtRow: some View {
        HStack(spacing: 8) {
            ForEach(0..<answer.count, id: \.self) { slot in
                let ch: Character? = slot < built.count ? scrambled[built[slot]] : nil
                let isReveal = revealed
                let revealCh: Character? = isReveal ? Array(answer)[slot] : nil
                Text(String(revealCh ?? ch ?? " "))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .frame(width: 44, height: 54)
                    .foregroundStyle(isReveal ? Brand.live : Brand.text)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .strokeBorder((ch == nil && !isReveal) ? Brand.hairline : game.tint.opacity(0.6), lineWidth: 1.5))
            }
        }
        .padding(.top, 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(revealed ? "Answer was \(answer)" : "Built so far: \(builtString)")
    }

    private var tileRow: some View {
        let cols = Array(repeating: GridItem(.flexible(), spacing: 8),
                         count: min(scrambled.count, 4))
        return LazyVGrid(columns: cols, spacing: 8) {
            ForEach(scrambled.indices, id: \.self) { i in
                Button { useTile(i) } label: {
                    Text(String(scrambled[i]).uppercased())
                        .font(.title.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .foregroundStyle(used[safe: i] == true ? Brand.text3 : Brand.text)
                        .background((used[safe: i] == true) ? AnyShapeStyle(Brand.hairline.opacity(0.4)) : AnyShapeStyle(.ultraThinMaterial),
                                    in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled((used[safe: i] == true) || revealed)
                .accessibilityLabel("Letter \(String(scrambled[i]))")
            }
        }
        .padding(.horizontal, 36)
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button { undo() } label: { Label("Undo", systemImage: "arrow.uturn.backward") }
                .buttonStyle(GlassButtonStyle())
                .disabled(built.isEmpty || revealed)
            Button { skip() } label: { Label("Skip", systemImage: "forward.fill") }
                .buttonStyle(GlassButtonStyle())
                .disabled(revealed)
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }

    // MARK: - Logic

    private func newWord() {
        let s = QuestionGen.scramble(difficulty)
        scrambled = s.scrambled
        answer = s.answer
        used = Array(repeating: false, count: scrambled.count)
        built = []
        revealed = false
    }

    private func useTile(_ i: Int) {
        guard !(used[safe: i] ?? true), !revealed else { return }
        used[i] = true
        built.append(i)
        Haptics.selection()
        if built.count == answer.count { check() }
    }

    private func undo() {
        guard let last = built.popLast() else { return }
        used[last] = false
        Haptics.tap()
    }

    private func check() {
        attempted += 1
        if builtString == answer {
            correct += 1
            score += Int(Double(answer.count * 14) * difficulty.scoreMultiplier)
            feedback = .correct
            Haptics.success()
            advance(after: 0.5)
        } else {
            feedback = .wrong
            Haptics.warning()
            // Clear the build so they can retry the same word.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(reduceMotion ? nil : Brand.ease(0.25)) {
                    feedback = nil
                    used = Array(repeating: false, count: scrambled.count)
                    built = []
                }
            }
        }
    }

    private func skip() {
        attempted += 1
        revealed = true
        Haptics.tap()
        advance(after: 1.0)
    }

    private func advance(after delay: Double) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard timeRemaining > 0 else { return }
            withAnimation(reduceMotion ? nil : Brand.ease(0.3)) {
                feedback = nil
                newWord()
            }
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 { timeRemaining -= 1 } else { finish() }
        }
    }

    private func finish() {
        timer?.invalidate(); timer = nil
        onComplete(PlayResult(game: game, score: score, correct: correct, attempted: max(attempted, correct)))
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
