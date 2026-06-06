import SwiftUI
import SwiftData

/// Real, persisted preferences. Every control here changes behavior and survives relaunch.
struct SettingsView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Query private var formulas: [Formula]
    @Query private var bakes: [Bake]
    @Query private var starters: [Starter]

    @State private var showingResetConfirm = false
    @State private var showingClearConfirm = false
    @State private var toast: String?

    private var ingredientCount: Int { formulas.reduce(0) { $0 + $1.ingredients.count } }
    private var feedingCount: Int { starters.reduce(0) { $0 + $1.feedings.count } }

    var body: some View {
        @Bindable var settings = settings

        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Theme", selection: $settings.appearance) {
                        ForEach(SettingsStore.Appearance.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Picker("Weight units", selection: $settings.massUnit) {
                        ForEach(Units.Mass.allCases) { unit in
                            Text(unit.title).tag(unit)
                        }
                    }
                    Picker("Temperature", selection: $settings.temperatureUnit) {
                        ForEach(Units.Temperature.allCases) { unit in
                            Text(unit.title).tag(unit)
                        }
                    }
                } header: {
                    Text("Units")
                } footer: {
                    Text("Weights and temperatures are converted live across every screen.")
                }

                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Default dough weight")
                            Spacer()
                            Text(Units.massWithSuffix(settings.defaultDoughGrams, unit: settings.massUnit))
                                .font(Brand.mono(15))
                                .foregroundStyle(Brand.text2)
                                .monospacedDigit()
                        }
                        Slider(value: $settings.defaultDoughGrams, in: 300...3000, step: 50)
                            .tint(Brand.text)
                            .accessibilityLabel("Default dough weight")
                            .accessibilityValue(Units.massWithSuffix(settings.defaultDoughGrams, unit: settings.massUnit))
                    }
                    Picker("Default scheduling", selection: $settings.schedulesFromFinish) {
                        Text("From start").tag(false)
                        Text("To finish").tag(true)
                    }
                    Toggle("Haptic feedback", isOn: $settings.hapticsEnabled)
                } header: {
                    Text("Baking defaults")
                } footer: {
                    Text("Applied when you open a new formula's scaler or plan a new bake.")
                }

                Section {
                    statRow("Formulas", systemImage: "list.bullet.rectangle", value: formulas.count)
                    statRow("Ingredients", systemImage: "drop", value: ingredientCount)
                    statRow("Bakes", systemImage: "flame", value: bakes.count)
                    statRow("Feedings", systemImage: "leaf", value: feedingCount)
                } header: {
                    Text("Your data")
                } footer: {
                    Text("Everything stays on this device, stored with SwiftData. Nothing leaves your phone.")
                }

                Section("Manage") {
                    Button {
                        showingResetConfirm = true
                    } label: {
                        Label("Reset to sample data", systemImage: "arrow.counterclockwise")
                    }
                    Button(role: .destructive) {
                        showingClearConfirm = true
                    } label: {
                        Label("Clear all data", systemImage: "trash")
                    }
                }

                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0").font(Brand.mono(15)).foregroundStyle(Brand.text3)
                    }
                    HStack {
                        Text("Made by")
                        Spacer()
                        Text("Orbioom").foregroundStyle(Brand.text2)
                    }
                } header: {
                    Text("About")
                } footer: {
                    Text("Crumb — conjured, not just coded.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle("Settings")
            .alert("Reset to sample data?", isPresented: $showingResetConfirm) {
                Button("Reset", role: .destructive) { resetToSample() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This replaces everything currently in Crumb with the original sample formulas, bakes, and starter.")
            }
            .alert("Clear all data?", isPresented: $showingClearConfirm) {
                Button("Delete everything", role: .destructive) { clearAll() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Every formula, bake, and feeding will be permanently removed. This can't be undone.")
            }
            .overlay(alignment: .bottom) {
                if let toast { ToastView(message: toast) }
            }
        }
    }

    private func statRow(_ title: String, systemImage: String, value: Int) -> some View {
        HStack {
            Label(title, systemImage: systemImage)
            Spacer()
            Text("\(value)")
                .font(Brand.mono(15))
                .foregroundStyle(Brand.text2)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }

    private func resetToSample() {
        do {
            try SampleData.clear(context)
            SampleData.insert(into: context)
            Haptics.success(enabled: settings.hapticsEnabled)
            flash("Sample data restored")
        } catch {
            flash("Couldn't reset — please try again")
        }
    }

    private func clearAll() {
        do {
            try SampleData.clear(context)
            Haptics.warning(enabled: settings.hapticsEnabled)
            flash("All data cleared")
        } catch {
            flash("Couldn't clear — please try again")
        }
    }

    private func flash(_ message: String) {
        withAnimation(Brand.ease()) { toast = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(Brand.ease()) { toast = nil }
        }
    }
}

#Preview {
    let container = PreviewSupport.container()
    return SettingsView()
        .environment(SettingsStore())
        .modelContainer(container)
}
