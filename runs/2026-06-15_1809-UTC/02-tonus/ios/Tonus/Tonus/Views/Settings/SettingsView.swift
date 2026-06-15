import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \TrainingProgram.sortIndex) private var programs: [TrainingProgram]

    @State private var paywallReason: PaywallReason?

    var body: some View {
        NavigationStack {
            Form {
                appearanceSection
                trainingSection
                remindersSection
                proSection
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
            Toggle("Haptic feedback", isOn: $settings.hapticsEnabled)
            Toggle("Audio cues during sessions", isOn: $settings.audioCuesEnabled)
        }
    }

    private var trainingSection: some View {
        Section {
            Stepper(value: $settings.weeklyGoal, in: 1...14) {
                HStack {
                    Text("Weekly goal")
                    Spacer()
                    Text("\(settings.weeklyGoal) sessions")
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            .accessibilityValue("\(settings.weeklyGoal) sessions per week")

            Picker("Default program", selection: $settings.defaultProgramName) {
                ForEach(programNames, id: \.self) { name in
                    Text(name).tag(name)
                }
            }
        } header: {
            Text("Training")
        } footer: {
            Text("Your default program is the one Tonus suggests first on Today.")
        }
    }

    private var remindersSection: some View {
        Section {
            Toggle("Daily reminder", isOn: Binding(
                get: { settings.reminderEnabled },
                set: { newValue in
                    if newValue && !isPro {
                        paywallReason = .reminders
                    } else {
                        settings.reminderEnabled = newValue
                    }
                }
            ))
            if settings.reminderEnabled {
                DatePicker("Reminder time",
                           selection: Binding(
                            get: { settings.reminderTime },
                            set: { settings.reminderTime = $0 }
                           ),
                           displayedComponents: .hourAndMinute)
            }
            if !isPro {
                Label("Reminders are a Tonus Pro feature.", systemImage: "lock.fill")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkFaint)
            }
        } header: {
            Text("Reminders")
        } footer: {
            Text("A gentle nudge to keep your streak going. (Scheduling notifications wires in for production.)")
        }
    }

    private var proSection: some View {
        Section("Tonus Pro") {
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
                    Label("Unlock Tonus Pro (\(Pro.priceLabel))", systemImage: "circle.circle.fill")
                }
            }
        }
    }

    private var aboutSection: some View {
        Section {
            HStack { Text("Version"); Spacer(); Text("1.0").foregroundStyle(Theme.inkSoft) }
            Text("Not medical advice. Tonus offers general guided exercises and is not a substitute for professional care. Consult a qualified professional for pelvic-floor concerns.")
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkFaint)
            Text("Your data stays private on your device — no account, no network, no tracking.")
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkFaint)
        } header: {
            Text("About")
        }
    }

    private var programNames: [String] {
        let names = programs.map { $0.name }
        if names.contains(settings.defaultProgramName) {
            return names
        }
        // Ensure the stored default is always selectable even if programs haven't loaded yet.
        return ([settings.defaultProgramName] + names).reduced()
    }
}

private extension Array where Element == String {
    /// Stable de-duplication preserving first occurrence.
    func reduced() -> [String] {
        var seen = Set<String>()
        var out: [String] = []
        for s in self where !seen.contains(s) {
            seen.insert(s); out.append(s)
        }
        return out
    }
}
