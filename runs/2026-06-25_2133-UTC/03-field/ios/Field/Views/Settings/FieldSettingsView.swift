import SwiftUI
import SwiftData

struct FieldSettingsView: View {
    @Query private var allSettings: [FieldSettings]
    @Environment(\.modelContext) private var context
    @State private var showingClearConfirm = false

    private var settings: FieldSettings? { allSettings.first }

    var body: some View {
        NavigationStack {
            Form {
                displaySection
                behaviourSection
                dataSection
                aboutSection
            }
            .navigationTitle("Settings")
        }
    }

    private var displaySection: some View {
        Section("Display") {
            Toggle("Metric distance (km)", isOn: Binding(
                get: { settings?.useMetricDistance ?? true },
                set: { v in settings?.useMetricDistance = v; save() }
            ))
            Picker("Default habitat", selection: Binding(
                get: { settings?.defaultHabitat ?? .forest },
                set: { v in settings?.defaultHabitat = v; save() }
            )) {
                ForEach(HabitatType.allCases) { h in Text(h.rawValue).tag(h) }
            }
        }
    }

    private var behaviourSection: some View {
        Section("Behaviour") {
            Toggle("Haptic feedback", isOn: Binding(
                get: { settings?.hapticsEnabled ?? true },
                set: { v in settings?.hapticsEnabled = v; save() }
            ))
            Toggle("Lifer celebration haptic", isOn: Binding(
                get: { settings?.liferAlerts ?? true },
                set: { v in settings?.liferAlerts = v; save() }
            ))
            .accessibilityHint("Extra haptic feedback when a new lifer is logged")
        }
    }

    private var dataSection: some View {
        Section("Data") {
            Button("Reset onboarding") {
                settings?.showOnboarding = true; save()
            }
            .foregroundStyle(FieldTheme.fern)

            Button("Clear all observations", role: .destructive) {
                showingClearConfirm = true
            }
            .confirmationDialog("Clear all observations?", isPresented: $showingClearConfirm, titleVisibility: .visible) {
                Button("Clear", role: .destructive) {
                    try? context.delete(model: Observation.self)
                    try? context.save()
                }
                Button("Cancel", role: .cancel) {}
            } message: { Text("This will permanently delete all observations.") }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack { Text("Version"); Spacer(); Text("1.0").foregroundStyle(.secondary) }
            HStack { Text("Privacy"); Spacer(); Text("On-device only").foregroundStyle(.secondary) }
            HStack { Text("Account"); Spacer(); Text("None required").foregroundStyle(.secondary) }
        }
    }

    private func save() { try? context.save() }
}
