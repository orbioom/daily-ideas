import SwiftUI

/// Tap-targets mission: dots appear at random positions and fade; tap `count` of them before
/// they vanish. Faster fade on higher difficulty. One full quota = one rep.
struct TapMissionView: View {
    let difficulty: MissionDifficulty
    let reps: Int
    let onComplete: () -> Void
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var dot: Dot? = nil
    @State private var hits = 0
    @State private var done = 0
    @State private var rng = SplitMix64(seed: 7)

    private struct Dot: Identifiable {
        let id = UUID()
        let x: CGFloat   // 0...1
        let y: CGFloat   // 0...1
        let born: Date
    }

    private var target: Int { MissionEngine.tapTargetCount(difficulty: difficulty) }
    private var lifetime: Double { MissionEngine.tapDotLifetime(difficulty: difficulty) }
    private let spawn = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    init(difficulty: MissionDifficulty, reps: Int, onComplete: @escaping () -> Void) {
        self.difficulty = difficulty
        self.reps = max(1, reps)
        self.onComplete = onComplete
        _rng = State(initialValue: SplitMix64(seed: UInt64(Date().timeIntervalSince1970.bitPattern) ^ 0x7A77A7))
    }

    var body: some View {
        MissionShell(title: "Tap the dots",
                     subtitle: "Catch \(target) dots before they fade. \(hits)/\(target)",
                     repsTotal: reps, repsDone: done) {
            GeometryReader { geo in
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                    if let dot {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 56, height: 56)
                            .position(x: dot.x * geo.size.width, y: dot.y * geo.size.height)
                            .transition(reduceMotion ? .identity : .scale.combined(with: .opacity))
                            .onTapGesture { hit() }
                            .accessibilityLabel("Tap target")
                            .accessibilityAddTraits(.isButton)
                    }
                }
                .onReceive(spawn) { _ in maintain() }
            }
            .frame(height: 240)
            .frame(maxWidth: .infinity)
        }
        .onAppear { spawnDot() }
    }

    private func maintain() {
        guard let dot else { return }
        if Date().timeIntervalSince(dot.born) > lifetime {
            // Missed — respawn elsewhere (no penalty beyond lost time).
            spawnDot()
        }
    }

    private func spawnDot() {
        let x = CGFloat(rng.int(in: 12...88)) / 100
        let y = CGFloat(rng.int(in: 14...86)) / 100
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.15)) {
            dot = Dot(x: x, y: y, born: Date())
        }
    }

    private func hit() {
        Haptics.tap(settings.hapticsEnabled)
        hits += 1
        if hits >= target {
            done += 1
            hits = 0
            if done >= reps {
                dot = nil
                onComplete()
                return
            }
        }
        spawnDot()
    }
}
