import SwiftUI

/// Shake mission: physically shake the phone until the meter fills. Uses CoreMotion via
/// `ShakeDetector`. On devices without an accelerometer (some simulators) a tap fallback
/// keeps the mission winnable. Each filled meter is one rep.
struct ShakeMissionView: View {
    let difficulty: MissionDifficulty
    let reps: Int
    let onComplete: () -> Void
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var detector = ShakeDetector()

    @State private var done = 0
    @State private var wobble = false

    private var goal: Int { MissionEngine.shakeGoal(difficulty: difficulty) }
    private var progress: Double {
        guard goal > 0 else { return 1 }
        return min(1, Double(detector.count) / Double(goal))
    }

    init(difficulty: MissionDifficulty, reps: Int, onComplete: @escaping () -> Void) {
        self.difficulty = difficulty
        self.reps = max(1, reps)
        self.onComplete = onComplete
    }

    var body: some View {
        MissionShell(title: "Shake awake",
                     subtitle: detector.isAvailable
                        ? "Shake your phone! \(min(detector.count, goal))/\(goal)"
                        : "Tap rapidly to wake. \(min(detector.count, goal))/\(goal)",
                     repsTotal: reps, repsDone: done) {
            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.22), lineWidth: 14)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: progress)
                    Image(systemName: "iphone.gen3.radiowaves.left.and.right")
                        .font(.system(size: 46))
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(wobble && !reduceMotion ? 8 : -8))
                }
                .frame(width: 170, height: 170)
                .contentShape(Circle())
                .onTapGesture {
                    // Fallback / supplement: a tap also nudges the meter so it's never stuck.
                    if !detector.isAvailable { detector.registerManualShake(); bump() }
                }

                if !detector.isAvailable {
                    Text("No motion sensor detected — tap the circle quickly instead.")
                        .font(Theme.rounded(12))
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
            }
        }
        .onAppear {
            detector.start()
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 0.25).repeatForever(autoreverses: true)) { wobble = true }
            }
        }
        .onDisappear { detector.stop() }
        .onChange(of: detector.count) { _, _ in checkGoal() }
    }

    private func bump() {
        Haptics.tap(settings.hapticsEnabled)
        checkGoal()
    }

    private func checkGoal() {
        guard detector.count >= goal else { return }
        done += 1
        Haptics.select(settings.hapticsEnabled)
        if done >= reps {
            detector.stop()
            onComplete()
        } else {
            detector.stop()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { detector.start() }
        }
    }
}
