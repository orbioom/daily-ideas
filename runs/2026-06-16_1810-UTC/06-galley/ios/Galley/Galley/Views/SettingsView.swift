import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var context

    @AppStorage(PrefKey.isPro) private var isPro: Bool = false
    @AppStorage(PrefKey.hapticsEnabled) private var hapticsEnabled: Bool = true
    @AppStorage(PrefKey.useFractions) private var useFractions: Bool = true
    @AppStorage(PrefKey.measurementSystem) private var measurementSystemRaw: String = MeasurementSystem.us.rawValue
    @AppStorage(PrefKey.temperatureUnit) private var temperatureUnitRaw: String = TemperatureUnit.fahrenheit.rawValue

    @State private var showingPaywall = false
    @State private var showingResetConfirm = false
    @State private var showingProResetConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Preferences
                Section("Measurement") {
                    Picker("Default system", selection: $measurementSystemRaw) {
                        ForEach(MeasurementSystem.allCases) { Text($0.rawValue).tag($0.rawValue) }
                    }
                    .accessibilityHint("Sets the default units used across Galley")

                    Picker("Temperature unit", selection: $temperatureUnitRaw) {
                        ForEach(TemperatureUnit.allCases) { Text($0.rawValue).tag($0.rawValue) }
                    }
                }

                Section("Display") {
                    Toggle("Show cooking fractions", isOn: $useFractions)
                        .tint(GalleyTheme.terracotta)
                        .accessibilityHint("When on, results like 1.5 show as 1 and a half")
                    Toggle("Haptics", isOn: $hapticsEnabled)
                        .tint(GalleyTheme.terracotta)
                        .accessibilityHint("Subtle vibration on timer completion and key actions")
                }

                // MARK: Pro
                Section("Galley Pro") {
                    if isPro {
                        Label("Pro unlocked", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(GalleyTheme.sageDeep)
                        Button("Restore to free (demo)", role: .destructive) {
                            showingProResetConfirm = true
                        }
                    } else {
                        Button {
                            showingPaywall = true
                        } label: {
                            HStack {
                                Label("Unlock Galley Pro", systemImage: "lock.open")
                                Spacer()
                                Text("$2.99").foregroundStyle(GalleyTheme.secondaryText(scheme))
                            }
                        }
                    }
                }

                // MARK: About
                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Made by", value: "Orbioom")
                    Text("Galley is your warm, all-in-one kitchen toolkit: density-aware conversions, recipe scaling, substitutions and many timers at once.")
                        .font(.footnote)
                        .foregroundStyle(GalleyTheme.secondaryText(scheme))
                }

                // MARK: Reset
                Section {
                    Button("Reset all data", role: .destructive) {
                        showingResetConfirm = true
                    }
                } footer: {
                    Text("Removes your saved recipes, custom substitutions and timers, then restores the bundled samples.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingPaywall) { PaywallView() }
            .alert("Reset all data?", isPresented: $showingResetConfirm) {
                Button("Reset", role: .destructive) { resetAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This clears your recipes, custom substitutions and timers, then re-seeds the samples.")
            }
            .alert("Return to free?", isPresented: $showingProResetConfirm) {
                Button("Return to free", role: .destructive) { isPro = false }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This demo toggle removes Pro so you can see the free limits again.")
            }
        }
    }

    private func resetAll() {
        // Delete user records, then re-seed.
        do {
            try context.delete(model: KitchenTimer.self)
            try context.delete(model: RecipeIngredient.self)
            try context.delete(model: SavedRecipe.self)
            try context.delete(model: SubstituteOption.self)
            try context.delete(model: SubstitutionEntry.self)
            try context.save()
        } catch {
            // Non-fatal: if a bulk delete fails we simply leave existing data.
        }
        SeedData.seedIfNeeded(context)
        Haptics.warning()
    }
}
