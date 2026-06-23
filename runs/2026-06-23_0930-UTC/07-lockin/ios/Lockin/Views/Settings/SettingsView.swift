import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var settingsList: [AppSettings]
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var showResetConfirm = false

    private var settings: AppSettings? { settingsList.first }

    var body: some View {
        NavigationStack {
            Group {
                if let settings {
                    form(settings)
                } else {
                    ProgressView().tint(Theme.Palette.brand)
                }
            }
            .navigationTitle("Settings")
        }
    }

    private func form(_ s: AppSettings) -> some View {
        let binding = Bindable(s)
        return Form {
            Section("Default mode") {
                Picker("Start sessions as", selection: binding.defaultModeRaw) {
                    ForEach(SessionMode.allCases) { mode in
                        Label(mode.label, systemImage: mode.symbol).tag(mode.rawValue)
                    }
                }
            }

            Section("Pomodoro durations") {
                durationStepper("Focus", value: binding.focusMinutes, range: 5...120, unit: "min")
                durationStepper("Short break", value: binding.shortBreakMinutes, range: 1...30, unit: "min")
                durationStepper("Long break", value: binding.longBreakMinutes, range: 5...60, unit: "min")
                durationStepper("Rounds before long break", value: binding.roundsBeforeLongBreak, range: 2...8, unit: "")
            }

            Section("Behavior") {
                Toggle("Auto-start breaks", isOn: binding.autoStartBreaks)
                Toggle("Keep screen awake while focusing", isOn: binding.keepScreenAwake)
                Toggle("Haptic feedback", isOn: binding.hapticsEnabled)
            }

            Section("About") {
                LabeledContent("Version", value: "1.0")
                LabeledContent("Sessions stored", value: "\(sessionCount)")
                NavigationLink {
                    AboutView()
                } label: {
                    Label("About Lockin", systemImage: "info.circle")
                }
            }

            Section {
                Button {
                    hasOnboarded = false
                } label: {
                    Label("Replay onboarding", systemImage: "sparkles")
                }
                Button(role: .destructive) {
                    showResetConfirm = true
                } label: {
                    Label("Reset preferences", systemImage: "arrow.counterclockwise")
                }
            } footer: {
                Text("Resetting preferences restores default durations and toggles. Your projects and session history are kept.")
            }
        }
        .onChange(of: s.focusMinutes) { _, _ in save() }
        .onChange(of: s.shortBreakMinutes) { _, _ in save() }
        .onChange(of: s.longBreakMinutes) { _, _ in save() }
        .onChange(of: s.roundsBeforeLongBreak) { _, _ in save() }
        .onChange(of: s.autoStartBreaks) { _, _ in save() }
        .onChange(of: s.keepScreenAwake) { _, _ in save() }
        .onChange(of: s.hapticsEnabled) { _, _ in save() }
        .onChange(of: s.defaultModeRaw) { _, _ in save() }
        .confirmationDialog("Reset preferences to defaults?",
                            isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("Reset", role: .destructive) { reset(s) }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func durationStepper(_ title: String, value: Binding<Int>, range: ClosedRange<Int>, unit: String) -> some View {
        Stepper(value: value, in: range) {
            HStack {
                Text(title)
                Spacer()
                Text(unit.isEmpty ? "\(value.wrappedValue)" : "\(value.wrappedValue) \(unit)")
                    .foregroundStyle(Theme.Palette.brand)
                    .font(.body.weight(.semibold))
            }
        }
        .accessibilityValue(unit.isEmpty ? "\(value.wrappedValue)" : "\(value.wrappedValue) \(unit)")
    }

    private var sessionCount: Int {
        (try? context.fetchCount(FetchDescriptor<FocusSession>())) ?? 0
    }

    private func save() {
        Haptics.selection(settings?.hapticsEnabled ?? true)
        try? context.save()
    }

    private func reset(_ s: AppSettings) {
        s.focusMinutes = 25
        s.shortBreakMinutes = 5
        s.longBreakMinutes = 15
        s.roundsBeforeLongBreak = 4
        s.autoStartBreaks = false
        s.keepScreenAwake = true
        s.hapticsEnabled = true
        s.defaultModeRaw = SessionMode.pomodoro.rawValue
        try? context.save()
    }
}

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                Image(systemName: "timer")
                    .font(.system(size: 60))
                    .foregroundStyle(Theme.Palette.brand)
                    .accessibilityHidden(true)
                Text("Lockin")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(Theme.Palette.textPrimary)
                Text("A deep-work focus timer with honest session analytics. Flexible Pomodoro, custom, and open-ended flow timers tied to your projects — no trees, no streaks-shaming, just clear data on where your focus goes.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.Palette.textSecondary)
                    .padding(.horizontal)
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    aboutRow("timer", "Pomodoro, custom & flow timers")
                    aboutRow("folder.fill", "Sessions tied to projects + tags")
                    aboutRow("chart.bar.xaxis", "Minutes, project mix & hour-of-day heatmap")
                    aboutRow("exclamationmark.bubble.fill", "Distraction counter to build awareness")
                    aboutRow("lock.fill", "100% on-device — nothing leaves your phone")
                }
                .padding(Theme.Spacing.lg)
                .cardSurface()
            }
            .padding(Theme.Spacing.lg)
        }
        .background(Theme.Palette.appBackground.ignoresSafeArea())
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func aboutRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .foregroundStyle(Theme.Palette.brand)
                .frame(width: 26)
                .accessibilityHidden(true)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Theme.Palette.textPrimary)
            Spacer()
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Project.self, FocusSession.self, AppSettings.self], inMemory: true)
}
