import SwiftUI
import SwiftData

/// Persisted preferences, each of which changes real behavior, plus a sample-data reset.
struct SettingsView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Query private var routines: [Routine]
    @Query private var sessions: [Session]

    @State private var showResetConfirm = false
    @State private var showClearConfirm = false

    var body: some View {
        @Bindable var settings = settings
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    runSection(settings: settings)
                    feedbackSection(settings: settings)
                    appearanceSection(settings: settings)
                    dataSection
                    aboutSection
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
        }
        .alert("Reset sample routines?", isPresented: $showResetConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) { resetSamples() }
        } message: {
            Text("Re-inserts the starter routines. Your own routines and run history are kept.")
        }
        .alert("Delete everything?", isPresented: $showClearConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete all", role: .destructive) { clearAll() }
        } message: {
            Text("Removes every routine and all run history. This can't be undone.")
        }
    }

    // MARK: - Sections

    private func runSection(settings: SettingsStore) -> some View {
        Section {
            Stepper(value: Binding(
                get: { settings.countInSeconds },
                set: { settings.countInSeconds = $0 }
            ), in: 0...10) {
                HStack {
                    Label("Count-in", systemImage: "timer")
                    Spacer()
                    Text(settings.countInSeconds == 0 ? "Off" : "\(settings.countInSeconds)s")
                        .font(Brand.mono(15, weight: .medium))
                        .foregroundStyle(Brand.text2)
                }
            }
            .accessibilityValue(settings.countInSeconds == 0 ? "Off"
                                                             : "\(settings.countInSeconds) seconds")

            Toggle(isOn: Binding(get: { settings.keepAwake },
                                 set: { settings.keepAwake = $0 })) {
                Label("Keep screen awake", systemImage: "sun.max")
            }
            .tint(Brand.live)
        } header: {
            Text("Running")
        } footer: {
            Text("The count-in is a lead-in countdown before the first segment. Keep-awake stops the screen dimming during a run.")
        }
    }

    private func feedbackSection(settings: SettingsStore) -> some View {
        Section {
            Toggle(isOn: Binding(get: { settings.hapticsEnabled },
                                 set: { settings.hapticsEnabled = $0 })) {
                Label("Haptics", systemImage: "iphone.radiowaves.left.and.right")
            }
            .tint(Brand.live)

            Toggle(isOn: Binding(get: { settings.soundEnabled },
                                 set: { settings.soundEnabled = $0 })) {
                Label("Sound cues", systemImage: "speaker.wave.2")
            }
            .tint(Brand.live)
        } header: {
            Text("Feedback")
        } footer: {
            Text("Cues fire at segment transitions and during the final lead-in. Sound uses built-in system tones and respects the silent switch.")
        }
    }

    private func appearanceSection(settings: SettingsStore) -> some View {
        Section("Appearance") {
            Picker(selection: Binding(get: { settings.appearance },
                                      set: { settings.appearance = $0 })) {
                ForEach(SettingsStore.Appearance.allCases) { option in
                    Text(option.title).tag(option)
                }
            } label: {
                Label("Theme", systemImage: "circle.lefthalf.filled")
            }
            .pickerStyle(.segmented)
        }
    }

    private var dataSection: some View {
        Section {
            HStack {
                Label("Routines", systemImage: "list.bullet.rectangle.portrait")
                Spacer()
                Text("\(routines.count)").foregroundStyle(Brand.text2).monospacedDigit()
            }
            HStack {
                Label("Logged runs", systemImage: "chart.bar")
                Spacer()
                Text("\(sessions.count)").foregroundStyle(Brand.text2).monospacedDigit()
            }
            Button {
                showResetConfirm = true
            } label: {
                Label("Reset sample routines", systemImage: "arrow.counterclockwise")
                    .foregroundStyle(Brand.text)
            }
            Button(role: .destructive) {
                showClearConfirm = true
            } label: {
                Label("Delete all data", systemImage: "trash")
            }
        } header: {
            Text("Data")
        } footer: {
            Text("Routines, segments, and runs are stored on device with SwiftData.")
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Interval")
                Spacer()
                Text("1.0").foregroundStyle(Brand.text3)
            }
            Text("An interval-timer builder by Orbioom. Build a routine once, run it hands-free.")
                .font(.caption)
                .foregroundStyle(Brand.text3)
        }
    }

    // MARK: - Actions

    private func resetSamples() {
        SampleData.insert(into: context)
        settings.hasSeeded = true
        Haptics.success(enabled: settings.hapticsEnabled)
    }

    private func clearAll() {
        for routine in routines { context.delete(routine) }
        for session in sessions where session.routine == nil {
            context.delete(session)
        }
        try? context.save()
        settings.clearSeedFlag()
        Haptics.warning(enabled: settings.hapticsEnabled)
    }
}

#Preview {
    SettingsView().intervalPreview()
}
