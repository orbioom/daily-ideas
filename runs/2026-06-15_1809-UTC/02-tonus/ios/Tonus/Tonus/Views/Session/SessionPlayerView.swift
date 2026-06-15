import SwiftUI
import SwiftData

struct SessionPlayerView: View {
    let program: TrainingProgram

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var settings: AppSettings

    @StateObject private var vm: PlayerViewModel
    @State private var showStopConfirm = false
    @State private var summary: SessionSummary?
    /// True when the stop dialog auto-paused a running session (so cancel can resume it).
    @State private var pausedForDialog = false

    init(program: TrainingProgram) {
        self.program = program
        // Settings aren't available in init; capture from UserDefaults defaults at construction.
        let haptics = UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true
        let audio = UserDefaults.standard.object(forKey: "audioCuesEnabled") as? Bool ?? true
        _vm = StateObject(wrappedValue: PlayerViewModel(program: program,
                                                        hapticsEnabled: haptics,
                                                        audioEnabled: audio))
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            if vm.engine.totalSeconds <= 0 {
                // Calm, recoverable guard: a program with no timed phases can't be played.
                ErrorStateView(
                    title: "This program has no timed phases",
                    message: "Edit the program to add at least one squeeze, hold, or relax phase, then try again.",
                    retryTitle: "Go back",
                    retry: { dismiss() }
                )
            } else if let summary {
                SessionSummaryView(summary: summary,
                                   onDone: { dismiss() },
                                   onRepeat: { restart() })
                    .transition(.opacity)
            } else {
                TimelineView(.animation(minimumInterval: reduceMotion ? 0.2 : nil)) { timeline in
                    livePlayer(reference: timeline.date)
                        .onChange(of: timeline.date) { _, newDate in
                            handleTick(reference: newDate)
                        }
                }
            }
        }
        .confirmationDialog("Stop this session?", isPresented: $showStopConfirm, titleVisibility: .visible) {
            Button("Stop & save progress", role: .destructive) { stopEarly() }
            Button("Keep going", role: .cancel) { resumeIfPausedForDialog() }
        } message: {
            Text("We'll save the reps you've completed so far.")
        }
    }

    // MARK: Live player

    private func livePlayer(reference: Date) -> some View {
        let moment = vm.moment(at: reference)
        return VStack(spacing: 0) {
            topBar(moment: moment)
            Spacer()
            ringArea(moment: moment)
            Spacer()
            phaseInfo(moment: moment)
            Spacer()
            controls
            Spacer().frame(height: 24)
        }
        .padding(.horizontal, 24)
    }

    /// Advances cue/completion logic off the render pass (called from onChange).
    private func handleTick(reference: Date) {
        guard summary == nil else { return }
        vm.tick(at: reference)
        if vm.status == .finished {
            finishNaturally(reference: reference)
        }
    }

    private func topBar(moment: SessionMoment) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(program.name)
                    .font(Theme.rounded(16, .bold))
                    .foregroundStyle(Theme.ink)
                Text("Set \(moment.set) of \(vm.totalSets)")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            Button {
                if vm.status == .running {
                    vm.pause()
                    pausedForDialog = true
                }
                showStopConfirm = true
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.inkSoft)
                    .padding(10)
                    .background(Circle().fill(Theme.surfaceAlt))
            }
            .accessibilityLabel("Stop session")
        }
        .padding(.top, 16)
    }

    @ViewBuilder
    private func ringArea(moment: SessionMoment) -> some View {
        if reduceMotion {
            ReducedMotionRing(moment: moment)
        } else {
            BreathingRing(moment: moment)
        }
    }

    private func phaseInfo(moment: SessionMoment) -> some View {
        VStack(spacing: 12) {
            Text(moment.phase.label.uppercased())
                .font(Theme.rounded(34, .heavy))
                .foregroundStyle(moment.phase.color)
                .accessibilityLabel("\(moment.phase.label) phase")
            Text("\(Int(moment.remainingInStep.rounded(.up)))s")
                .font(Theme.mono(22, .semibold))
                .foregroundStyle(Theme.ink)
                .contentTransition(.numericText())
                .accessibilityLabel("\(Int(moment.remainingInStep.rounded(.up))) seconds remaining")
            Text(moment.phase.guidance)
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(minHeight: 40)
            if moment.phase != .rest {
                Text("Rep \(min(moment.rep, vm.totalReps / max(1, vm.totalSets))) of \(vm.totalReps / max(1, vm.totalSets)) · \(vm.totalReps) total")
                    .font(Theme.rounded(13, .medium))
                    .foregroundStyle(Theme.inkFaint)
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 16) {
            Button {
                if vm.status == .running { vm.pause() } else { vm.resume() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: vm.status == .running ? "pause.fill" : "play.fill")
                        .accessibilityHidden(true)
                    Text(vm.status == .running ? "Pause" : "Resume")
                        .font(Theme.rounded(17, .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .foregroundStyle(.white)
                .background(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous).fill(Theme.heroGradient))
            }
            .buttonStyle(PressableScale())
        }
    }

    // MARK: Actions

    private func resumeIfPausedForDialog() {
        if pausedForDialog {
            vm.resume()
            pausedForDialog = false
        }
    }

    private func stopEarly() {
        pausedForDialog = false
        let result = vm.stopEarly(at: Date())
        vm.log(into: modelContext, finished: false,
               completedReps: result.reps, durationSeconds: result.seconds)
        withAnimation(reduceMotion ? nil : .easeInOut) {
            summary = SessionSummary(programName: program.name,
                                     reps: result.reps,
                                     totalReps: vm.totalReps,
                                     seconds: result.seconds,
                                     finished: false)
        }
    }

    private func finishNaturally(reference: Date) {
        let seconds = vm.engine.totalSeconds
        vm.log(into: modelContext, finished: true,
               completedReps: vm.totalReps, durationSeconds: seconds)
        withAnimation(reduceMotion ? nil : .easeInOut) {
            summary = SessionSummary(programName: program.name,
                                     reps: vm.totalReps,
                                     totalReps: vm.totalReps,
                                     seconds: seconds,
                                     finished: true)
        }
    }

    private func restart() {
        vm.restart()
        withAnimation(reduceMotion ? nil : .easeInOut) {
            summary = nil
        }
    }
}

/// Immutable result passed to the success screen.
struct SessionSummary: Identifiable {
    let id = UUID()
    let programName: String
    let reps: Int
    let totalReps: Int
    let seconds: Int
    let finished: Bool

    var minutes: Int { max(1, Int((Double(seconds) / 60.0).rounded())) }
}
