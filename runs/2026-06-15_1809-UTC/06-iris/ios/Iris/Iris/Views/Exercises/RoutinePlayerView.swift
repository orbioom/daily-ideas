import SwiftUI

/// Full-screen guided player. A focus dot moves along the exercise's path (figure-8, near-far,
/// side-to-side, circle); under Reduce Motion the dot is still and the text cue guides instead.
struct RoutinePlayerView: View {
    let routine: EyeRoutine
    /// Called on completion with (totalSecondsGuided, exercisesCompleted).
    var onFinish: (Int, Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var scheme
    @EnvironmentObject private var settings: AppSettings

    @StateObject private var player: RoutinePlayer
    @State private var didFinish = false
    /// Anchor for the TimelineView time used to drive the moving path.
    @State private var anchor: Date = .now

    /// A real timer drives the state machine OUTSIDE the view-update cycle (safe to mutate state).
    private let ticker = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    init(routine: EyeRoutine, onFinish: @escaping (Int, Int) -> Void) {
        self.routine = routine
        self.onFinish = onFinish
        _player = StateObject(wrappedValue: RoutinePlayer(routine: routine))
    }

    var body: some View {
        ZStack {
            Theme.restGradient(scheme).ignoresSafeArea()
            if player.isFinished {
                finishView.transition(.opacity)
            } else if player.current == nil {
                emptyView
            } else {
                playerBody
            }
        }
        .onAppear {
            anchor = .now
            player.start()
        }
        .onReceive(ticker) { date in
            guard !player.isFinished else { return }
            player.tick(now: date)
            if player.isFinished { handleFinish() }
        }
    }

    // MARK: - Active player

    private var playerBody: some View {
        // The TimelineView only drives the smooth dot path (read-only); state advances via `ticker`.
        TimelineView(.animation(minimumInterval: reduceMotion ? nil : 0.03, paused: player.isPaused)) { context in
            let elapsed = max(0, context.date.timeIntervalSince(anchor))
            VStack(spacing: 0) {
                topBar
                ProgressView(value: player.overallProgress)
                    .tint(Theme.accent)
                    .padding(.top, 12)
                    .accessibilityHidden(true)
                Spacer(minLength: 8)
                instructionBlock
                targetArea(time: elapsed)
                countdown
                Spacer(minLength: 8)
                controls
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
    }

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.inkSoft)
                    .padding(10)
                    .background(Circle().fill(Theme.surface))
            }
            .accessibilityLabel("End routine")
            Spacer()
            Text("\(player.position) of \(player.exerciseCount)")
                .font(Theme.rounded(14, .semibold))
                .foregroundStyle(Theme.inkSoft)
                .accessibilityLabel("Exercise \(player.position) of \(player.exerciseCount)")
            Spacer()
            // Balance the layout.
            Color.clear.frame(width: 40, height: 40)
        }
    }

    private var instructionBlock: some View {
        VStack(spacing: 8) {
            Text(player.current?.name ?? "")
                .font(Theme.rounded(24, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(player.current?.instruction ?? "")
                .font(Theme.rounded(16))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 12)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func targetArea(time: Double) -> some View {
        let type = player.current?.type ?? .blinking
        ZStack {
            if reduceMotion {
                // Still, motion-free guidance.
                VStack(spacing: 14) {
                    FocusDot(size: 60, glow: false)
                    Text(type.motionFreeCue)
                        .font(Theme.rounded(14, .medium))
                        .foregroundStyle(Theme.accent)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 24)
                }
            } else if type == .palming || type == .blinking {
                // No travel — a gentle centered pulse already encoded in scale.
                GuidedTargetView(type: type, time: player.isPaused ? 0 : time, reduceMotion: false)
            } else {
                GuidedTargetView(type: type, time: player.isPaused ? 0 : time, travel: 130, reduceMotion: false)
            }
        }
        .frame(height: 280)
        .frame(maxWidth: .infinity)
        .accessibilityHidden(true)
    }

    private var countdown: some View {
        Text("\(player.remainingSeconds)")
            .font(Theme.rounded(40, .bold))
            .monospacedDigit()
            .foregroundStyle(Theme.accent)
            .contentTransition(.numericText())
            .accessibilityLabel("\(player.remainingSeconds) seconds remaining in this exercise")
    }

    private var controls: some View {
        HStack(spacing: 14) {
            Button {
                player.togglePause()
            } label: {
                Label(player.isPaused ? "Resume" : "Pause",
                      systemImage: player.isPaused ? "play.fill" : "pause.fill")
                    .font(Theme.rounded(16, .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundStyle(Theme.accent)
                    .background(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous).fill(Theme.accentSoft))
            }
            .buttonStyle(PressableScale())

            Button {
                Haptics.selection(enabled: settings.hapticsEnabled)
                player.skip()
            } label: {
                Label("Skip", systemImage: "forward.fill")
                    .font(Theme.rounded(16, .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundStyle(Theme.inkSoft)
                    .background(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous).fill(Theme.surface))
            }
            .buttonStyle(PressableScale())
        }
    }

    // MARK: - Finish

    private var finishView: some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle().fill(Theme.heroGradient).frame(width: 116, height: 116)
                    .shadow(color: Theme.accent.opacity(0.35), radius: 20, y: 8)
                Image(systemName: "checkmark")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)
            }
            Text("Routine complete")
                .font(Theme.rounded(28, .bold))
                .foregroundStyle(Theme.ink)
            Text("\(routine.name) · \(routine.totalMinutesLabel) of eye care, logged. Your eyes feel a little lighter.")
                .font(Theme.rounded(16))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 36)
            Spacer()
            PrimaryButton(title: "Done", systemImage: "checkmark") { dismiss() }
                .padding(.horizontal, 36)
            Spacer().frame(height: 28)
        }
        .accessibilityElement(children: .combine)
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            EmptyStateView(symbol: "figure.mind.and.body",
                           title: "Nothing to play",
                           message: "This routine has no exercises.")
            Button("Close") { dismiss() }
                .font(Theme.rounded(15, .medium))
                .foregroundStyle(Theme.accent)
        }
    }

    private func handleFinish() {
        guard !didFinish else { return }
        didFinish = true
        onFinish(routine.totalSeconds, routine.exercises.count)
    }
}
