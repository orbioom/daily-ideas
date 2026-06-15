import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("isPro") private var isPro = false

    @State private var paywallReason: PaywallReason?
    @State private var showResetConfirm = false
    @State private var historyCleared = false

    var body: some View {
        NavigationStack {
            Form {
                appearanceSection
                breakSection
                remindersSection
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

    private var breakSection: some View {
        Section("Break rhythm") {
            Stepper(value: Binding(
                get: { settings.breakIntervalMinutes },
                set: { settings.breakIntervalMinutes = min(120, max(5, $0)) }
            ), in: 5...120, step: 5) {
                HStack {
                    Text("Break every")
                    Spacer()
                    Text("\(settings.breakIntervalMinutes) min").foregroundStyle(Theme.inkSoft)
                }
            }
            .accessibilityValue("\(settings.breakIntervalMinutes) minutes")

            Stepper(value: Binding(
                get: { settings.dailyBreakGoal },
                set: { settings.dailyBreakGoal = min(40, max(1, $0)) }
            ), in: 1...40) {
                HStack {
                    Text("Daily break goal")
                    Spacer()
                    Text("\(settings.dailyBreakGoal)").foregroundStyle(Theme.inkSoft)
                }
            }
            .accessibilityValue("\(settings.dailyBreakGoal) breaks")
        }
    }

    private var remindersSection: some View {
        Section("On Today") {
            Toggle("Nudge when a break is due", isOn: $settings.breakReminderEnabled)
            Toggle("Suggest a daily routine", isOn: $settings.exerciseReminderEnabled)
            Text("Reminders appear on the Today screen while the app is open. Iris never sends background notifications or uses the network.")
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkFaint)
        }
    }

    private var preferencesSection: some View {
        Section("Feedback") {
            Toggle("Haptic feedback", isOn: $settings.hapticsEnabled)
        }
    }

    private var proSection: some View {
        Section("Iris Pro") {
            if isPro {
                Label("Pro unlocked", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(Theme.good)
            } else {
                Button {
                    paywallReason = .general
                } label: {
                    Label("Unlock Iris Pro (\(Pro.priceLabel))", systemImage: "eye.fill")
                }
            }
        }
    }

    private var dataSection: some View {
        Section("History") {
            Button {
                showResetConfirm = true
            } label: {
                Label("Clear all activity history", systemImage: "trash")
                    .foregroundStyle(Theme.bad)
            }
            if historyCleared {
                Text("History cleared.").font(Theme.rounded(12)).foregroundStyle(Theme.inkFaint)
            }
        }
        .confirmationDialog("Clear all activity history?", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("Clear history", role: .destructive) {
                SeedData.clearAll(context: modelContext)
                historyCleared = true
                Haptics.tap(enabled: settings.hapticsEnabled)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently removes every logged break and exercise session on this device. Settings are not affected.")
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack { Text("Version"); Spacer(); Text("1.0").foregroundStyle(Theme.inkSoft) }
            Text("Iris supports healthy screen habits and is not a medical eye exam. If you have pain, sudden vision changes, or other concerns, see an optometrist or physician. Your data stays private on your device — no account, no network, no tracking.")
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkFaint)
        }
    }
}
