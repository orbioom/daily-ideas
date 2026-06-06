import SwiftUI
import SwiftData
import UIKit

/// The full-screen run experience. Hosts a `WorkoutEngine`, renders the big mono
/// countdown + progress ring + next-up preview, and writes a `Session` on completion or
/// early stop. Keeps the screen awake while running (per Settings).
struct RunView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(SettingsStore.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    let routine: Routine

    @State private var engine: WorkoutEngine?
    @State private var steps: [TimelineStep] = []
    @State private var showStopConfirm = false
    @State private var didWriteSession = false

    var body: some View {
        ZStack {
            background
            content
        }
        .onAppear(perform: setUp)
        .onDisappear(perform: tearDown)
        .onChange(of: scenePhase) { _, phase in
            // Pause automatically if the app is backgrounded mid-run.
            if phase != .active, engine?.phase == .running || engine?.phase == .countIn {
                engine?.pause()
            }
        }
        .alert("End this run?", isPresented: $showStopConfirm) {
            Button("Keep going", role: .cancel) {
                engine?.resume(haptics: settings.hapticsEnabled, sound: settings.soundEnabled)
            }
            Button("End run", role: .destructive) {
                writeSessionIfNeeded()
                dismiss()
            }
        } message: {
            Text("Your progress so far will be saved to History.")
        }
        .statusBarHidden(true)
    }

    // MARK: - Background

    private var background: some View {
        let tint = currentTint
        return LinearGradient(colors: [Brand.mist1, Brand.mist2],
                              startPoint: .top, endPoint: .bottom)
            .overlay(tint.opacity(phaseIsActive ? 0.10 : 0.0))
            .ignoresSafeArea()
            .animation(reduceMotion ? nil : Brand.ease(0.6), value: currentTint)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if let engine {
            switch engine.phase {
            case .empty:
                emptyState
            case .completed:
                CompletionView(engine: engine, routineName: routine.displayName) {
                    dismiss()
                }
            default:
                runningContent(engine)
            }
        } else {
            ProgressView().tint(Brand.text)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            EmptyStateView(
                icon: "exclamationmark.triangle",
                title: "Nothing to run",
                message: "This routine has no segments. Add at least one segment before running it."
            )
            Button("Close") { dismiss() }
                .tint(Brand.text)
        }
    }

    private func runningContent(_ engine: WorkoutEngine) -> some View {
        VStack(spacing: 0) {
            topBar(engine)
            Spacer(minLength: 0)
            ringStack(engine)
            Spacer(minLength: 0)
            nextUp(engine)
            controls(engine)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 28)
        .padding(.top, 12)
    }

    private func topBar(_ engine: WorkoutEngine) -> some View {
        HStack {
            Button {
                requestStop(engine)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Brand.text2)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .accessibilityLabel("End run")

            Spacer()

            VStack(spacing: 2) {
                Text(routine.displayName)
                    .font(.headline)
                    .foregroundStyle(Brand.text)
                    .lineLimit(1)
                Text("Total left \(DurationFormat.clock(engine.remainingTotal))")
                    .font(Brand.mono(12))
                    .foregroundStyle(Brand.text3)
            }

            Spacer()

            // Balance the xmark for centering.
            Color.clear.frame(width: 40, height: 40).accessibilityHidden(true)
        }
    }

    private func ringStack(_ engine: WorkoutEngine) -> some View {
        ZStack {
            CountdownRing(progress: engine.stepProgress,
                          tint: ringTint(engine),
                          lineWidth: 16,
                          reduceMotion: reduceMotion)
                .frame(width: 280, height: 280)

            VStack(spacing: 6) {
                if engine.phase == .countIn {
                    Text("Get ready")
                        .font(.headline)
                        .foregroundStyle(Brand.text2)
                    Text("\(max(0, engine.countInRemaining))")
                        .font(Brand.mono(96, weight: .bold))
                        .foregroundStyle(Brand.text)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                } else {
                    if let step = engine.currentStep {
                        KindChip(kind: step.kind)
                        Text(step.headline)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Brand.text)
                            .lineLimit(1)
                        if step.isRepeated {
                            Text(step.roundText)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Brand.text3)
                        }
                    }
                    Text(DurationFormat.clock(engine.remainingInStep))
                        .font(Brand.mono(72, weight: .bold))
                        .foregroundStyle(Brand.text)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
            }
            .padding(40)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(ringAccessibilityLabel(engine))
        .accessibilityValue(DurationFormat.compact(
            engine.phase == .countIn ? engine.countInRemaining : engine.remainingInStep) + " remaining")
    }

    @ViewBuilder
    private func nextUp(_ engine: WorkoutEngine) -> some View {
        if let next = engine.nextStep, engine.phase != .completed {
            HStack(spacing: 10) {
                Text("Next")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Brand.text3)
                Image(systemName: next.kind.symbol)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(next.kind.tint)
                    .accessibilityHidden(true)
                Text(next.headline)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Brand.text)
                Text(DurationFormat.clock(next.duration))
                    .font(Brand.mono(13))
                    .foregroundStyle(Brand.text2)
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(.ultraThinMaterial, in: Capsule())
            .padding(.bottom, 18)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Next, \(next.headline), \(DurationFormat.compact(next.duration))")
        } else {
            Text("Final segment")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Brand.text3)
                .padding(.bottom, 18)
        }
    }

    private func controls(_ engine: WorkoutEngine) -> some View {
        HStack(spacing: 14) {
            RunControlButton(icon: "goforward.15", label: "Add 15s") {
                engine.addFifteen()
                Haptics.impact(enabled: settings.hapticsEnabled, style: .light)
            }
            .disabled(engine.phase == .completed)

            primaryControl(engine)

            RunControlButton(icon: "forward.fill", label: "Skip") {
                engine.skip(haptics: settings.hapticsEnabled, sound: settings.soundEnabled)
            }
            .disabled(engine.phase != .running)
        }
    }

    private func primaryControl(_ engine: WorkoutEngine) -> some View {
        Button {
            switch engine.phase {
            case .running, .countIn:
                engine.pause()
                Haptics.impact(enabled: settings.hapticsEnabled, style: .light)
            case .paused:
                engine.resume(haptics: settings.hapticsEnabled, sound: settings.soundEnabled)
            default:
                break
            }
        } label: {
            Image(systemName: engine.phase == .paused ? "play.fill" : "pause.fill")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 88, height: 88)
                .background(Brand.inkGradient, in: Circle())
        }
        .accessibilityLabel(engine.phase == .paused ? "Resume" : "Pause")
    }

    // MARK: - Tint helpers

    private var phaseIsActive: Bool {
        guard let engine else { return false }
        return engine.phase == .running || engine.phase == .countIn || engine.phase == .paused
    }

    private var currentTint: Color {
        guard let engine, let step = engine.currentStep, engine.phase != .countIn else {
            return Brand.text3
        }
        return step.kind.tint
    }

    private func ringTint(_ engine: WorkoutEngine) -> Color {
        if engine.phase == .countIn { return Brand.text3 }
        if engine.phase == .paused { return Brand.text3 }
        return engine.currentStep?.kind.tint ?? Brand.live
    }

    private func ringAccessibilityLabel(_ engine: WorkoutEngine) -> String {
        if engine.phase == .countIn { return "Getting ready" }
        if let step = engine.currentStep {
            return "\(step.kind.title), \(step.headline)" +
                   (step.isRepeated ? ", \(step.roundText)" : "")
        }
        return "Run"
    }

    // MARK: - Lifecycle

    private func setUp() {
        guard engine == nil else { return }
        let flattened = Timeline.flatten(routine.orderedSegments)
        steps = flattened
        let newEngine = WorkoutEngine(
            routineName: routine.displayName,
            steps: flattened,
            countIn: settings.countInSeconds,
            onComplete: { writeSessionIfNeeded() }
        )
        engine = newEngine
        if settings.keepAwake {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        newEngine.start(haptics: settings.hapticsEnabled, sound: settings.soundEnabled)
    }

    private func tearDown() {
        UIApplication.shared.isIdleTimerDisabled = false
    }

    private func requestStop(_ engine: WorkoutEngine) {
        if engine.phase == .completed {
            dismiss()
            return
        }
        engine.pause()
        showStopConfirm = true
    }

    private func writeSessionIfNeeded() {
        guard let engine, !didWriteSession else { return }
        didWriteSession = true
        let snapshot = engine.stop()
        persist(snapshot)
    }

    private func persist(_ snapshot: SessionSnapshot) {
        // Only log runs that actually progressed past the count-in.
        guard snapshot.completedSteps > 0 || snapshot.finishedFully else { return }
        let session = Session(startedAt: snapshot.startedAt,
                              endedAt: snapshot.endedAt,
                              activeSeconds: snapshot.activeSeconds,
                              workSeconds: snapshot.workSeconds,
                              completedSteps: snapshot.completedSteps,
                              totalSteps: snapshot.totalSteps,
                              finishedFully: snapshot.finishedFully,
                              routineNameSnapshot: snapshot.routineName)
        session.routine = routine
        context.insert(session)
        routine.lastRunAt = snapshot.endedAt
        try? context.save()
    }
}

/// A secondary, glassy run-control button (add-15 / skip).
struct RunControlButton: View {
    var icon: String
    var label: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                Text(label)
                    .font(.caption2.weight(.medium))
            }
            .foregroundStyle(Brand.text)
            .frame(width: 72, height: 72)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1)
            )
        }
        .accessibilityLabel(label)
    }
}

#Preview {
    if let routine = SampleData.makeRoutines().first {
        RunView(routine: routine).intervalPreview()
    }
}
