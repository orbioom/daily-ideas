import SwiftUI
import SwiftData

/// Full-screen ringing takeover. Shows the current time + alarm label over a dawn gradient,
/// then the active dismiss-mission UI. Stop is only reachable on mission success; Snooze is
/// available if allowed. Writes a WakeLog on real (non-test) dismiss.
struct RingScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var ring: RingController
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var phase: Phase = .mission
    @State private var glow = false

    private enum Phase { case mission, success }

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var now = Date()

    var body: some View {
        ZStack {
            background
            VStack(spacing: 0) {
                topBar
                clockHeader
                Spacer(minLength: 8)
                content
                Spacer(minLength: 8)
                if phase == .mission { controls }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 28)
            .padding(.top, 12)
        }
        .onReceive(ticker) { now = $0 }
        .onAppear {
            if !reduceMotion { withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) { glow = true } }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: Background

    private var background: some View {
        ZStack {
            LinearGradient(colors: [Theme.dawnTop, Theme.dawnBottom],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            // A soft sun glow that gently breathes (respects Reduce Motion).
            Circle()
                .fill(RadialGradient(colors: [Color.white.opacity(0.28), .clear],
                                     center: .center, startRadius: 10, endRadius: 260))
                .frame(width: 360, height: 360)
                .offset(y: -220)
                .scaleEffect(glow ? 1.08 : 0.96)
                .accessibilityHidden(true)
        }
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack {
            if ring.isTest {
                Pill(text: "TEST RING", systemImage: "play.circle.fill",
                     fill: Color.white.opacity(0.2), foreground: .white)
            }
            Spacer()
            if ring.isTest {
                Button {
                    ring.cancel()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .accessibilityLabel("Close test ring")
            }
        }
        .frame(height: 30)
    }

    // MARK: Clock header

    private var clockHeader: some View {
        VStack(spacing: 6) {
            Text(TimeFormat.clock(now, use24Hour: settings.use24Hour))
                .font(Theme.rounded(64, .bold))
                .foregroundStyle(.white)
                .monospacedDigit()
                .shadow(color: .black.opacity(0.2), radius: 8, y: 2)
            Text(ring.activeAlarm?.label ?? "Alarm")
                .font(Theme.rounded(22, .semibold))
                .foregroundStyle(.white.opacity(0.92))
            if ring.snoozeCount > 0 {
                Text("Snoozed \(ring.snoozeCount)×")
                    .font(Theme.rounded(13, .semibold))
                    .foregroundStyle(.white.opacity(0.75))
            }
        }
        .padding(.top, 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(ring.activeAlarm?.label ?? "Alarm") is ringing. The time is \(TimeFormat.clock(now, use24Hour: settings.use24Hour)).")
    }

    // MARK: Content (mission or success)

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .success:
            successView
        case .mission:
            missionView
        }
    }

    @ViewBuilder
    private var missionView: some View {
        let snapshot = ring.activeAlarm
        let type = snapshot?.missionType ?? .none
        let difficulty = snapshot?.missionDifficulty ?? .medium
        let reps = snapshot?.missionReps ?? 0

        switch type {
        case .none:
            NoneMissionView { onMissionComplete() }
        case .math:
            MathMissionView(difficulty: difficulty, reps: reps) { onMissionComplete() }
        case .memory:
            MemoryMissionView(difficulty: difficulty, reps: reps) { onMissionComplete() }
        case .tap:
            TapMissionView(difficulty: difficulty, reps: reps) { onMissionComplete() }
        case .shake:
            ShakeMissionView(difficulty: difficulty, reps: reps) { onMissionComplete() }
        case .typing:
            TypingMissionView(difficulty: difficulty, reps: reps) { onMissionComplete() }
        }
    }

    private var successView: some View {
        VStack(spacing: 18) {
            Image(systemName: "sun.max.fill")
                .font(.system(size: 64))
                .foregroundStyle(.white)
                .accessibilityHidden(true)
            Text("Good morning")
                .font(Theme.rounded(30, .bold))
                .foregroundStyle(.white)
            Text(ring.isTest ? "Test complete — that's exactly how it'll feel."
                             : "You're up. Have a great day.")
                .font(Theme.rounded(16))
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
            PrimaryButton(title: "Done", systemImage: "checkmark") {
                finish()
            }
            .padding(.horizontal, 30)
            .padding(.top, 8)
        }
        .padding(28)
        .transition(.opacity)
    }

    // MARK: Controls (snooze)

    @ViewBuilder
    private var controls: some View {
        if ring.canSnooze {
            Button {
                if ring.isTest { ring.snoozeQuick() } else { ring.snooze() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "zzz")
                    Text(ring.isTest ? "Snooze · rings again in 5s"
                                     : "Snooze \(ring.activeAlarm?.snoozeMinutes ?? 9) min · \(ring.snoozesRemaining) left")
                }
                .font(Theme.rounded(16, .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Capsule().fill(Color.white.opacity(0.18)))
            }
            .accessibilityHint("Silences the alarm temporarily, then it rings again.")
        } else if ring.activeAlarm?.snoozeEnabled == true {
            Text("No snoozes left — finish the mission to stop.")
                .font(Theme.rounded(13))
                .foregroundStyle(.white.opacity(0.8))
                .padding(.bottom, 4)
        }
    }

    // MARK: Flow

    private func onMissionComplete() {
        Haptics.success(settings.hapticsEnabled)
        withAnimation(reduceMotion ? nil : .easeInOut) { phase = .success }
    }

    private func finish() {
        if let log = ring.dismiss() {
            context.insert(log)
            try? context.save()
        }
        // `ring.dismiss()` already tore down audio; the cover dismisses because isRinging is false.
    }
}
