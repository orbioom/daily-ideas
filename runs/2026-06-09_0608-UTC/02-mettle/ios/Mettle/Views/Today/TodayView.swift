import SwiftUI
import SwiftData

struct TodayView: View {
    @Query(filter: #Predicate<Challenge> { $0.isActive == true })
    private var activeChallenges: [Challenge]

    private var active: Challenge? { activeChallenges.first }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                if let challenge = active {
                    ActiveTodayContent(challenge: challenge)
                } else {
                    EmptyStateView(
                        icon: "trophy",
                        title: "No active challenge",
                        message: "Pick a program in the Challenges tab and start it to begin tracking today."
                    )
                    .padding(.top, 40)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .scrollContentBackground(.hidden)
        .background(Brand.pageBackground)
        .navigationTitle("Today")
    }
}

/// The body shown when a challenge is active. Split out so SwiftData mutations
/// stay scoped to a concrete `Challenge`.
private struct ActiveTodayContent: View {
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Bindable var challenge: Challenge

    @State private var now = Date()

    private var state: ChallengeEngine.OverallState {
        ChallengeEngine.overallState(for: challenge, now: now)
    }
    private var dayIndex: Int {
        ChallengeEngine.currentDayIndex(for: challenge, now: now)
    }
    private var todayProgress: ChallengeEngine.TodayProgress {
        ChallengeEngine.todayProgress(for: challenge, now: now)
    }

    var body: some View {
        Group {
            switch state {
            case .failed:
                brokenBanner
            case .completed:
                completedBanner
            default:
                runningContent
            }
        }
        .onAppear { now = Date() }
    }

    // MARK: - Running

    private var runningContent: some View {
        VStack(spacing: 18) {
            header

            ringCard

            VStack(spacing: 10) {
                SectionTitle(text: "Today's tasks")
                ForEach(challenge.orderedTasks) { task in
                    TaskRow(task: task,
                            tick: tick(for: task),
                            onToggle: { toggle(task) },
                            onAdd: { add(task, amount: quickStep(task)) },
                            onClear: { clearValue(task) })
                }
            }

            if todayProgress.required > 0 && todayProgress.done >= todayProgress.required {
                dayCompleteBanner
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow(text: challenge.name)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("Day \(dayIndex)")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(Brand.text)
                Text("of \(challenge.durationDays)")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(Brand.text3)
            }
            HStack(spacing: 12) {
                Pill(text: challenge.modeLabel,
                     tint: challenge.hardMode ? Brand.danger : Brand.info)
                Label("\(ChallengeEngine.currentStreak(for: challenge, now: now)) day streak",
                      systemImage: "flame.fill")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Brand.text2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(challenge.name), day \(dayIndex) of \(challenge.durationDays), \(challenge.modeLabel) mode")
    }

    private var ringCard: some View {
        HStack(spacing: 20) {
            ZStack {
                ProgressRing(progress: todayProgress.fraction, lineWidth: 12,
                             tint: todayProgress.done >= todayProgress.required && todayProgress.required > 0
                                ? Brand.live : Brand.magic)
                    .frame(width: 104, height: 104)
                VStack(spacing: 2) {
                    Text("\(todayProgress.done)/\(todayProgress.required)")
                        .font(Brand.mono(22, weight: .bold))
                        .foregroundStyle(Brand.text)
                    Text("tasks")
                        .font(Brand.mono(10, weight: .medium))
                        .foregroundStyle(Brand.text3)
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(todayProgress.done >= todayProgress.required && todayProgress.required > 0
                     ? "Day complete" : "Keep going")
                    .font(.headline)
                    .foregroundStyle(Brand.text)
                Text(todayProgress.done >= todayProgress.required && todayProgress.required > 0
                     ? "Every task is done. Come back tomorrow."
                     : "\(max(0, todayProgress.required - todayProgress.done)) task\(todayProgress.required - todayProgress.done == 1 ? "" : "s") left today.")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
            }
            Spacer(minLength: 0)
        }
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Today's progress: \(todayProgress.done) of \(todayProgress.required) tasks done")
    }

    private var dayCompleteBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title2)
                .foregroundStyle(Brand.live)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Day \(dayIndex) passed")
                    .font(.headline)
                    .foregroundStyle(Brand.text)
                Text("Nice work. Rest up and reset tomorrow.")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
            }
            Spacer(minLength: 0)
        }
        .glassCard()
    }

    // MARK: - Broken / completed

