import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("isPro") private var isPro = false

    @State private var paywallReason: PaywallReason?
    @State private var showResetConfirm = false
    @State private var dataCleared = false

    var body: some View {
        NavigationStack {
            Form {
                appearanceSection
                trackingSection
                preferencesSection
                proSection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: Binding(
                get: { settings.appearance },
                set: { settings.appearance = $0 }
            )) {
                ForEach(AppearanceMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var trackingSection: some View {
        Section("Tracking") {
            Toggle("Track cycle & flow", isOn: $settings.trackCycle)
            DatePicker("Daily reminder",
                       selection: Binding(get: { settings.reminderTime },
                                          set: { settings.reminderTime = $0 }),
                       displayedComponents: .hourAndMinute)
            Text("We don't schedule a notification in this build — your chosen time is saved for when reminders are enabled.")
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkFaint)
            Picker("Temperature unit", selection: Binding(
                get: { settings.temperatureUnit },
                set: { settings.temperatureUnit = $0 }
            )) {
                ForEach(TemperatureUnit.allCases) { unit in
                    Text(unit.label).tag(unit)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var preferencesSection: some View {
        Section("Preferences") {
            Toggle("Haptic feedback", isOn: $settings.hapticsEnabled)
            Toggle("Show full symptom list on Today", isOn: $settings.defaultSymptomsShown)
            Text(settings.defaultSymptomsShown
                 ? "Today shows every symptom domain expanded."
                 : "Today shows a compact common set; tap to reveal the rest.")
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkFaint)
        }
    }

    private var proSection: some View {
        Section("Equinox Pro") {
            if isPro {
                HStack {
                    Label("Pro unlocked", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(Theme.good)
                    Spacer()
                }
            } else {
                Button {
                    paywallReason = .general
                } label: {
                    Label("Unlock Equinox Pro (\(Pro.priceLabel))", systemImage: "leaf.fill")
                }
            }
        }
    }

    private var dataSection: some View {
        Section("Your data") {
            Button {
                showResetConfirm = true
            } label: {
                Label("Delete all logs", systemImage: "trash")
                    .foregroundStyle(Theme.bad)
            }
            if dataCleared {
                Text("All logs deleted.").font(Theme.rounded(12)).foregroundStyle(Theme.inkFaint)
            }
        }
        .confirmationDialog("Delete all your logs?", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("Delete everything", role: .destructive) {
                deleteAllLogs()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently removes every day you've logged on this device. This can't be undone.")
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack { Text("Version"); Spacer(); Text("1.0").foregroundStyle(Theme.inkSoft) }
            Text("Not medical advice. Equinox helps you notice patterns and prepare for appointments — it doesn't diagnose or treat. Always talk to your clinician about your care.")
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkFaint)
            Text("Your data never leaves this device. No account, no network, no tracking.")
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkFaint)
        }
    }

    private func deleteAllLogs() {
        let logs = DayLogStore.allLogs(context: modelContext)
        for log in logs { modelContext.delete(log) }
        DayLogStore.save(modelContext)
        dataCleared = true
        Haptics.tap(enabled: settings.hapticsEnabled)
    }
}
