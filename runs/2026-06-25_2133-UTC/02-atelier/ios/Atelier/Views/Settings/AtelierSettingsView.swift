import SwiftUI
import SwiftData

struct AtelierSettingsView: View {
    @Query private var allSettings: [AtelierSettings]
    @Query private var goals: [StudyGoal]
    @Environment(\.modelContext) private var context
    @State private var showingClearConfirm = false

    private var settings: AtelierSettings? { allSettings.first }
    private var activeGoal: StudyGoal? { goals.first(where: { $0.isActive }) }

    var body: some View {
        NavigationStack {
            Form {
                weeklyGoalSection
                defaultsSection
                behaviourSection
                dataSection
                aboutSection
            }
            .navigationTitle("Settings")
        }
    }

    private var weeklyGoalSection: some View {
        Section("Weekly Goal") {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Target minutes / week")
                    Spacer()
                    Text("\(settings?.weeklyGoalMinutes ?? 300) min")
                        .foregroundStyle(.secondary)
                }
                Slider(
                    value: Binding(
                        get: { Double(settings?.weeklyGoalMinutes ?? 300) },
                        set: { v in
                            settings?.weeklyGoalMinutes = Int(v)
                            activeGoal?.targetMinutesPerWeek = Int(v)
                            save()
                        }
                    ),
                    in: 30...840, step: 30
                )
                .tint(AtelierTheme.amber)
                .accessibilityLabel("Weekly practice goal: \(settings?.weeklyGoalMinutes ?? 300) minutes")
            }
        }
    }

    private var defaultsSection: some View {
        Section("Defaults") {
            Picker("Default medium", selection: Binding(
                get: { settings?.defaultMedium ?? .pencil },
                set: { v in settings?.defaultMedium = v; save() }
            )) {
                ForEach(ArtMedium.allCases) { m in Text(m.rawValue).tag(m) }
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Default duration")
                    Spacer()
                    Text(formatDuration(settings?.defaultDurationMinutes ?? 60))
                        .foregroundStyle(.secondary)
                }
                Slider(value: Binding(
                    get: { Double(settings?.defaultDurationMinutes ?? 60) },
                    set: { v in settings?.defaultDurationMinutes = Int(v); save() }
                ), in: 15...180, step: 15)
                .tint(AtelierTheme.amber)
            }
        }
    }

    private var behaviourSection: some View {
        Section("Behaviour") {
            Toggle("Haptic feedback", isOn: Binding(
                get: { settings?.hapticsEnabled ?? true },
                set: { v in settings?.hapticsEnabled = v; save() }
            ))
        }
    }

    private var dataSection: some View {
        Section("Data") {
            Button("Reset onboarding") {
                settings?.showOnboarding = true; save()
            }
            .foregroundStyle(AtelierTheme.amber)

            Button("Clear all sessions", role: .destructive) {
                showingClearConfirm = true
            }
            .confirmationDialog("Clear all sessions?", isPresented: $showingClearConfirm, titleVisibility: .visible) {
                Button("Clear", role: .destructive) {
                    try? context.delete(model: ArtSession.self)
                    try? context.save()
                }
                Button("Cancel", role: .cancel) {}
            } message: { Text("This will permanently delete all practice sessions.") }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack { Text("Version"); Spacer(); Text("1.0").foregroundStyle(.secondary) }
            HStack { Text("Privacy"); Spacer(); Text("On-device only").foregroundStyle(.secondary) }
        }
    }

    private func formatDuration(_ m: Int) -> String {
        let h = m / 60; let mn = m % 60
        if h > 0 && mn > 0 { return "\(h)h \(mn)m" }
        if h > 0 { return "\(h)h" }
        return "\(mn)m"
    }

    private func save() { try? context.save() }
}
