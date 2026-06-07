import SwiftUI
import SwiftData

/// Settings: persisted preferences, library counts, destructive erase, and About.
struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var systems: [PowerSystem]
    @Query private var loads: [Load]

    @AppStorage(PrefKey.haptics) private var hapticsEnabled = true
    @AppStorage(PrefKey.appearance) private var appearanceRaw = AppAppearance.system.rawValue
    @AppStorage(PrefKey.defaultChemistry) private var defaultChemistryRaw = Chemistry.lifepo4.rawValue
    @AppStorage(PrefKey.defaultSunHours) private var defaultSunHours = 4.5
    @AppStorage(PrefKey.hasOnboarded) private var hasOnboarded = true

    @State private var showEraseConfirm = false

    private var appearance: Binding<AppAppearance> {
        Binding(
            get: { AppAppearance(rawValue: appearanceRaw) ?? .system },
            set: { appearanceRaw = $0.rawValue }
        )
    }

    private var defaultChemistry: Binding<Chemistry> {
        Binding(
            get: { Chemistry(rawValue: defaultChemistryRaw) ?? .lifepo4 },
            set: { defaultChemistryRaw = $0.rawValue }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                preferencesSection
                defaultsSection
                librarySection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle("Settings")
            .confirmationDialog(
                "Erase all data?",
                isPresented: $showEraseConfirm,
                titleVisibility: .visible
            ) {
                Button("Erase everything", role: .destructive) { eraseAll() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This permanently deletes every system and load, and replays onboarding. This can't be undone.")
            }
        }
    }

    // MARK: - Sections

    private var preferencesSection: some View {
        Section("Preferences") {
            Toggle(isOn: $hapticsEnabled) {
                Label("Haptics", systemImage: "hand.tap")
            }
            .onChange(of: hapticsEnabled) { _, newValue in
                Haptics.enabled = newValue
                if newValue { Haptics.tap() }
            }

            Picker(selection: appearance) {
                ForEach(AppAppearance.allCases) { Text($0.label).tag($0) }
            } label: {
                Label("Appearance", systemImage: "circle.lefthalf.filled")
            }
        }
    }

    private var defaultsSection: some View {
        Section {
            Picker(selection: defaultChemistry) {
                ForEach(Chemistry.allCases) { Text($0.label).tag($0) }
            } label: {
                Label("Default chemistry", systemImage: "bolt.batteryblock")
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label("Default peak sun", systemImage: "sun.max")
                    Spacer()
                    Text("\(Fmt.dec1(defaultSunHours)) h")
                        .font(Brand.mono(14, weight: .medium))
                        .foregroundStyle(Brand.text)
                }
                Slider(value: $defaultSunHours, in: 1...8, step: 0.5)
            }
        } header: {
            Text("New system defaults")
        } footer: {
            Text("Applied when you create a new system or open the sizing calculator.")
        }
    }

    private var librarySection: some View {
        Section("Library") {
            InfoRow(label: "Systems", value: "\(systems.count)", mono: true)
            InfoRow(label: "Loads", value: "\(loads.count)", mono: true)
            InfoRow(label: "Catalog appliances", value: "\(ApplianceCatalog.all.count)", mono: true)
        }
    }

    private var dataSection: some View {
        Section("Data") {
            Button(role: .destructive) {
                Haptics.warning()
                showEraseConfirm = true
            } label: {
                Label("Erase all data", systemImage: "trash")
            }
        }
    }

    private var aboutSection: some View {
        Section {
            InfoRow(label: "App", value: "Reserve")
            InfoRow(label: "Version", value: "1.0", mono: true)
            InfoRow(label: "Studio", value: "Orbioom")
            Text("An on-device off-grid power budget planner for vanlife, RVs, boats and cabins. Conjured, not just coded.")
                .font(.caption)
                .foregroundStyle(Brand.text3)
        } header: {
            Text("About")
        }
    }

    // MARK: - Actions

    private func eraseAll() {
        for system in systems { context.delete(system) }
        for load in loads { context.delete(load) }
        try? context.save()
        hasOnboarded = false
        Haptics.success()
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [PowerSystem.self, Load.self], inMemory: true)
}
