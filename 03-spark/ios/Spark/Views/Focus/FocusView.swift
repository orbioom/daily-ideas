import SwiftUI
import SwiftData

struct FocusView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Query(
        filter: #Predicate<FocusTask> { !$0.isCompleted },
        sort: \FocusTask.sortIndex
    ) private var pendingTasks: [FocusTask]
    @AppStorage(SparkSettings.defaultDuration) private var defaultDuration = 25
    @AppStorage(SparkSettings.warningHaptics) private var warningHaptics = true
    @AppStorage(SparkSettings.keepScreenOn) private var keepScreenOn = true
    @State private var timerEngine = FocusTimerEngine()
    @State private var currentTask: FocusTask? = nil
    @State private var selectedDuration: Int = 25
    @State private var showDurationPicker = false
    @State private var showCompletionSheet = false
    @State private var showTaskPicker = false
    @State private var lastWarning: FocusTimerEngine.FocusWarning = .normal
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var activeTask: FocusTask? {
        currentTask ?? pendingTasks.first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    if timerEngine.isRunning || timerEngine.isPaused {
                        activeTimerView
                    } else {
                        idleView
                    }
                }
            }
            .navigationTitle("Focus")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: timerEngine.warningState) { _, newState in
                guard warningHaptics else { return }
                if newState == .fiveMinutes && lastWarning == .normal {
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                } else if newState == .almostDone && lastWarning != .almostDone {
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                }
                lastWarning = newState
            }
            .onChange(of: timerEngine.remainingSeconds) { _, remaining in
                if remaining == 0 && timerEngine.isRunning == false {
                    handleTimerComplete()
                }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active && timerEngine.isPaused == false && timerEngine.isRunning {
                }
            }
            .onAppear {
                selectedDuration = defaultDuration
                if keepScreenOn { UIApplication.shared.isIdleTimerDisabled = true }
            }
            .onDisappear {
                UIApplication.shared.isIdleTimerDisabled = false
            }
            .sheet(isPresented: $showTaskPicker) {
                TaskPickerView(tasks: pendingTasks, selected: $currentTask)
            }
            .sheet(isPresented: $showCompletionSheet) {
                SessionCompleteView(
                    taskTitle: activeTask?.title ?? "Focus Session",
                    minutes: timerEngine.elapsedSeconds / 60
                ) { markDone in
                    saveSession(completed: markDone)
                    if markDone { activeTask.map { $0.isCompleted = true; $0.completedDate = Date() } }
                    showCompletionSheet = false
                }
            }
        }
    }

    private var idleView: some View {
        ScrollView {
            VStack(spacing: 28) {
                Spacer(minLength: 20)

                if let task = activeTask {
                    currentTaskCard(task)
                } else {
                    emptyTaskCard
                }

                timerRingDisplay(progress: 0)

                durationSelector
                startButton
            }
            .padding(24)
        }
    }

    private func currentTaskCard(_ task: FocusTask) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: task.category.icon)
                    .foregroundStyle(SparkTheme.categoryColor(task.category))
                    .accessibilityHidden(true)
                Text(task.category.rawValue.uppercased())
                    .font(.caption.weight(.bold))
                    .foregroundStyle(SparkTheme.categoryColor(task.category))
                    .kerning(0.5)
                Spacer()
                Button {
                    showTaskPicker = true
                } label: {
                    Text("Switch")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(SparkTheme.electricBlue)
                }
            }

            Text(task.title)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            if !task.note.isEmpty {
                Text(task.note)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(SparkTheme.categoryColor(task.category).opacity(0.3), lineWidth: 1.5)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Current task: \(task.title), category: \(task.category.rawValue)")
    }

    private var emptyTaskCard: some View {
        Button {
            showTaskPicker = true
        } label: {
            VStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(SparkTheme.electricBlue)
                    .accessibilityHidden(true)
                Text("Choose a Task")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("Or just start a free-form focus session")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }

    private func timerRingDisplay(progress: Double) -> some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGroupedBackground), lineWidth: 18)
                .frame(width: 200, height: 200)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    timerEngine.isRunning || timerEngine.isPaused
                        ? timerEngine.progressColor.gradient
                        : SparkTheme.electricBlue.opacity(0.3).gradient,
                    style: StrokeStyle(lineWidth: 18, lineCap: .round)
                )
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .easeInOut(duration: 1.0), value: progress)

            VStack(spacing: 4) {
                Text(timerEngine.isRunning || timerEngine.isPaused
                     ? timerEngine.timeString
                     : String(format: "%02d:00", selectedDuration))
                    .font(.system(size: 44, weight: .bold, design: .monospaced))
                    .foregroundStyle(.primary)
                    .accessibilityLabel("Time remaining: \(timerEngine.isRunning || timerEngine.isPaused ? timerEngine.timeString : "\(selectedDuration) minutes")")

                if timerEngine.isRunning {
                    Text(warningText)
                        .font(.caption)
                        .foregroundStyle(timerEngine.progressColor)
                        .animation(.easeInOut, value: timerEngine.warningState)
                }
            }
        }
        .frame(width: 220, height: 220)
    }

    private var warningText: String {
        switch timerEngine.warningState {
        case .almostDone: return "Almost done!"
        case .fiveMinutes: return "5 min left"
        case .normal: return "Keep going"
        }
    }

    private var durationSelector: some View {
        HStack(spacing: 0) {
            ForEach([15, 25, 45, 60], id: \.self) { mins in
                Button {
                    selectedDuration = mins
                } label: {
                    Text("\(mins)m")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            selectedDuration == mins
                                ? SparkTheme.electricBlue
                                : Color(.secondarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                        .foregroundStyle(selectedDuration == mins ? .white : .primary)
                }
                .accessibilityAddTraits(selectedDuration == mins ? .isSelected : [])
                .accessibilityLabel("\(mins) minutes")
            }
        }
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
        .disabled(timerEngine.isRunning || timerEngine.isPaused)
        .opacity(timerEngine.isRunning || timerEngine.isPaused ? 0.4 : 1)
    }

    private var startButton: some View {
        Group {
            if !timerEngine.isRunning && !timerEngine.isPaused {
                Button {
                    timerEngine.start(minutes: selectedDuration)
                    lastWarning = .normal
                } label: {
                    Text("Start Focus")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(SparkTheme.electricBlue, in: RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }

    private var activeTimerView: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 40)

            if let task = activeTask {
                Text(task.title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            timerRingDisplay(progress: timerEngine.progress)

            HStack(spacing: 16) {
                Button {
                    let elapsed = timerEngine.stop()
                    showCompletionSheet = true
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(.systemRed), in: RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    if timerEngine.isPaused { timerEngine.resume() }
                    else { timerEngine.pause() }
                } label: {
                    Label(timerEngine.isPaused ? "Resume" : "Pause",
                          systemImage: timerEngine.isPaused ? "play.fill" : "pause.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(SparkTheme.electricBlue, in: RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    private func handleTimerComplete() {
        if warningHaptics {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        showCompletionSheet = true
    }

    private func saveSession(completed: Bool) {
        let elapsed = max(1, timerEngine.elapsedSeconds / 60)
        let session = FocusSession(
            taskTitle: activeTask?.title ?? "Focus Session",
            plannedMinutes: selectedDuration,
            actualMinutes: elapsed,
            wasCompleted: completed,
            category: activeTask?.category ?? .work
        )
        context.insert(session)
        timerEngine.isRunning = false
        timerEngine.isPaused = false
    }
}

struct TaskPickerView: View {
    let tasks: [FocusTask]
    @Binding var selected: FocusTask?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if tasks.isEmpty {
                    ContentUnavailableView {
                        Label("No Tasks", systemImage: "checklist")
                    } description: {
                        Text("Add tasks in the Tasks tab to pick one here.")
                    }
                } else {
                    List(tasks) { task in
                        Button {
                            selected = task
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: task.category.icon)
                                    .foregroundStyle(SparkTheme.categoryColor(task.category))
                                    .frame(width: 28)
                                    .accessibilityHidden(true)
                                Text(task.title)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selected?.id == task.id {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(SparkTheme.electricBlue)
                                        .accessibilityHidden(true)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Pick a Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }
}

struct SessionCompleteView: View {
    let taskTitle: String
    let minutes: Int
    let onDone: (Bool) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .fill(SparkTheme.focusGreen.opacity(0.15))
                    .frame(width: 120, height: 120)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(SparkTheme.focusGreen)
                    .accessibilityHidden(true)
            }
            .scaleEffect(reduceMotion ? 1 : 1.0)

            VStack(spacing: 8) {
                Text("Session Done!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text("\(minutes) min on"\(taskTitle)"")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(spacing: 12) {
                Button {
                    onDone(true)
                } label: {
                    Text("✓ Task Done!")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(SparkTheme.focusGreen, in: RoundedRectangle(cornerRadius: 14))
                }
                .accessibilityLabel("Mark task as done")

                Button {
                    onDone(false)
                } label: {
                    Text("Still Working on It")
                        .font(.subheadline)
                        .foregroundStyle(SparkTheme.electricBlue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(SparkTheme.electricBlue.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                }
                .accessibilityLabel("Keep task as in progress")
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .interactiveDismissDisabled()
    }
}
