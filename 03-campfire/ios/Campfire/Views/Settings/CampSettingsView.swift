import SwiftUI
import SwiftData

struct CampSettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var settingsQ: [CampSettings]
    @State private var showClearAlert = false

    private var settings: CampSettings {
        if let s = settingsQ.first { return s }
        let s = CampSettings(); context.insert(s); try? context.save(); return s
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Preferences") {
                    Picker("Default Camp Type", selection: Binding(
                        get: { settings.defaultCampType },
                        set: { settings.defaultCampType = $0; try? context.save() }
                    )) {
                        ForEach(CampType.allCases, id: \.self) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    .accessibilityLabel("Default camp type")

                    Toggle("Show Countdown on Trips", isOn: Binding(
                        get: { settings.showCountdown },
                        set: { settings.showCountdown = $0; try? context.save() }
                    ))
                    .accessibilityLabel("Show countdown to trip start")

                    Picker("Weight Unit", selection: Binding(
                        get: { settings.weightUnit },
                        set: { settings.weightUnit = $0; try? context.save() }
                    )) {
                        Text("oz").tag("oz")
                        Text("g").tag("g")
                        Text("kg").tag("kg")
                        Text("lb").tag("lb")
                    }
                    .accessibilityLabel("Weight unit for gear")
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0").foregroundColor(CampfireTheme.secondaryLabel)
                    }
                    HStack {
                        Text("App")
                        Spacer()
                        Text("Campfire").foregroundColor(CampfireTheme.secondaryLabel)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showClearAlert = true
                    } label: {
                        Label("Clear All Data", systemImage: "trash")
                    }
                    .accessibilityLabel("Clear all trip data")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Clear All Data?", isPresented: $showClearAlert) {
                Button("Delete Everything", role: .destructive) { clearAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all trips, gear, meals, and nature logs. This cannot be undone.")
            }
        }
    }

    private func clearAll() {
        try? context.delete(model: CampTrip.self)
        try? context.delete(model: GearItem.self)
        try? context.delete(model: MealPlan.self)
        try? context.delete(model: NatureLog.self)
        try? context.save()
    }
}