    private var brokenBanner: some View {
        VStack(spacing: 16) {
            header
            VStack(spacing: 12) {
                Image(systemName: "arrow.counterclockwise.circle")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(Brand.danger)
                    .accessibilityHidden(true)
                Text("Streak broken")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Brand.text)
                Text("A required day was missed in hard mode. The run resets to Day 1 — but that's where toughness is built. Ready to go again?")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
                    .multilineTextAlignment(.center)
                Button("Restart at Day 1") { restart() }
                    .buttonStyle(InkButtonStyle())
            }
            .padding(.vertical, 8)
            .glassCard(padding: 20)
        }
    }

    private var completedBanner: some View {
        VStack(spacing: 16) {
            header
            VStack(spacing: 12) {
                Image(systemName: "rosette")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(Brand.live)
                    .accessibilityHidden(true)
                Text("Challenge complete")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Brand.text)
                Text("You finished all \(challenge.durationDays) days of \(challenge.name). That's real mettle.")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 8)
            .glassCard(padding: 20)
        }
    }

    // MARK: - Mutations

    private func todayLogEnsured() -> DayLog? {
        let idx = dayIndex
        guard idx > 0 else { return nil }
        if let existing = ChallengeEngine.log(for: idx, in: challenge.dayLogs) {
            return existing
        }
        let log = DayLog(date: Calendar.current.startOfDay(for: now), dayIndex: idx)
        log.challenge = challenge
        context.insert(log)
        return log
    }

    private func tick(for task: ChallengeTask) -> TaskTick? {
        guard let log = ChallengeEngine.log(for: dayIndex, in: challenge.dayLogs) else { return nil }
        return log.ticks.first { $0.taskTitle == task.title }
    }

    private func tickEnsured(for task: ChallengeTask) -> TaskTick? {
        guard let log = todayLogEnsured() else { return nil }
        if let existing = log.ticks.first(where: { $0.taskTitle == task.title }) {
            return existing
        }
        let t = TaskTick(taskTitle: task.title, value: 0, target: task.targetValue)
        t.dayLog = log
        context.insert(t)
        return t
    }

    private func toggle(_ task: ChallengeTask) {
        guard let t = tickEnsured(for: task) else { return }
        if task.isMeasured {
            // Toggling a measured task fills or empties it to target.
            if t.value >= t.target { t.value = 0 } else { t.value = t.target }
        } else {
            t.done.toggle()
        }
        save()
    }

    private func add(_ task: ChallengeTask, amount: Double) {
        guard task.isMeasured, let t = tickEnsured(for: task) else { return }
        t.value = min(t.value + amount, t.target)
        save()
    }

    private func clearValue(_ task: ChallengeTask) {
        guard let t = tickEnsured(for: task) else { return }
        t.value = 0
        t.done = false
        try? context.save()
        Haptics.selection()
    }

    private func quickStep(_ task: ChallengeTask) -> Double {
        // A sensible single tap increment: aim for ~8 taps to reach target.
        guard task.targetValue > 0 else { return 1 }
        let raw = task.targetValue / 8
        if raw >= 8 { return (raw / 4).rounded() * 4 }
        if raw >= 1 { return raw.rounded() }
        return 1
    }

    private func save() {
        try? context.save()
        let prog = ChallengeEngine.todayProgress(for: challenge, now: now)
        if prog.required > 0 && prog.done >= prog.required {
            Haptics.success()
        } else {
            Haptics.tap()
        }
    }

    private func restart() {
        for log in challenge.dayLogs { context.delete(log) }
        challenge.startDate = Calendar.current.startOfDay(for: Date())
        try? context.save()
        now = Date()
        Haptics.warning()
    }
}

// MARK: - Task row

private struct TaskRow: View {
    let task: ChallengeTask
    let tick: TaskTick?
    let onToggle: () -> Void
    let onAdd: () -> Void
    let onClear: () -> Void

    private var satisfied: Bool { tick?.satisfied ?? false }
    private var value: Double { tick?.value ?? 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Button(action: onToggle) {
                    Image(systemName: satisfied ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(satisfied ? Brand.live : Brand.text3)
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(task.title)
                .accessibilityValue(satisfied ? "Done" : "Not done")
                .accessibilityHint(satisfied ? "Marks the task incomplete" : "Marks the task complete")

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Image(systemName: task.iconName)
                            .font(.subheadline)
                            .foregroundStyle(Brand.text2)
                            .accessibilityHidden(true)
                        Text(task.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Brand.text)
                            .strikethrough(satisfied, color: Brand.text3)
                    }
                    if !task.detail.isEmpty {
                        Text(task.detail)
                            .font(.caption)
                            .foregroundStyle(Brand.text3)
                    }
                }
                Spacer(minLength: 0)
            }

            if task.isMeasured {
                HStack(spacing: 12) {
                    Text("\(Format.number(value)) / \(Format.number(task.targetValue)) \(task.unit)")
                        .font(Brand.mono(13, weight: .medium))
                        .foregroundStyle(satisfied ? Brand.live : Brand.text2)
                    Spacer(minLength: 0)
                    Button(action: onClear) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.subheadline)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Brand.text3)
                    .accessibilityLabel("Clear \(task.title)")
                    Button {
                        onAdd()
                    } label: {
                        Text("+\(Format.number(quickStep))")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(GlassButtonCompact())
                    .accessibilityLabel("Add \(Format.number(quickStep)) \(task.unit) to \(task.title)")
                }
                ProgressView(value: min(value, task.targetValue), total: max(task.targetValue, 1))
                    .tint(satisfied ? Brand.live : Brand.magic)
                    .accessibilityHidden(true)
            }
        }
        .glassCard()
    }

    private var quickStep: Double {
        guard task.targetValue > 0 else { return 1 }
        let raw = task.targetValue / 8
        if raw >= 8 { return (raw / 4).rounded() * 4 }
        if raw >= 1 { return raw.rounded() }
        return 1
    }
}

/// A compact glass button style for inline +N controls.
private struct GlassButtonCompact: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Brand.text)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1))
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1)
            .animation(Brand.ease(0.2), value: configuration.isPressed)
    }
}
