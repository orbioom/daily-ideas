import SwiftUI

/// A near/far focus-flexibility mini-drill. The target alternates a "NEAR" / "FAR" cue with a
/// gently pulsing dot. Under Reduce Motion it becomes a still, text-paced drill.
struct FocusFlexibilityView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var scheme
    @EnvironmentObject private var settings: AppSettings

    @State private var running = false
    @State private var anchor: Date = .now
    @State private var phaseNear = true
    @State private var roundsDone = 0

    /// Seconds per near/far hold.
    private let hold: Double = 4
    private let totalRounds = 10

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Theme.restGradient(scheme).ignoresSafeArea()
            VStack(spacing: 24) {
                header
                Spacer()
                if running {
                    activeDrill
                } else {
                    idleState
                }
                Spacer()
                controls
            }
            .padding(20)
        }
        .navigationTitle("Focus flexibility")
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(ticker) { _ in
            guard running else { return }
            tick()
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("Near & far")
                .font(Theme.rounded(22, .bold)).foregroundStyle(Theme.ink)
            Text("Alternate focus between your thumb up close and a point far across the room.")
                .font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var activeDrill: some View {
        VStack(spacing: 22) {
            Text(phaseNear ? "FOCUS NEAR" : "FOCUS FAR")
                .font(Theme.rounded(26, .heavy))
                .foregroundStyle(Theme.accent)
                .contentTransition(.opacity)
                .accessibilityLabel(phaseNear ? "Focus near, on your thumb" : "Focus far, across the room")

            if reduceMotion {
                FocusDot(size: phaseNear ? 64 : 40, glow: false)
                Text(phaseNear
                     ? "Hold your thumb up close and focus on it."
                     : "Now focus on the farthest point you can see.")
                    .font(Theme.rounded(15, .medium)).foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                TimelineView(.animation) { context in
                    let t = context.date.timeIntervalSince(anchor)
                    let scale = GuidedPath.scale(for: .nearFar, phase: t / hold)
                    FocusDot(size: 64 * scale)
                        .frame(height: 90)
                }
            }

            Text("Round \(min(roundsDone + 1, totalRounds)) of \(totalRounds)")
                .font(Theme.rounded(13)).foregroundStyle(Theme.inkFaint)
        }
    }

    private var idleState: some View {
        VStack(spacing: 16) {
            FocusDot(size: 60, glow: false)
            if roundsDone >= totalRounds {
                Text("Nicely done — your eyes are limber.")
                    .font(Theme.rounded(16, .semibold)).foregroundStyle(Theme.good)
            } else {
                Text("Ten gentle rounds, four seconds each. Ready when you are.")
                    .font(Theme.rounded(15)).foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var controls: some View {
        Group {
            if running {
                SecondaryButton(title: "Stop", systemImage: "stop.fill") { stop() }
            } else {
                PrimaryButton(title: roundsDone >= totalRounds ? "Go again" : "Start drill",
                              systemImage: "play.fill") { start() }
            }
        }
    }

    private func start() {
        roundsDone = 0
        phaseNear = true
        anchor = .now
        running = true
        Haptics.tap(enabled: settings.hapticsEnabled)
    }

    private func stop() {
        running = false
        Haptics.tap(enabled: settings.hapticsEnabled)
    }

    private func tick() {
        let elapsed = Date.now.timeIntervalSince(anchor)
        if elapsed >= hold {
            anchor = .now
            phaseNear.toggle()
            if phaseNear {
                // Completed a full near+far cycle.
                roundsDone += 1
                Haptics.selection(enabled: settings.hapticsEnabled)
                if roundsDone >= totalRounds {
                    running = false
                    Haptics.success(enabled: settings.hapticsEnabled)
                }
            }
        }
    }
}
