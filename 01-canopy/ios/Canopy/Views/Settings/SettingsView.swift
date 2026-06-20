import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var settingsQuery: [CanopySettings]
    @Environment(\.modelContext) private var modelContext

    @State private var showResetAlert = false
    @State private var showProAlert = false

    private var settings: CanopySettings {
        if let existing = settingsQuery.first { return existing }
        let s = CanopySettings()
        modelContext.insert(s)
        return s
    }

    private let appVersion: String = {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }()

    var body: some View {
        NavigationStack {
            Form {
                goalSection
                unitsSection
                proSection
                aboutSection
                dangerSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Unlock Pro", isPresented: $showProAlert) {
                Button("Unlock for $2.99") {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    settings.hasPro = true
                }
                Button("Restore Purchase") {
                    // Demo: no-op
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Canopy Pro includes full benchmark details, CSV export, and unlimited goal presets.\n\nThis is a demo — no real purchase will be made.")
            }
            .alert("Reset All Data", isPresented: $showResetAlert) {
                Button("Reset Everything", role: .destructive) {
                    resetAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all logged entries and reset your settings. This cannot be undone.")
            }
        }
    }

    // MARK: - Sections

    private var goalSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Weekly Goal")
                        .font(.body)
                    Spacer()
                    Text(String(format: "%.0f kg CO₂e", settings.weeklyGoalKg))
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.canopyGreen)
                }

                Slider(
                    value: Binding(
                        get: { settings.weeklyGoalKg },
                        set: { settings.weeklyGoalKg = ($0 / 5).rounded() * 5 }
                    ),
                    in: 10...500,
                    step: 5
                )
                .tint(.canopyGreen)
                .accessibilityLabel("Weekly goal slider")
                .accessibilityValue("\(Int(settings.weeklyGoalKg)) kilograms")

                HStack {
                    Text("10 kg")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("500 kg")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)

            HStack(spacing: 20) {
                presetGoalButton(label: "Paris", value: 96.2)
                presetGoalButton(label: "World avg", value: 192.3)
                presetGoalButton(label: "UK avg", value: 212.0)
            }
        } header: {
            Text("Weekly Carbon Goal")
        } footer: {
            Text("World average is \(String(format: "%.0f", EmissionsEngine.worldAverageWeeklyKg)) kg/wk. Paris-aligned target is \(String(format: "%.0f", EmissionsEngine.targetWeeklyKg)) kg/wk.")
        }
    }

    private func presetGoalButton(label: String, value: Double) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            settings.weeklyGoalKg = value
        } label: {
            VStack(spacing: 2) {
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                Text("\(Int(value)) kg")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                abs(settings.weeklyGoalKg - value) < 1
                    ? Color.canopyGreen.opacity(0.15)
                    : Color(.secondarySystemBackground),
                in: RoundedRectangle(cornerRadius: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        abs(settings.weeklyGoalKg - value) < 1 ? Color.canopyGreen : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .accessibilityLabel("Set goal to \(label): \(Int(value)) kilograms per week")
    }

    private var unitsSection: some View {
        Section("Units") {
            Picker("Unit System", selection: Binding(
                get: { settings.unitSystem },
                set: { settings.unitSystem = $0 }
            )) {
                Text("Metric (kg, km)").tag("metric")
                Text("Imperial (lbs, mi)").tag("imperial")
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Unit system selector")
        }
    }

    private var proSection: some View {
        Section("Canopy Pro") {
            if settings.hasPro {
                HStack {
                    Label("Pro Unlocked", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.canopyGreen)
                    Spacer()
                    Button("Restore") {
                        // Demo no-op
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            } else {
                Button {
                    showProAlert = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Unlock Pro — $2.99")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                            Text("Benchmark details, CSV export, unlimited goal presets")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityLabel("Unlock Canopy Pro for two dollars and ninety-nine cents")
                .accessibilityHint("One-time purchase for benchmark details, CSV export, and unlimited goals")
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text(appVersion)
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel("App version \(appVersion)")

            HStack {
                Text("Bundle ID")
                Spacer()
                Text("com.orbioom.canopy")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("About Canopy")
                    .font(.body)
                Text("Track your footprint. Lighten your impact. Canopy is a private, offline carbon footprint journal. All data stays on your device — no account required, no subscriptions.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)

            if let sourceURL = URL(string: "https://github.com/orbioom/canopy") {
                Link(destination: sourceURL) {
                    Label("Source & Methodology", systemImage: "link")
                        .font(.body)
                        .foregroundStyle(.canopyGreen)
                }
                .accessibilityLabel("View source code and methodology on GitHub")
            }
        }
    }

    private var dangerSection: some View {
        Section {
            Button(role: .destructive) {
                showResetAlert = true
            } label: {
                Label("Reset All Data", systemImage: "trash")
            }
            .accessibilityLabel("Reset all data")
            .accessibilityHint("Permanently deletes all entries and settings. Cannot be undone.")
        } header: {
            Text("Danger Zone")
        }
    }

    // MARK: - Actions

    private func resetAllData() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        do {
            try modelContext.delete(model: EmissionEntry.self)
            try modelContext.delete(model: CanopySettings.self)
        } catch {
            // Graceful no-op: data may already be clean
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [EmissionEntry.self, CanopySettings.self], inMemory: true)
}
