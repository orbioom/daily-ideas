import SwiftUI
import SwiftData

/// Live workout: check off sets, edit weight/reps, rest timer between sets,
/// finish to save the session and apply progression.
struct ActiveWorkoutView: View {
    @Bindable var session: WorkoutSession
    let onClose: () -> Void

    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.scenePhase) private var scenePhase

    /// Wall-clock workout start, so duration survives backgrounding.
    @State private var startedAt = Date()
    /// When the current rest period began; nil = no timer running.
    @State private var restStartedAt: Date?
    @State private var restTarget: Int = 150
    @State private var showFinishConfirm = false
    @State private var showCancelConfirm = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(session.orderedExercises) { exercise in
                            exerciseCard(exercise)
                        }
                        PrimaryButton(title: "Finish workout", systemImage: "checkmark.circle.fill") {
                            showFinishConfirm = true
                        }
                        .padding(.top, 4)
                    }
                    .padding(20)
                    .padding(.bottom, restStartedAt != nil ? 90 : 0)
                }
            }
            .navigationTitle(session.dayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showCancelConfirm = true }
                        .foregroundStyle(Theme.bad)
                }
                ToolbarItem(placement: .principal) {
                    TimelineView(.periodic(from: startedAt, by: 1)) { ctx in
                        Text(elapsedText(now: ctx.date))
                            .font(Theme.num(15, .semibold))
                            .monospacedDigit()
                            .foregroundStyle(Theme.inkSoft)
                            .accessibilityLabel("Elapsed time \(elapsedText(now: ctx.date))")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if restStartedAt != nil {
                    restTimerBar
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                // Timers are driven by stored Dates, so they stay correct across backgrounding.
                // On return, clear a rest bar whose period already finished while we were away.
                if newPhase == .active, let start = restStartedAt,
                   Int(Date().timeIntervalSince(start)) >= restTarget {
                    restStartedAt = nil
                }
            }
            .confirmationDialog("Finish this workout?", isPresented: $showFinishConfirm, titleVisibility: .visible) {
                Button("Finish & save") { finish() }
                Button("Keep going", role: .cancel) {}
            } message: {
                Text("Completed sets will be saved and your weights progressed.")
            }
            .confirmationDialog("Discard this workout?", isPresented: $showCancelConfirm, titleVisibility: .visible) {
                Button("Discard", role: .destructive) { cancel() }
                Button("Keep going", role: .cancel) {}
            }
        }
        .interactiveDismissDisabled(true)
        .onAppear { restTarget = max(settings.defaultRestSeconds, 5) }
    }

    // MARK: Exercise card

    private func exerciseCard(_ exercise: LoggedExercise) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(exercise.name)
                        .font(Theme.rounded(18, .bold))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    MuscleBadge(group: exercise.group)
                }
                ForEach(exercise.orderedSets) { set in
                    SetRow(set: set,
                           unit: settings.unit,
                           onToggle: { toggle(set) },
                           hapticsOn: settings.hapticsEnabled)
                }
                Button {
                    addSet(to: exercise)
                } label: {
                    Label("Add set", systemImage: "plus.circle")
                        .font(Theme.rounded(14, .semibold))
                        .foregroundStyle(Theme.accent)
                }
                .padding(.top, 2)
            }
        }
    }

    // MARK: Rest timer bar

    private var restTimerBar: some View {
        TimelineView(.periodic(from: restStartedAt ?? Date(), by: 1)) { ctx in
            let remaining = remainingRest(now: ctx.date)
            HStack(spacing: 14) {
                Image(systemName: remaining > 0 ? "timer" : "checkmark.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(remaining > 0 ? Theme.accent : Theme.good)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 1) {
                    Text(remaining > 0 ? "Rest" : "Rest done")
                        .font(Theme.rounded(12, .semibold))
                        .foregroundStyle(Theme.inkSoft)
                    Text(clock(remaining))
                        .font(Theme.num(22, .heavy))
                        .monospacedDigit()
                        .foregroundStyle(remaining > 0 ? Theme.ink : Theme.good)
                }
                Spacer()
                Button {
                    restStartedAt = nil
                    Haptics.tap(settings.hapticsEnabled)
                } label: {
                    Text("Skip")
                        .font(Theme.rounded(15, .semibold))
                        .foregroundStyle(Theme.accent)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .overlay(Rectangle().frame(height: 0.5).foregroundStyle(Theme.hairline), alignment: .top)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Rest timer, \(clock(remaining)) remaining")
        }
    }

    // MARK: Actions

    private func toggle(_ set: LoggedSet) {
        set.isComplete.toggle()
        if set.isComplete {
            Haptics.success(settings.hapticsEnabled)
            // Start a fresh rest period from now.
            restTarget = max(settings.defaultRestSeconds, 5)
            restStartedAt = Date()
        } else {
            Haptics.tap(settings.hapticsEnabled)
        }
        try? context.save()
    }

    private func addSet(to exercise: LoggedExercise) {
        let last = exercise.orderedSets.last
        let new = LoggedSet(setIndex: exercise.sets.count,
                            weightKg: last?.weightKg ?? 0,
                            reps: last?.reps ?? 5,
                            isWarmup: false,
                            isComplete: false)
        new.exercise = exercise
        exercise.sets.append(new)
        Haptics.tap(settings.hapticsEnabled)
        try? context.save()
    }

    private func finish() {
        session.durationSeconds = max(Int(Date().timeIntervalSince(startedAt)), 0)
        session.isComplete = true
        try? context.save()
        Haptics.heavy(settings.hapticsEnabled)
        onClose()
    }

    private func cancel() {
        context.delete(session)
        try? context.save()
        Haptics.warning(settings.hapticsEnabled)
        onClose()
    }

    // MARK: Time helpers

    private func remainingRest(now: Date) -> Int {
        guard let start = restStartedAt else { return 0 }
        let elapsed = Int(now.timeIntervalSince(start))
        return max(restTarget - elapsed, 0)
    }

    private func elapsedText(now: Date) -> String {
        clock(max(Int(now.timeIntervalSince(startedAt)), 0))
    }

    private func clock(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

/// A single editable set row with a completion toggle.
private struct SetRow: View {
    @Bindable var set: LoggedSet
    let unit: WeightUnit
    let onToggle: () -> Void
    let hapticsOn: Bool

    @State private var weightText = ""
    @State private var repsText = ""

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: set.isComplete ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 26))
                    .foregroundStyle(set.isComplete ? Theme.good : Theme.inkFaint)
            }
            .accessibilityLabel(set.isComplete ? "Set complete" : "Mark set complete")

            Text(set.isWarmup ? "W" : "\(set.setIndex + 1)")
                .font(Theme.rounded(13, .bold))
                .foregroundStyle(set.isWarmup ? Theme.steel : Theme.inkSoft)
                .frame(width: 22)

            HStack(spacing: 4) {
                TextField("0", text: $weightText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .font(Theme.num(18, .bold))
                    .frame(width: 64)
                    .onChange(of: weightText) { _, newValue in
                        if let v = Double(newValue.replacingOccurrences(of: ",", with: ".")) {
                            set.weightKg = Units.fromDisplay(max(v, 0), unit: unit)
                        }
                    }
                Text(unit.label)
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkFaint)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Theme.surfaceAlt))
            .accessibilityLabel("Weight")
            .accessibilityValue(weightText + " " + unit.label)

            Text("×")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkFaint)

            HStack(spacing: 4) {
                TextField("0", text: $repsText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(Theme.num(18, .bold))
                    .frame(width: 44)
                    .onChange(of: repsText) { _, newValue in
                        if let v = Int(newValue) { set.reps = max(v, 0) }
                    }
                Text("reps")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkFaint)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Theme.surfaceAlt))
            .accessibilityLabel("Reps")
            .accessibilityValue(repsText)
        }
        .onAppear {
            weightText = Units.formatNumber(set.weightKg, unit: unit)
            repsText = String(set.reps)
        }
    }
}
