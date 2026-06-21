import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsList: [NovaSettings]
    @State private var showCityPicker = false

    private var settings: NovaSettings {
        if let s = settingsList.first { return s }
        let s = NovaSettings(); modelContext.insert(s); return s
    }

    var selectedCity: CelestialCity {
        CityData.cities[safe: settings.selectedCityIndex] ?? CityData.cities[0]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                NovaTheme.skyBackground.ignoresSafeArea()
                Form {
                    Section {
                        Button {
                            showCityPicker = true
                        } label: {
                            HStack {
                                Text("Location")
                                    .foregroundStyle(NovaTheme.textPrimary)
                                Spacer()
                                Text(selectedCity.name)
                                    .foregroundStyle(NovaTheme.textSecondary)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundStyle(NovaTheme.textSecondary)
                            }
                        }

                        HStack {
                            Text("Limiting Magnitude")
                                .foregroundStyle(NovaTheme.textPrimary)
                            Spacer()
                            Text(String(format: "%.1f", settings.limitingMagnitude))
                                .foregroundStyle(NovaTheme.textSecondary)
                        }
                        Slider(value: Binding(
                            get: { settings.limitingMagnitude },
                            set: { settings.limitingMagnitude = $0 }
                        ), in: 2.0...6.5, step: 0.5)
                        .tint(NovaTheme.accentGold)
                    } header: { Text("Location & Display") }
                    .listRowBackground(NovaTheme.cardBackground)

                    Section {
                        Toggle("Constellation Lines", isOn: Binding(
                            get: { settings.showConstellationLines },
                            set: { settings.showConstellationLines = $0 }
                        ))
                        .tint(NovaTheme.accent)
                        .foregroundStyle(NovaTheme.textPrimary)

                        Toggle("Constellation Names", isOn: Binding(
                            get: { settings.showConstellationNames },
                            set: { settings.showConstellationNames = $0 }
                        ))
                        .tint(NovaTheme.accent)
                        .foregroundStyle(NovaTheme.textPrimary)

                        Toggle("Show Planets", isOn: Binding(
                            get: { settings.showPlanets },
                            set: { settings.showPlanets = $0 }
                        ))
                        .tint(NovaTheme.accent)
                        .foregroundStyle(NovaTheme.textPrimary)

                        Toggle("Show Moon", isOn: Binding(
                            get: { settings.showMoon },
                            set: { settings.showMoon = $0 }
                        ))
                        .tint(NovaTheme.accent)
                        .foregroundStyle(NovaTheme.textPrimary)

                        Toggle("North Up", isOn: Binding(
                            get: { settings.northUp },
                            set: { settings.northUp = $0 }
                        ))
                        .tint(NovaTheme.accent)
                        .foregroundStyle(NovaTheme.textPrimary)

                        Toggle("Haptics", isOn: Binding(
                            get: { settings.hapticsEnabled },
                            set: { settings.hapticsEnabled = $0 }
                        ))
                        .tint(NovaTheme.accent)
                        .foregroundStyle(NovaTheme.textPrimary)
                    } header: { Text("Sky Chart") }
                    .listRowBackground(NovaTheme.cardBackground)

                    Section {
                        HStack {
                            Text("Coordinates")
                                .foregroundStyle(NovaTheme.textSecondary)
                            Spacer()
                            Text(String(format: "%.2f° %.2f°", selectedCity.latitude, selectedCity.longitude))
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundStyle(NovaTheme.textSecondary)
                        }
                        HStack {
                            Text("Version")
                                .foregroundStyle(NovaTheme.textSecondary)
                            Spacer()
                            Text("1.0")
                                .foregroundStyle(NovaTheme.textSecondary)
                        }
                    } header: { Text("About") }
                    .listRowBackground(NovaTheme.cardBackground)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(NovaTheme.cardBackground, for: .navigationBar)
            .sheet(isPresented: $showCityPicker) {
                CityPickerView(selectedIndex: Binding(
                    get: { settings.selectedCityIndex },
                    set: { settings.selectedCityIndex = $0 }
                ))
            }
        }
    }
}

struct CityPickerView: View {
    @Binding var selectedIndex: Int
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var filtered: [CelestialCity] {
        if searchText.isEmpty { return CityData.cities }
        return CityData.cities.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.country.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                NovaTheme.skyBackground.ignoresSafeArea()
                List(filtered) { city in
                    Button {
                        selectedIndex = city.id
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(city.name)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(NovaTheme.textPrimary)
                                Text("\(city.country) · \(latString(city.latitude))")
                                    .font(.system(size: 13))
                                    .foregroundStyle(NovaTheme.textSecondary)
                            }
                            Spacer()
                            if city.id == selectedIndex {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(NovaTheme.accent)
                            }
                        }
                    }
                    .listRowBackground(NovaTheme.cardBackground)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Choose City")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(NovaTheme.cardBackground, for: .navigationBar)
            .searchable(text: $searchText, prompt: "Search cities…")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }.foregroundStyle(NovaTheme.accent)
                }
            }
        }
    }

    func latString(_ lat: Double) -> String {
        String(format: "%.1f°%@", abs(lat), lat >= 0 ? "N" : "S")
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
