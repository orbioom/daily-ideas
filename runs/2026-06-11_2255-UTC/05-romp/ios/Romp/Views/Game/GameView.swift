import SwiftUI
import SwiftData

struct GameView: View {
    let deck: PlayableDeck
    let roundSeconds: Int

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("tiltControls") private var tiltControls = true

    @State private var engine: GameEngine?
    @State private var saved = false

    var body: some View {
        ZStack {
            background
            if let engine {
                switch engine.phase {
                case .getReady(let remaining):
                    getReadyView(remaining)
                case .playing, .flash:
                    playView(engine)
                case .finished:
                    RoundRecapView(engine: engine, saved: $saved, onSave: saveResult) {
                        dismiss()
                    }
                }
            }
        }
        .statusBarHidden(true)
        .onAppear {
            let e = GameEngine(deck: deck, roundSeconds: roundSeconds, tiltEnabled: tiltControls)
            e.onCorrect = { Haptics.correct() }
            e.onPass = { Haptics.pass() }
            engine = e
            e.begin()
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            engine?.cancel()
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    private var background: some View {
        Group {
            if let engine, case .flash(let correct) = engine.phase {
                (correct ? Theme.correct : Theme.pass)
            } else {
                Theme.accent
            }
        }
        .ignoresSafeArea()
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: flashKey)
    }

    private var flashKey: Bool {
        if let engine, case .flash = engine.phase { return true }
        return false
    }

    private func getReadyView(_ remaining: Int) -> some View {
        VStack(spacing: 18) {
            Text(deck.emoji)
                .font(.system(size: 56))
                .accessibilityHidden(true)
            Text(deck.name)
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
            Text(tiltControls && engine?.tilt == .available
                 ? "Hold the phone to your forehead, screen out.\nTilt DOWN for correct · UP to pass."
                 : "Show the screen to the guesser.\nUse the buttons to score.")
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.9))
            Text("\(remaining)")
                .font(.system(size: 110, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(reduceMotion ? .identity : .numericText(countsDown: true))
                .animation(reduceMotion ? nil : .snappy, value: remaining)
                .accessibilityLabel("Starting in \(remaining)")
            Button("Cancel") { dismiss() }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(24)
    }

    private func playView(_ engine: GameEngine) -> some View {
        VStack(spacing: 0) {
            // Timer bar
            TimelineView(.periodic(from: .now, by: 0.25)) { timeline in
                let remaining = engine.remainingSeconds(at: timeline.date)
                VStack(spacing: 6) {
                    Text("\(remaining)")
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .accessibilityLabel("\(remaining) seconds left")
                    ProgressView(value: Double(remaining), total: Double(roundSeconds))
                        .tint(.white)
                        .padding(.horizontal, 40)
                        .accessibilityHidden(true)
                }
            }
            .padding(.top, 18)

            Spacer()

            Group {
                if case .flash(let correct) = engine.phase {
                    VStack(spacing: 10) {
                        Image(systemName: correct ? "checkmark.circle.fill" : "arrow.uturn.right.circle.fill")
                            .font(.system(size: 64))
                        Text(correct ? "Got it!" : "Pass")
                            .font(.system(.title, design: .rounded, weight: .black))
                    }
                    .foregroundStyle(.white)
                    .accessibilityLabel(correct ? "Correct" : "Passed")
                } else {
                    Text(engine.currentWord)
                        .font(.system(size: 54, weight: .black, design: .rounded))
                        .minimumScaleFactor(0.35)
                        .lineLimit(3)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28)
                        .accessibilityLabel("Word: \(engine.currentWord)")
                }
            }
            .frame(maxHeight: .infinity)

            Spacer()

            HStack(spacing: 14) {
                Button {
                    engine.markPass()
                } label: {
                    Label("Pass", systemImage: "arrow.uturn.right")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.white.opacity(0.22), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .foregroundStyle(.white)
                }
                .accessibilityHint("Skips this word")
                Button {
                    engine.markCorrect()
                } label: {
                    Label("Got it", systemImage: "checkmark")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .foregroundStyle(Theme.accent)
                }
                .accessibilityHint("Scores this word as guessed")
            }
            .padding(.horizontal, 20)

            HStack {
                Label("\(engine.score)", systemImage: "trophy.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .accessibilityLabel("Score \(engine.score)")
                Spacer()
                Button("End round") { engine.cancel() }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
        }
    }

    private func saveResult() {
        guard let engine, !saved else { return }
        saved = true
        let result = GameResult(
            deckName: deck.name,
            score: engine.score,
            totalSeen: engine.totalSeen,
            roundSeconds: roundSeconds,
            correctWords: engine.correctWords,
            passedWords: engine.passedWords
        )
        context.insert(result)
        Haptics.correct()
    }
}

struct RoundRecapView: View {
    let engine: GameEngine
    @Binding var saved: Bool
    let onSave: () -> Void
    let onDone: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text("Time's up!")
                    .font(.system(.largeTitle, design: .rounded, weight: .black))
                    .foregroundStyle(.white)
                    .padding(.top, 30)
                Text("\(engine.score)")
                    .font(.system(size: 96, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .accessibilityLabel("Final score \(engine.score)")
                Text("\(engine.score) of \(engine.totalSeen) cards guessed")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.9))

                if !engine.correctWords.isEmpty {
                    recapSection(title: "Guessed", words: engine.correctWords, icon: "checkmark.circle.fill")
                }
                if !engine.passedWords.isEmpty {
                    recapSection(title: "Passed", words: engine.passedWords, icon: "arrow.uturn.right.circle.fill")
                }
                if engine.totalSeen == 0 {
                    Text("No cards were seen this round — try a longer timer!")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                }

                VStack(spacing: 10) {
                    Button {
                        onSave()
                    } label: {
                        Label(saved ? "Saved to Scores" : "Save result",
                              systemImage: saved ? "checkmark" : "square.and.arrow.down")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .foregroundStyle(Theme.accent)
                    }
                    .disabled(saved)
                    Button {
                        onDone()
                    } label: {
                        Text("Done")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.white.opacity(0.22), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .foregroundStyle(.white)
                    }
                }
                .padding(.top, 8)
            }
            .padding(20)
        }
        .background(Theme.accent.ignoresSafeArea())
    }

    private func recapSection(title: String, words: [String], icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
            ForEach(words, id: \.self) { word in
                Text(word)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.92))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(14)
        .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
