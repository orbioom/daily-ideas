import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var affirmations: [Affirmation]

    @AppStorage("haptics") private var haptics = true
    @AppStorage("appearance") private var appearance = "system"
    @AppStorage("enabledThemes") private var enabledThemesRaw = ""
    @AppStorage("reminderOn") private var reminderOn = false
    @AppStorage("reminderHour") private var reminderHour = 8
    @AppStorage("reminderMinute") private var reminderMinute = 0

    @State private var reminderTime = Date()
    @State private var showResetConfirm = false
    @State private var permissionDenied = false

    private var enabledThemes: Set<String> {
        let s = enabledThemesRaw.split(separator: ",").map(String.init)
        return s.isEmpty ? Set(AffirmationTheme.allCases.map(\.rawValue)) : Set(s)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section("Daily Reminder") {
                        Toggle("Remind me daily", isOn: $reminderOn)
                            .tint(Brand.live)
                            .onChange(of: reminderOn) { _, on in handleReminderToggle(on) }
                        if reminderOn {
                            DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                                .onChange(of: reminderTime) { _, _ in updateReminder() }
                        }
                        if permissionDenied {
                            Text("Notifications are turned off for Lumina. Enable them in the Settings app to receive reminders.")
                                .font(.caption)
                                .foregroundStyle(Brand.warn)
                        }
                    }

                    Section {
                        ForEach(AffirmationTheme.allCases) { t in
                            Toggle(isOn: bindingFor(t)) {
                                Label(t.title, systemImage: t.icon)
                            }
                            .tint(t.tint)
                        }
                    } header: {
                        Text("Themes on Today")
                    } footer: {
                        Text("Choose which themes appear in your daily deck. At least one stays on.")
                    }

                    Section("Appearance") {
                        Picker("Theme", selection: $appearance) {
                            Text("System").tag("system")
                            Text("Light").tag("light")
                            Text("Dark").tag("dark")
                        }
                        .pickerStyle(.segmented)
                    }

                    Section("Feedback") {
                        Toggle("Haptics", isOn: $haptics)
                            .tint(Brand.live)
                            .onChange(of: haptics) { _, v in Haptics.enabled = v }
                    }

                    Section {
                        Button(role: .destructive) {
                            showResetConfirm = true
                        } label: {
                            Label("Delete my custom affirmations", systemImage: "trash")
                        }
                    } footer: {
                        Text("Built-in affirmations stay. \(affirmations.filter { $0.isCustom }.count) of your own are stored.")
                    }

                    Section {
                        LabeledContent("Affirmations", value: "\(affirmations.count)")
                        LabeledContent("Privacy", value: "On device only")
                        LabeledContent("Version", value: "1.0")
                    } header: {
                        Text("About")
                    } footer: {
                        Text("Lumina keeps everything on this device. No account, no ads, no tracking.")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .preferredColorScheme(resolvedScheme)
            .onAppear(perform: loadReminderTime)
            .confirmationDialog("Delete all custom affirmations?",
                                isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Delete", role: .destructive) { deleteCustom() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This cannot be undone. Your favorites among built-in affirmations are kept.")
            }
        }
    }

    private var resolvedScheme: ColorScheme? {
        switch appearance { case "light": .light; case "dark": .dark; default: nil }
    }

    private func bindingFor(_ t: AffirmationTheme) -> Binding<Bool> {
        Binding(
            get: { enabledThemes.contains(t.rawValue) },
            set: { isOn in
                var set = enabledThemes
                if isOn { set.insert(t.rawValue) }
                else if set.count > 1 { set.remove(t.rawValue) }
                enabledThemesRaw = set.sorted().joined(separator: ",")
                Haptics.selection()
            }
        )
    }

    private func loadReminderTime() {
        var comps = DateComponents()
        comps.hour = reminderHour; comps.minute = reminderMinute
        reminderTime = Calendar.current.date(from: comps) ?? .now
    }

    private func handleReminderToggle(_ on: Bool) {
        if on {
            Task {
                let granted = await Reminders.requestAuthorization()
                await MainActor.run {
                    if granted { permissionDenied = false; updateReminder() }
                    else { permissionDenied = true; reminderOn = false }
                }
            }
        } else {
            Reminders.cancel()
            permissionDenied = false
        }
    }

    private func updateReminder() {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        reminderHour = comps.hour ?? 8
        reminderMinute = comps.minute ?? 0
        guard reminderOn else { return }
        Task {
            await Reminders.schedule(hour: reminderHour, minute: reminderMinute,
                                     message: "A quiet moment for yourself. Open Lumina.")
        }
    }

    private func deleteCustom() {
        for a in affirmations where a.isCustom { context.delete(a) }
        try? context.save()
        Haptics.warning()
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Affirmation.self, DayLog.self], inMemory: true)
}
