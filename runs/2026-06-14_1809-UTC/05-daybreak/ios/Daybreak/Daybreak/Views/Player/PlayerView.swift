import SwiftUI
import SwiftData
import AudioToolbox

/// Full-screen guided run. Drives a `PlayerEngine` with a wall-clock timer,
/// keeps the screen awake (per setting), cues a gentle sound/haptic on step change,
/// and records a `RoutineRun` whether the run completes or is abandoned.
struct PlayerView: View {
    let routine: Routine

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var settings: AppSettings

    @State private var engine: PlayerEngine
    /// Guards against double-recording the run on dismiss.
    @State private var recorded = false
    /// Bumped to force redraws so the wall-clock ring/label stays live.
    @State private var now = Date()
    @State private var showQuitConfirm = false

    /// 4 Hz tick keeps the countdown smooth without burning the battery.
    private let timer = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()

    init(routine: Routine) {
        self.routine = routine
        _engine = State(initialValue: PlayerEngine(routine: routine))
    }

    var body: some View {
        ZStack {
            backdrop
            content
        }
        .onReceive(timer) { _ in
            // Freeze the clock once finished so the completion time doesn't keep ticking.
            guard engine.phase == .running else { return }
            now = Date()
            let advanced = engine.advanceClock(now: now)
            if advanced { cueStepChange() }
        }
        .onChange(of: scenePhase) { _, phase in
            // Recompute on return to foreground so a timed step that finished while
            // backgrounded settles correctly (wall-clock makes this safe).
            if phase == .active {
                now = Date()
                if engine.phase == .running { engine.advanceClock(now: now) }
            }
        }
        .onChange(of: engine.phase) { _, phase in
            // Record as soon as the run finishes (any path) so the completion
            // screen's streak includes this run.
            if phase == .finished { recordIfNeeded() }
        }
        .onAppear { applyIdleTimer(true) }
        .onDisappear {
            applyIdleTimer(false)
            recordIfNeeded()
        }
        .interactiveDismissDisabled(engine.phase == .running)
        .confirmationDialog("Leave this routine?",
                            isPresented: $showQuitConfirm,
                            titleVisibility: .visible) {
            Button("Finish & save progress") { finishEarly() }
            Button("Keep going", role: .cancel) {}
        } message: {
            Text("Your progress so far will be saved.")
        }
    }

    // MARK: Backdrop

    private var backdrop: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            routine.timeOfDay.gradient
                .opacity(0.30)
                .ignoresSafeArea()
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private var content: some View {
        if engine.phase == .finished {
            CompletionView(routineName: engine.routineName,
                           completed: engine.completedCount,
                           total: engine.totalSteps,
                           seconds: runSeconds,
                           onDone: { dismiss() })
        } else if let step = engine.currentStep {
            runningBody(step)
        } else {
            // No steps to run — degrade gracefully.
            EmptyStateView(symbol: "tray",
                           title: "Nothing to run",
                           message: "This routine has no steps yet. Add a few and start again.",
                           actionTitle: "Close") { dismiss() }
        }
    }

    // MARK: Running body

