import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var allSettings: [SurfSettings]
    @Environment(\.modelContext) private var context
    @State private var showingClearConfirm = false

    private var settings: SurfSettings? { allSettings.first }

    var body: some View {
        NavigationStack {
            Form {
                unitsSection
                behaviourSection
                dataSection
                aboutSection
            }
            .navigationTitle("Settings")
        }
    }

    private var unitsSection: some View {
        Section("Units") {
            Toggle("Metric wave height (m)", isOn: Binding(
                get: { settings?.useMetricHeight ?? false },
                set: { v in settings?.useMetricHeight = v; save() }
            ))
            Toggle("Metric wind speed (km/h)", isOn: Binding(
                get: { settings?.useMetricWind ?? false },
                set: { v in settings?.useMetricWind = v; save() }
            ))
        }
    }

    private var behaviourSection: some View {
        Section("Behaviour") {
            Toggle("Haptic feedback", isOn: Binding(
                get: { settings?.hapticsEnabled ?? true },
                set: { v in settings?.hapticsEnabled = v; save() }
            ))
            .accessibilityHint("Provides tactile feedback on actions")

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Default duration")
                    Spacer()
                    Text(formatDuration(settings?.defaultDurationMinutes ?? 90))
                        .foregroundStyle(.secondary)
                }
                Slider(
                    value: Binding(
                        get: { Double(settings?.defaultDurationMinutes ?? 90) },
                        set: { v in settings?.defaultDurationMinutes = Int(v); save() }
                    ),
                    in: 15...360, step: 15
                )
                .tint(SwellTheme.teal)
                .accessibilityLabel("Default session duration: \(formatDuration(settings?.defaultDurationMinutes ?? 90))")
            }
        }
    }

    private var dataSection: some View {
        Section("Data") {
            Button("Reset onboarding") {
                settings?.showOnboarding = true
                save()
            }
            .foregroundStyle(SwellTheme.teal)

            Button("Clear all sessions", role: .destructive) {
                showingClearConfirm = true
            }
            .confirmationDialog("Clear all sessions?", isPresented: $showingClearConfirm, titleVisibility: .visible) {
                Button("Clear", role: .destructive) { clearAllSessions() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will delete all your logged sessions. This cannot be undone.")
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("Storage")
                Spacer()
                Text("On-device only")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("Privacy")
                Spacer()
                Text("No account, no cloud")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func formatDuration(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }

    private func save() {
        try? context.save()
    }

    private func clearAllSessions() {
        do {
            try context.delete(model: SurfSession.self)
            try context.save()
        } catch {
            // Session deletion errors are non-critical
        }
    }
}
