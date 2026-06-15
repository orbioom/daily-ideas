import SwiftUI

/// Steady-type mission: type a given phrase exactly. Live progress fills as you match the
/// phrase prefix; a mismatch is shown gently. Each correctly-typed phrase is one rep.
struct TypingMissionView: View {
    let difficulty: MissionDifficulty
    let reps: Int
    let onComplete: () -> Void
    @EnvironmentObject private var settings: AppSettings
    @FocusState private var focused: Bool

    @State private var rng = SplitMix64(seed: 3)
    @State private var phrase: String = ""
    @State private var typed: String = ""
    @State private var done = 0

    init(difficulty: MissionDifficulty, reps: Int, onComplete: @escaping () -> Void) {
        self.difficulty = difficulty
        self.reps = max(1, reps)
        self.onComplete = onComplete
        var seed = SplitMix64(seed: UInt64(Date().timeIntervalSince1970.bitPattern) ^ 0x7795)
        _phrase = State(initialValue: MissionEngine.makeTypingPhrase(difficulty: difficulty, rng: &seed))
        _rng = State(initialValue: seed)
    }

    private var progress: Double { MissionEngine.typingProgress(typed, target: phrase) }
    private var matches: Bool { MissionEngine.typingMatches(typed, target: phrase) }

    var body: some View {
        MissionShell(title: "Type to prove you're up",
                     subtitle: "Type the phrase exactly.",
                     repsTotal: reps, repsDone: done) {
            VStack(spacing: 14) {
                Text(phrase)
                    .font(Theme.rounded(20, .semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                ProgressView(value: progress)
                    .tint(.white)
                    .accessibilityValue("\(Int(progress * 100)) percent matched")

                TextField("Start typing…", text: $typed, axis: .vertical)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(Theme.rounded(18))
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.14)))
                    .focused($focused)
                    .submitLabel(.done)
                    .onChange(of: typed) { _, _ in checkMatch() }

                if matches {
                    Label("Perfect — locking it in", systemImage: "checkmark.seal.fill")
                        .font(Theme.rounded(13, .semibold))
                        .foregroundStyle(.white)
                }
            }
        }
        .onAppear { focused = true }
    }

    private func checkMatch() {
        guard matches else { return }
        done += 1
        Haptics.select(settings.hapticsEnabled)
        if done >= reps {
            focused = false
            onComplete()
        } else {
            typed = ""
            phrase = MissionEngine.makeTypingPhrase(difficulty: difficulty, rng: &rng)
        }
    }
}