    private func runningBody(_ step: PlayerEngine.Step) -> some View {
        VStack(spacing: 0) {
            header
            Spacer(minLength: 8)

            Text(step.title)
                .font(Theme.rounded(28, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .accessibilityAddTraits(.isHeader)

            if !step.note.isEmpty {
                Text(step.note)
                    .font(Theme.rounded(16))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 36)
                    .padding(.top, 6)
            }

            Spacer(minLength: 16)

            stepFocus(step)

            Spacer(minLength: 16)

            if engine.isPaused {
                Label("Paused", systemImage: "pause.fill")
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.accent)
                    .padding(.bottom, 8)
            }

            controls(step)
        }
        .padding(.bottom, 24)
    }

    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    if engine.completedCount > 0 || engine.index > 0 {
                        showQuitConfirm = true
                    } else {
                        // Nothing done yet — leave without a confirmation, but still record.
                        finishEarly()
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Theme.inkSoft)
                        .padding(10)
                        .background(Circle().fill(Theme.surface))
                }
                .accessibilityLabel("Close routine")
                Spacer()
                Text(engine.routineName)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Spacer()
                // Balance the X visually.
                Color.clear.frame(width: 42, height: 42)
                    .accessibilityHidden(true)
            }

            SegmentBar(total: engine.totalSteps,
                       currentIndex: engine.index,
                       completedIndices: completedIndices)
            Text(engine.positionText)
                .font(Theme.rounded(13, .medium))
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    @ViewBuilder
    private func stepFocus(_ step: PlayerEngine.Step) -> some View {
        if step.kind == .timed {
            CountdownRing(progress: engine.stepProgress(now: now),
                          remaining: engine.remaining(now: now),
                          icon: step.iconName)
                .animation(reduceMotion ? nil : .linear(duration: 0.25), value: engine.remaining(now: now))
        } else {
            Button {
                completeCurrent()
            } label: {
                ZStack {
                    Circle()
                        .fill(Theme.accentSoft)
                        .frame(width: 240, height: 240)
                    Circle()
                        .strokeBorder(Theme.accent, lineWidth: 4)
                        .frame(width: 240, height: 240)
                    VStack(spacing: 10) {
                        Image(systemName: step.iconName)
                            .font(.system(size: 46))
                            .foregroundStyle(Theme.accent)
                            .accessibilityHidden(true)
                        Text("Tap when done")
                            .font(Theme.rounded(16, .semibold))
                            .foregroundStyle(Theme.ink)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Mark \(step.title) complete")
            .accessibilityHint("Double tap when you finish this step")
        }
    }

    private func controls(_ step: PlayerEngine.Step) -> some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                circleControl("arrow.uturn.backward", "Back",
                              enabled: engine.index > 0) { goBack() }
                circleControl(engine.isPaused ? "play.fill" : "pause.fill",
                              engine.isPaused ? "Resume" : "Pause",
                              enabled: step.kind == .timed) { togglePause() }
                circleControl("forward.fill", "Skip", enabled: true) { skip() }
            }

            PrimaryButton(title: step.kind == .timed ? "Done early" : "Complete step",
                          systemImage: "checkmark") {
                completeCurrent()
            }
            .padding(.horizontal, 20)
        }
    }

    private func circleControl(_ icon: String, _ label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(enabled ? Theme.ink : Theme.inkFaint)
                .frame(width: 60, height: 60)
                .background(Circle().fill(Theme.surface))
        }
        .disabled(!enabled)
        .accessibilityLabel(label)
    }

    // MARK: Derived

    private var completedIndices: Set<Int> {
        var set: Set<Int> = []
        for (i, step) in engine.steps.enumerated() where engine.isStepComplete(step) {
            set.insert(i)
        }
        return set
    }

    private var runSeconds: Int {
        engine.runDuration(now: now)
    }

    // MARK: Actions

    private func completeCurrent() {
        engine.completeCurrent(now: Date())
        cueStepChange()
        if engine.phase == .finished { cueFinish() }
    }

    private func skip() {
        engine.skip(now: Date())
        Haptics.tap(settings.hapticsEnabled)
        if engine.phase == .finished { cueFinish() }
    }

    private func goBack() {
        engine.back(now: Date())
        Haptics.tap(settings.hapticsEnabled)
    }

    private func togglePause() {
        engine.togglePause(now: Date())
        Haptics.select(settings.hapticsEnabled)
    }

    private func finishEarly() {
        engine.finish()
        recordIfNeeded()
        cueFinish()
    }

    private func recordIfNeeded() {
        guard !recorded else { return }
        recorded = true
        let run = engine.makeRun(routineRef: routine, now: Date())
        context.insert(run)
        try? context.save()
    }

    private func cueStepChange() {
        guard engine.phase == .running else { return }
        Haptics.tap(settings.hapticsEnabled)
        if settings.soundCueOnStepChange {
            AudioServicesPlaySystemSound(1104) // gentle tock
        }
    }

    private func cueFinish() {
        Haptics.success(settings.hapticsEnabled)
        if settings.soundCueOnStepChange {
            AudioServicesPlaySystemSound(1025) // completion chime
        }
    }

    private func applyIdleTimer(_ active: Bool) {
        UIApplication.shared.isIdleTimerDisabled = active && settings.keepAwakeDuringRun
    }
}
