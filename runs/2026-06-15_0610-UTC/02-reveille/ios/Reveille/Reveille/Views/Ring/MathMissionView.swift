import SwiftUI

/// Math mission: solve `reps` arithmetic problems on a keypad. A wrong answer shakes and
/// resets the entry; a correct one advances. Difficulty scales the operands/operations.
struct MathMissionView: View {
    let difficulty: MissionDifficulty
    let reps: Int
    let onComplete: () -> Void
    @EnvironmentObject private var settings: AppSettings

    @State private var rng = SplitMix64(seed: UInt64(Date().timeIntervalSince1970))
    @State private var problem: MissionEngine.MathProblem
    @State private var entry = ""
    @State private var done = 0
    @State private var wrong = false
    @State private var shake = false

    init(difficulty: MissionDifficulty, reps: Int, onComplete: @escaping () -> Void) {
        self.difficulty = difficulty
        self.reps = max(1, reps)
        self.onComplete = onComplete
        var seed = SplitMix64(seed: UInt64(Date().timeIntervalSince1970.bitPattern))
        _problem = State(initialValue: MissionEngine.makeMathProblem(difficulty: difficulty, rng: &seed))
        _rng = State(initialValue: seed)
    }

    var body: some View {
        MissionShell(title: "Solve to wake",
                     subtitle: "Tap the answer, then check.",
                     repsTotal: reps, repsDone: done) {
            VStack(spacing: 16) {
                Text(problem.prompt)
                    .font(Theme.mono(36, .bold))
                    .foregroundStyle(.white)
                    .accessibilityLabel("What is \(problem.prompt.replacingOccurrences(of: "×", with: "times").replacingOccurrences(of: "−", with: "minus"))")

                Text(entry.isEmpty ? " " : entry)
                    .font(Theme.mono(30, .semibold))
                    .foregroundStyle(wrong ? Theme.bad : .white)
                    .frame(height: 40)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.1)))
                    .offset(x: shake ? -8 : 0)

                keypad
            }
        }
    }

    private var keypad: some View {
        VStack(spacing: 10) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(1...3, id: \.self) { col in
                        let n = row * 3 + col
                        GlassButton(label: "\(n)") { append("\(n)") }
                    }
                }
            }
            HStack(spacing: 10) {
                GlassButton(label: "", systemImage: "delete.left") { backspace() }
                GlassButton(label: "0") { append("0") }
                GlassButton(label: "", systemImage: "checkmark", prominent: true) { check() }
            }
        }
    }

    private func append(_ d: String) {
        guard entry.count < 6 else { return }
        wrong = false
        entry += d
        Haptics.tap(settings.hapticsEnabled)
    }

    private func backspace() {
        guard !entry.isEmpty else { return }
        entry.removeLast()
        wrong = false
    }

    private func check() {
        guard let value = Int(entry) else { fail(); return }
        if value == problem.answer {
            done += 1
            Haptics.select(settings.hapticsEnabled)
            if done >= reps {
                onComplete()
            } else {
                entry = ""
                problem = MissionEngine.makeMathProblem(difficulty: difficulty, rng: &rng)
            }
        } else {
            fail()
        }
    }

    private func fail() {
        Haptics.warning(settings.hapticsEnabled)
        wrong = true
        withAnimation(.default.repeatCount(3, autoreverses: true).speed(6)) { shake = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { shake = false; entry = "" }
    }
}
