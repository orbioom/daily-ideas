import SwiftUI
import SwiftData
import UIKit

struct FocusView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(filter: #Predicate<Project> { !$0.isArchived },
           sort: \Project.createdAt) private var projects: [Project]
    @Query private var settingsList: [AppSettings]

    @State private var engine = TimerEngine()
    @State private var selectedProject: Project?
    @State private var selectedMode: SessionMode = .pomodoro
    @State private var customMinutes: Int = 45
    @State private var showSetup = true
    @State private var lastCompletionMessage: String?
    @State private var didFireTargetHaptic = false

    private var settings: AppSettings? { settingsList.first }
    private var haptics: Bool { settings?.hapticsEnabled ?? true }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Palette.appBackground.ignoresSafeArea()
                content
            }
            .navigationTitle("Focus")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear(perform: configureDefaultsIfNeeded)
        .onChange(of: engine.state) { _, _ in updateIdleTimer() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { updateIdleTimer() }
            if newPhase != .active { UIApplication.shared.isIdleTimerDisabled = false }
        }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }

    /// Honors the "keep screen awake" preference only while a timer is running.
    private func updateIdleTimer() {
        let keepAwake = settings?.keepScreenAwake ?? true
        UIApplication.shared.isIdleTimerDisabled = keepAwake && engine.state == .running
    }

    @ViewBuilder
    private var content: some View {
        switch engine.state {
        case .idle where showSetup:
            setupScreen
        default:
            activeScreen
        }
    }

    // MARK: - Setup

    private var setupScreen: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xl) {
                modePicker
                if selectedMode == .custom { customLengthCard }
                projectPicker
                summaryPreview
                Button(action: startSession) {
                    Label("Start focus", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.md)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityHint("Begin a focus session")
            }
            .padding(Theme.Spacing.lg)
        }
    }

    private var modePicker: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader(title: "Mode")
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(SessionMode.allCases) { mode in
                    Button {
                        Haptics.selection(haptics)
                        selectedMode = mode
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: mode.symbol)
                                .font(.title3)
                            Text(mode.label)
                                .font(.caption.weight(.semibold))
                            Text(modeSubtitle(mode))
                                .font(.caption2)
                                .foregroundStyle(Theme.Palette.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.md)
                        .background(selectedMode == mode ? Theme.Palette.brandSoft : Theme.Palette.surface)
                        .foregroundStyle(selectedMode == mode ? Theme.Palette.brand : Theme.Palette.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                                .stroke(selectedMode == mode ? Theme.Palette.brand : Theme.Palette.hairline,
                                        lineWidth: selectedMode == mode ? 2 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selectedMode == mode ? [.isSelected] : [])
                }
            }
        }
    }

    private func modeSubtitle(_ mode: SessionMode) -> String {
        switch mode {
        case .pomodoro: return "\(settings?.focusMinutes ?? 25)/\(settings?.shortBreakMinutes ?? 5)"
        case .custom: return "\(customMinutes) min"
        case .flow: return "Open"
        }
    }

    private var customLengthCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                SectionHeader(title: "Length")
                Spacer()
                Text("\(customMinutes) min")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.Palette.brand)
            }
            Stepper(value: $customMinutes, in: 5...180, step: 5) {
                Text("Focus length")
                    .foregroundStyle(Theme.Palette.textSecondary)
                    .font(.subheadline)
            }
            .accessibilityValue("\(customMinutes) minutes")
        }
        .padding(Theme.Spacing.lg)
        .cardSurface()
    }

    private var projectPicker: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader(title: "Project")
            if projects.isEmpty {
                Text("No projects yet — sessions will be saved as Unassigned. Add projects in the Tasks tab.")
                    .font(.footnote)
                    .foregroundStyle(Theme.Palette.textSecondary)
                    .padding(Theme.Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardSurface()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Spacing.sm) {
                        unassignedButton
                        ForEach(projects) { project in
                            projectButton(project)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private var unassignedButton: some View {
        Button {
            Haptics.selection(haptics)
            selectedProject = nil
        } label: {
            ProjectChip(name: "Unassigned", color: Theme.Palette.textSecondary, icon: "tray")
                .opacity(selectedProject == nil ? 1 : 0.5)
                .overlay(
                    Capsule().stroke(selectedProject == nil ? Theme.Palette.brand : .clear, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
    }

    private func projectButton(_ project: Project) -> some View {
        Button {
            Haptics.selection(haptics)
            selectedProject = project
        } label: {
            ProjectChip(name: project.name, color: project.color, icon: project.iconName)
                .opacity(selectedProject?.id == project.id ? 1 : 0.55)
                .overlay(
                    Capsule().stroke(selectedProject?.id == project.id ? project.color : .clear, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
    }

    private var summaryPreview: some View {
        let lengthText: String = selectedMode == .flow ? "Open-ended"
            : TimeFormat.duration(minutes: plannedMinutes)
        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Ready")
                    .font(.caption)
                    .foregroundStyle(Theme.Palette.textSecondary)
                Text(lengthText)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Theme.Palette.textPrimary)
            }
            Spacer()
            if let p = selectedProject {
                ProjectChip(name: p.name, color: p.color, icon: p.iconName)
            }
        }
        .padding(Theme.Spacing.lg)
        .cardSurface(elevated: true)
    }

    private var plannedMinutes: Int {
        switch selectedMode {
        case .pomodoro: return settings?.focusMinutes ?? 25
        case .custom: return customMinutes
        case .flow: return 0
        }
    }

    // MARK: - Active run

    private var activeScreen: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            let now = timeline.date
            VStack(spacing: Theme.Spacing.xl) {
                phaseBadge
                ringSection(now: now)
                if !engine.isBreak {
                    distractionSection
                }
                controlButtons(now: now)
                if let msg = lastCompletionMessage {
                    Text(msg)
                        .font(.subheadline)
                        .foregroundStyle(Theme.Palette.success)
                        .transition(.opacity)
                }
            }
            .padding(Theme.Spacing.xl)
            .onChange(of: engine.hasReachedTarget(at: now)) { _, reached in
                if reached { handleTargetReached(now: now) }
            }
        }
    }

    private var phaseBadge: some View {
        let (label, color): (String, Color) = {
            switch engine.phase {
            case .focus: return (engine.isOpenEnded ? "Flow focus" : "Focus", Theme.Palette.warm)
            case .shortBreak: return ("Short break", Theme.Palette.success)
            case .longBreak: return ("Long break", Theme.Palette.brand)
            }
        }()
        return Text(label.uppercased())
            .font(.caption.weight(.bold))
            .tracking(1.5)
            .foregroundStyle(color)
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, 6)
            .background(color.opacity(0.14))
            .clipShape(Capsule())
    }

    private func ringSection(now: Date) -> some View {
        let remaining = engine.remaining(at: now)
        let ringColor = engine.isBreak ? Theme.Palette.success : Theme.Palette.warm
        return ZStack {
            ProgressRing(progress: engine.progress(at: now),
                         ringColor: ringColor,
                         reduceMotion: reduceMotion)
                .frame(width: 260, height: 260)
            VStack(spacing: 6) {
                Text(TimeFormat.clock(remaining))
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Theme.Palette.textPrimary)
                if let p = selectedProject, !engine.isBreak {
                    ProjectChip(name: p.name, color: p.color, icon: p.iconName)
                }
                if engine.isOpenEnded {
                    Text("Tap stop when you're done")
                        .font(.caption)
                        .foregroundStyle(Theme.Palette.textSecondary)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(engine.isBreak ? "Break time remaining" : "Focus time remaining")
        .accessibilityValue(TimeFormat.clock(remaining))
    }

    private var distractionSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("Distractions")
                .font(.caption)
                .foregroundStyle(Theme.Palette.textSecondary)
            HStack(spacing: Theme.Spacing.lg) {
                Text("\(engine.distractionCount)")
                    .font(.title.weight(.bold).monospacedDigit())
                    .foregroundStyle(Theme.Palette.textPrimary)
                Button {
                    Haptics.warning(haptics)
                    engine.addDistraction()
                } label: {
                    Label("Got distracted", systemImage: "exclamationmark.bubble.fill")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.vertical, Theme.Spacing.sm)
                }
                .buttonStyle(.bordered)
                .tint(Theme.Palette.danger)
                .accessibilityHint("Increase the distraction counter for this session")
            }
        }
        .padding(Theme.Spacing.lg)
        .cardSurface()
    }

    private func controlButtons(now: Date) -> some View {
        HStack(spacing: Theme.Spacing.lg) {
            // Stop / give up.
            Button {
                handleStop(now: now)
            } label: {
                Label("End", systemImage: "stop.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.md)
            }
            .buttonStyle(.bordered)
            .tint(Theme.Palette.danger)

            // Pause / resume / next.
            if engine.isBreak {
                if engine.state == .paused {
                    Button {
                        Haptics.tap(haptics)
                        didFireTargetHaptic = false
                        engine.resume()
                    } label: {
                        Label("Start break", systemImage: "play.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Spacing.md)
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button {
                        skipBreak()
                    } label: {
                        Label("Skip break", systemImage: "forward.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Spacing.md)
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if engine.state == .running {
                Button {
                    Haptics.tap(haptics)
                    engine.pause()
                } label: {
                    Label("Pause", systemImage: "pause.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.md)
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button {
                    Haptics.tap(haptics)
                    engine.resume()
                } label: {
                    Label("Resume", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.md)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    // MARK: - Actions

    private func configureDefaultsIfNeeded() {
        if let s = settings { selectedMode = s.defaultMode }
        if selectedProject == nil { selectedProject = projects.first }
    }

    private func startSession() {
        let s = settings
        engine.configure(mode: selectedMode,
                         focusMinutes: plannedMinutes == 0 ? 25 : plannedMinutes,
                         breakMinutes: s?.shortBreakMinutes ?? 5,
                         roundsBeforeLong: s?.roundsBeforeLongBreak ?? 4,
                         tag: "")
        didFireTargetHaptic = false
        lastCompletionMessage = nil
        withAnimation(reduceMotion ? nil : .easeInOut) {
            showSetup = false
        }
        engine.start()
        Haptics.tap(haptics)
    }

    private func handleTargetReached(now: Date) {
        guard !didFireTargetHaptic else { return }
        didFireTargetHaptic = true
        Haptics.success(haptics)

        if engine.isBreak {
            // Break finished — return to a fresh focus phase, ready to start.
            engine.beginNextFocus()
            didFireTargetHaptic = false
            withAnimation { lastCompletionMessage = "Break over — ready when you are." }
            if settings?.autoStartBreaks ?? false {
                // If breaks auto-start, also auto-start the next focus round.
                engine.start()
            }
            return
        }

        // Persist the completed focus phase, then move into the break.
        if let result = engine.finalizeFocus(at: now, completed: true) {
            persist(result)
            withAnimation { lastCompletionMessage = "Nice — \(result.focusedSeconds / 60) min logged." }
        }
        let s = settings
        engine.beginBreak(longBreakMinutes: s?.longBreakMinutes ?? 15,
                          shortBreakMinutes: s?.shortBreakMinutes ?? 5)
        // beginBreak starts the break running; pause it if auto-start is disabled.
        if !(s?.autoStartBreaks ?? false) {
            engine.pause()
        } else {
            // Reset the haptic latch so the break's own completion can fire.
            didFireTargetHaptic = false
        }
    }

    private func handleStop(now: Date) {
        if !engine.isBreak {
            // Log whatever focus was accrued as an abandoned (or completed flow) session.
            let isFlow = engine.isOpenEnded
            if let result = engine.finalizeFocus(at: now, completed: isFlow) {
                persist(result)
                if isFlow {
                    Haptics.success(haptics)
                }
            }
        }
        engine.returnToIdle()
        withAnimation(reduceMotion ? nil : .easeInOut) {
            showSetup = true
        }
    }

    private func skipBreak() {
        Haptics.tap(haptics)
        engine.beginNextFocus()
        didFireTargetHaptic = false
        lastCompletionMessage = nil
        engine.start()
    }

    private func persist(_ result: TimerEngine.FocusResult) {
        let session = FocusSession(
            startedAt: result.startedAt,
            endedAt: result.endedAt,
            focusedSeconds: result.focusedSeconds,
            plannedSeconds: result.plannedSeconds,
            mode: result.mode,
            tag: "",
            note: "",
            wasCompleted: result.completed,
            distractionCount: result.distractionCount,
            project: selectedProject
        )
        context.insert(session)
        try? context.save()
    }
}

#Preview {
    FocusView()
        .modelContainer(for: [Project.self, FocusSession.self, AppSettings.self], inMemory: true)
}
