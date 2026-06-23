import SwiftUI
import SwiftData

/// Settings tab: real persisted preferences plus reminder scheduling and an
/// about section. All toggles write straight to the SwiftData `AppSettings` row.
struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var settingsRows: [AppSettings]
    @Query private var sessions: [BreathSession]

    @State private var showResetConfirm = false

    private var settings: AppSettings? { settingsRows.first }

    var body: some View {
        NavigationStack {
            Group {
                if let settings {
                    form(settings)
                } else {
                    LoadingView(message: "Loading settings…")
                }
            }
            .emberScreenBackground()
            .navigationTitle("Settings")
        }
    }

    private func form(_ settings: AppSettings) -> some View {
        Form {
            Section("Session") {
                Stepper(value: bind(settings, \.defaultSessionMinutes, clampedTo: 2...30), in: 2...30) {
                    HStack {
                        Label("Default length", systemImage: "timer")
                        Spacer()
                        Text("\(settings.defaultSessionMinutes) min").foregroundStyle(Theme.textSecondary)
                    }
                }
                Toggle(isOn: bind(settings, \.preparationCountdown)) {
                    Label("Count-in (3-2-1)", systemImage: "hourglass")
                }
                Toggle(isOn: bind(settings, \.keepScreenAwake)) {
                    Label("Keep screen awake", systemImage: "sun.max")
                }
            }

            Section("Feedback") {
                Toggle(isOn: Binding(
                    get: { settings.hapticsEnabled },
                    set: { newValue in
                        settings.hapticsEnabled = newValue
                        Haptics.shared.enabled = newValue
                        save()
                        if newValue { Haptics.shared.tap() }
                    })) {
                    Label("Haptic cues", systemImage: "iphone.radiowaves.left.and.right")
                }
                Toggle(isOn: bind(settings, \.voiceCuesText)) {
                    Label("Large text cues", systemImage: "textformat.size")
                }
            }

            Section {
                Toggle(isOn: Binding(
                    get: { settings.reminderEnabled },
                    set: { newValue in
                        settings.reminderEnabled = newValue
                        save()
                        ReminderScheduler.sync(enabled: newValue, minuteOfDay: settings.reminderMinuteOfDay)
                    })) {
                    Label("Daily reminder", systemImage: "bell")
                }
                if settings.reminderEnabled {
                    DatePicker("Reminder time",
                               selection: reminderBinding(settings),
                               displayedComponents: .hourAndMinute)
                }
            } header: {
                Text("Reminders")
            } footer: {
                Text("A gentle nudge to take a breathing break. You can change the time anytime.")
            }

            Section("Your Practice") {
                LabeledContent("Sessions completed", value: "\(sessions.count)")
                LabeledContent("Favorites", value: "\(settings.favoritePatternIDs.count)")
            }

            Section {
                Button(role: .destructive) {
                    showResetConfirm = true
                } label: {
                    Label("Reset all data", systemImage: "trash")
                }
            } header: {
                Text("Data")
            } footer: {
                Text("Removes every session and mood entry. Your preferences are kept.")
            }

            Section {
                aboutRow
            } header: {
                Text("About")
            } footer: {
                Text("Ember v1.0 · Crafted for calm. Works fully offline — your breathing data never leaves your device.")
            }
        }
        .scrollContentBackground(.hidden)
        .alert("Reset all data?", isPresented: $showResetConfirm) {
            Button("Reset", role: .destructive) { resetData() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes all sessions and mood logs. This cannot be undone.")
        }
    }

    private var aboutRow: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: "flame.fill")
                .font(.title2)
                .foregroundStyle(Theme.emberWarm)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Ember").font(.headline).foregroundStyle(Theme.textPrimary)
                Text("Guided breathwork & calm coach")
                    .font(.caption).foregroundStyle(Theme.textSecondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Bindings

    private func bind(_ settings: AppSettings, _ keyPath: ReferenceWritableKeyPath<AppSettings, Bool>) -> Binding<Bool> {
        Binding(
            get: { settings[keyPath: keyPath] },
            set: { settings[keyPath: keyPath] = $0; save() })
    }

    private func bind(_ settings: AppSettings, _ keyPath: ReferenceWritableKeyPath<AppSettings, Int>, clampedTo range: ClosedRange<Int>) -> Binding<Int> {
        Binding(
            get: { settings[keyPath: keyPath] },
            set: { settings[keyPath: keyPath] = min(range.upperBound, max(range.lowerBound, $0)); save() })
    }

    private func reminderBinding(_ settings: AppSettings) -> Binding<Date> {
        Binding(
            get: {
                let comps = DateComponents(hour: settings.reminderHour, minute: settings.reminderMinute)
                return Calendar.current.date(from: comps) ?? Date()
            },
            set: { newDate in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                settings.reminderMinuteOfDay = (comps.hour ?? 21) * 60 + (comps.minute ?? 0)
                save()
                if settings.reminderEnabled {
                    ReminderScheduler.sync(enabled: true, minuteOfDay: settings.reminderMinuteOfDay)
                }
            })
    }

    private func save() {
        try? context.save()
    }

    private func resetData() {
        Haptics.shared.warning()
        for session in sessions { context.delete(session) }
        let moods = (try? context.fetch(FetchDescriptor<MoodEntry>())) ?? []
        for mood in moods { context.delete(mood) }
        try? context.save()
    }
}

#Preview {
    SettingsView()
        .previewModelContainer()
}
