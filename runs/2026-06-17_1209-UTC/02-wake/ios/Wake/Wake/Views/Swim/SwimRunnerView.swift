import SwiftUI
import SwiftData

/// The guided swim runner: set banner, big interval clock, rep recording, rest countdown.
/// Clocks are anchored to stored Dates so lock/background/relaunch never lose time.
struct SwimRunnerView: View {
    @Bindable var runner: SwimRunner

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @AppStorage(PrefKey.hapticsEnabled) private var hapticsEnabled = true
    @AppStorage(PrefKey.beepEnabled) private var beepEnabled = true
    @AppStorage(PrefKey.unitsRaw) private var unitsRaw = DistanceUnit.meters.rawValue

    @State private var showConfirmEnd = false
    @State private var showSaveSheet = false
    @State private var didBeepRest = false

    private var unit: DistanceUnit { DistanceUnit(rawValue: unitsRaw) ?? .meters }
    private var fmt: UnitFormatter { UnitFormatter(unit: unit) }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle(runner.workoutName ?? "Free swim")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        if runner.recorded.isEmpty {
                            dismiss()
                        } else {
                            showConfirmEnd = true
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if runner.phase != .ready {
                        Button("Finish") {
                            runner.finish()
                            showSaveSheet = true
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .confirmationDialog("End this swim?",
                                isPresented: $showConfirmEnd,
                                titleVisibility: .visible) {
                Button("Save what I've swum") {
                    runner.finish()
                    showSaveSheet = true
                }
                Button("Discard", role: .destructive) { dismiss() }
                Button("Keep swimming", role: .cancel) {}
            }
            .sheet(isPresented: $showSaveSheet) {
                SaveSessionView(runner: runner) {
                    dismiss()
                }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    runner.reconcile(at: .now)
                }
            }
            .onChange(of: runner.phase) { _, newPhase in
                if newPhase == .resting { didBeepRest = false }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch runner.phase {
        case .ready:
            readyState
        case .swimming, .resting:
            runningState
        case .finished:
            finishedState
        }
    }

    // MARK: - Ready

    private var readyState: some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle().fill(Theme.accentSoft).frame(width: 120, height: 120)
                Image(systemName: "figure.pool.swim")
                    .font(.system(size: 54))
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)
            VStack(spacing: 6) {
                Text(runner.workoutName ?? "Free swim")
                    .font(Theme.rounded(24, .bold))
                    .foregroundStyle(Theme.ink)
                Text("\(runner.totalReps) reps · \(fmt.distance(plannedDistance))")
                    .font(.callout)
                    .foregroundStyle(Theme.inkSoft)
            }
            if let first = runner.currentRep {
                upcomingRepCard(first, label: "First up")
            }
            Spacer()
            PrimaryButton(title: "Start swimming", systemImage: "play.fill") {
                Haptics.success(hapticsEnabled)
                runner.start()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Running (swim + rest share the timeline)

    private var runningState: some View {
        VStack(spacing: 18) {
            progressHeader
            if let rep = runner.currentRep {
                currentSetBanner(rep)
            }
            Spacer(minLength: 0)
            TimelineView(.periodic(from: .now, by: 0.1)) { timeline in
                clock(now: timeline.date)
            }
            Spacer(minLength: 0)
            if let next = runner.nextRep {
                upcomingRepCard(next, label: "Next")
            }
            actionButton
        }
        .padding(20)
    }

    private func clock(now: Date) -> some View {
        Group {
            switch runner.phase {
            case .resting:
                restClock(now: now)
            default:
                swimClock(now: now)
            }
        }
    }

    private func swimClock(now: Date) -> some View {
        let elapsed = runner.swimElapsed(at: now)
        return VStack(spacing: 8) {
            Text("Swimming")
                .font(Theme.rounded(15, .semibold))
                .foregroundStyle(Theme.accent)
            Text(UnitFormatter.clock(elapsed))
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink)
                .monospacedDigit()
                .contentTransition(.numericText())
            if let rep = runner.currentRep, rep.sendOffSeconds > 0 {
                Text("On \(UnitFormatter.clock(Double(rep.sendOffSeconds)))")
                    .font(.footnote)
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Swimming \(Int(elapsed)) seconds")
    }

    private func restClock(now: Date) -> some View {
        let remaining = runner.restRemaining(at: now)
        // Auto-advance and beep when rest elapses (side effects kept idempotent).
        if remaining <= 0 {
            DispatchQueue.main.async { handleRestElapsed(now: now) }
        } else if remaining <= 3 && !didBeepRest {
            DispatchQueue.main.async { signalRestEnding() }
        }
        return VStack(spacing: 8) {
            Text("Rest")
                .font(Theme.rounded(15, .semibold))
                .foregroundStyle(Theme.good)
            Text(UnitFormatter.clock(max(0, remaining)))
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink)
                .monospacedDigit()
                .contentTransition(.numericText())
            Text("Next rep starts automatically")
                .font(.footnote)
                .foregroundStyle(Theme.inkSoft)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Resting, \(Int(max(0, remaining))) seconds remaining")
    }

    private var actionButton: some View {
        Group {
            switch runner.phase {
            case .swimming:
                PrimaryButton(title: "Record split", systemImage: "stopwatch") {
                    Haptics.rigid(hapticsEnabled)
                    runner.recordSplit()
                }
            case .resting:
                SecondaryButton(title: "Skip rest", systemImage: "forward.fill") {
                    Haptics.tap(hapticsEnabled)
                    runner.skipRest()
                }
            default:
                EmptyView()
            }
        }
    }

    private var progressHeader: some View {
        let done = runner.recorded.count
        let total = max(1, runner.totalReps)
        return VStack(spacing: 6) {
            HStack {
                Text("Rep \(min(done + 1, total)) of \(total)")
                    .font(Theme.rounded(14, .semibold))
                    .foregroundStyle(Theme.inkSoft)
                Spacer()
                Text(fmt.distance(runner.recordedDistance))
                    .font(Theme.rounded(14, .semibold))
                    .foregroundStyle(Theme.accent)
                    .monospacedDigit()
            }
            ProgressView(value: Double(done), total: Double(total))
                .tint(Theme.accent)
        }
        .accessibilityElement(children: .combine)
    }

    private func currentSetBanner(_ rep: RunnerRep) -> some View {
        HStack(spacing: 14) {
            Image(systemName: rep.stroke.symbol)
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 40)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text("\(Int(unit.value(fromMeters: rep.distanceMeters))) \(unit.shortUnit) \(rep.stroke.label)")
                    .font(Theme.rounded(20, .bold))
                    .foregroundStyle(.white)
                if !rep.note.isEmpty {
                    Text(rep.note)
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.waterGradient))
    }

    private func upcomingRepCard(_ rep: RunnerRep, label: String) -> some View {
        HStack(spacing: 12) {
            Text(label.uppercased())
                .font(Theme.rounded(11, .bold))
                .foregroundStyle(Theme.inkFaint)
            StrokeBadge(stroke: rep.stroke)
            Text("\(Int(unit.value(fromMeters: rep.distanceMeters))) \(unit.shortUnit)")
                .font(Theme.rounded(14, .semibold))
                .foregroundStyle(Theme.ink)
            if rep.sendOffSeconds > 0 {
                Pill(text: "@ \(UnitFormatter.clock(Double(rep.sendOffSeconds)))", color: Theme.accentDeep)
            }
            Spacer()
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.surfaceAlt))
    }

    // MARK: - Finished

    private var finishedState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 60))
                .foregroundStyle(Theme.good)
                .accessibilityHidden(true)
            Text("Swim complete")
                .font(Theme.rounded(26, .bold))
                .foregroundStyle(Theme.ink)
            HStack(spacing: 12) {
                StatTile(title: "Distance", value: fmt.distance(runner.recordedDistance), symbol: "ruler")
                StatTile(title: "Swim time", value: UnitFormatter.clock(runner.recordedTime), symbol: "stopwatch")
            }
            Spacer()
            PrimaryButton(title: "Save to log", systemImage: "square.and.arrow.down") {
                showSaveSheet = true
            }
            .padding(.bottom, 24)
        }
        .padding(20)
    }

    // MARK: - Helpers

    private var plannedDistance: Double {
        runner.reps.reduce(0) { $0 + $1.distanceMeters }
    }

    private func handleRestElapsed(now: Date) {
        guard runner.phase == .resting else { return }
        signalRestEnding()
        runner.completeRestIfDue(at: now)
    }

    private func signalRestEnding() {
        guard !didBeepRest else { return }
        didBeepRest = true
        if beepEnabled {
            Haptics.success(hapticsEnabled)
        }
    }
}
