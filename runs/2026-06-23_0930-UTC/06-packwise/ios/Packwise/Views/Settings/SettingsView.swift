import SwiftUI
import SwiftData

/// Settings with real persisted preferences backed by SwiftData + AppStorage.
struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var allSettings: [AppSettings]
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var showingResetConfirm = false

    var body: some View {
        NavigationStack {
            content
        }
    }

    @ViewBuilder
    private var content: some View {
        // Resolve the settings record, observed via @Query so edits re-render.
        let settings = allSettings.first ?? DataController.settings(in: context)
        Group {
            Form {
                Section("Packing defaults") {
                    Picker("Packing style", selection: Binding(
                        get: { settings.packingStyle },
                        set: { settings.packingStyle = $0; save() }
                    )) {
                        ForEach(PackingStyle.allCases) { style in
                            Text(style.title).tag(style)
                        }
                    }
                    Text(settings.packingStyle.detail)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)

                    Stepper(value: Binding(
                        get: { settings.defaultTravelerCount },
                        set: { settings.defaultTravelerCount = max(1, $0); save() }
                    ), in: 1...12) {
                        Text("Default travelers: \(settings.defaultTravelerCount)")
                            .monospacedDigit()
                    }

                    Stepper(value: Binding(
                        get: { settings.reminderLeadDays },
                        set: { settings.reminderLeadDays = max(0, $0); save() }
                    ), in: 0...30) {
                        Text("Pack reminder: \(settings.reminderLeadDays) day\(settings.reminderLeadDays == 1 ? "" : "s") before")
                            .monospacedDigit()
                    }
                }

                Section("Preferences") {
                    Toggle("Haptic feedback", isOn: Binding(
                        get: { settings.hapticsEnabled },
                        set: { settings.hapticsEnabled = $0; save()
                               Haptics.selection(enabled: $0) }
                    ))
                    Picker("Units", selection: Binding(
                        get: { settings.measurementMetric },
                        set: { settings.measurementMetric = $0; save() }
                    )) {
                        Text("Metric").tag(true)
                        Text("Imperial").tag(false)
                    }
                    .pickerStyle(.segmented)
                }

                Section("How generation works") {
                    InfoRow(symbol: "moon.zzz.fill",
                            text: "Clothing scales with the number of nights and your packing style.")
                    InfoRow(symbol: "person.2.fill",
                            text: "Per-person items multiply by traveler count.")
                    InfoRow(symbol: "figure.run",
                            text: "Each activity adds its own gear, de-duplicated against the base list.")
                }

                Section("App") {
                    Button {
                        showingResetConfirm = true
                    } label: {
                        Label("Replay onboarding", systemImage: "arrow.counterclockwise")
                    }
                    LabeledContent("Version", value: "1.0")
                }

                Section {
                    Text("Packwise generates everything on-device. No account, no network, no ads.")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Settings")
            .confirmationDialog(
                "Replay onboarding?",
                isPresented: $showingResetConfirm,
                titleVisibility: .visible
            ) {
                Button("Replay") { hasCompletedOnboarding = false }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your trips and templates are kept.")
            }
        }
    }

    private func save() {
        try? context.save()
    }
}

private struct InfoRow: View {
    let symbol: String
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: Theme.Space.md) {
            Image(systemName: symbol)
                .foregroundStyle(Theme.primary)
                .frame(width: 24)
                .accessibilityHidden(true)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Theme.textPrimary)
        }
    }
}
