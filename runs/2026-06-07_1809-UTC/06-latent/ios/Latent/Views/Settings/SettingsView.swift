import SwiftUI
import SwiftData

/// Settings: persisted preferences (haptics, appearance, temperature units,
/// default agitation interval, keep-screen-awake), library counts, a guarded
/// "Erase all" action, and an About section.
struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var recipes: [Recipe]
    @Query private var sessions: [DevSession]

    @AppStorage("latent.haptics") private var hapticsEnabled = true
    @AppStorage("latent.appearance") private var appearanceRaw = AppearancePref.system.rawValue
    @AppStorage("latent.tempUnit") private var tempUnitRaw = TempUnit.celsius.rawValue
    @AppStorage("latent.agitationInterval") private var agitationInterval = 60
    @AppStorage("latent.keepAwake") private var keepAwake = true

    @State private var showEraseConfirm = false
    @State private var showAbout = false

    private var appearance: AppearancePref { AppearancePref(rawValue: appearanceRaw) ?? .system }
    private var tempUnit: TempUnit { TempUnit(rawValue: tempUnitRaw) ?? .celsius }

    private let agitationOptions = [30, 45, 60, 90, 120]

    var body: some View {
        NavigationStack {
            Form {
                preferencesSection
                timerSection
                librarySection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle("Settings")
            .confirmationDialog(
                "Erase all recipes and sessions?",
                isPresented: $showEraseConfirm,
                titleVisibility: .visible
            ) {
                Button("Erase everything", role: .destructive) { eraseAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently deletes all \(recipes.count) recipes and \(sessions.count) sessions. This can't be undone.")
            }
            .sheet(isPresented: $showAbout) { AboutView() }
        }
    }

    // MARK: - Preferences

    private var preferencesSection: some View {
        Section("Preferences") {
            Toggle(isOn: $hapticsEnabled) {
                Label("Haptics", systemImage: "hand.tap")
            }
            .onChange(of: hapticsEnabled) { _, v in
                Haptics.enabled = v
                if v { Haptics.selection() }
            }

            Picker(selection: $appearanceRaw) {
                ForEach(AppearancePref.allCases) { pref in
                    Text(pref.label).tag(pref.rawValue)
                }
            } label: {
                Label("Appearance", systemImage: "circle.lefthalf.filled")
            }

            Picker(selection: $tempUnitRaw) {
                ForEach(TempUnit.allCases) { unit in
                    Text(unit == .celsius ? "Celsius (°C)" : "Fahrenheit (°F)").tag(unit.rawValue)
                }
            } label: {
                Label("Temperature units", systemImage: "thermometer.medium")
            }
        }
    }

    // MARK: - Timer

    private var timerSection: some View {
        Section {
            Picker(selection: $agitationInterval) {
                ForEach(agitationOptions, id: \.self) { secs in
                    Text(DevEngine.clock(secs)).tag(secs)
                }
            } label: {
                Label("Agitation interval", systemImage: "arrow.up.arrow.down")
            }

            Toggle(isOn: $keepAwake) {
                Label("Keep screen awake", systemImage: "sun.max")
            }
        } header: {
            Text("Timer")
        } footer: {
            Text("The default agitation reminder spacing for new runs, and whether the screen stays on while a timer is running.")
        }
    }

    // MARK: - Library

    private var librarySection: some View {
        Section("Library") {
            InfoRow(label: "Recipes", value: "\(recipes.count)", mono: true)
            InfoRow(label: "Logged sessions", value: "\(sessions.count)", mono: true)
            InfoRow(label: "Total rolls", value: "\(totalRolls)", mono: true)
        }
    }

    private var totalRolls: Int { sessions.reduce(0) { $0 + max(0, $1.rolls) } }

    // MARK: - Data

    private var dataSection: some View {
        Section {
            Button(role: .destructive) {
                Haptics.tap()
                showEraseConfirm = true
            } label: {
                Label("Erase all data", systemImage: "trash")
            }
            .disabled(recipes.isEmpty && sessions.isEmpty)
        } header: {
            Text("Data")
        } footer: {
            Text("Everything is stored on this device only.")
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section("About") {
            Button {
                Haptics.tap()
                showAbout = true
            } label: {
                Label("About Latent", systemImage: "info.circle")
            }
            InfoRow(label: "Version", value: appVersion, mono: true)
        }
    }

    private var appVersion: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(v) (\(b))"
    }

    // MARK: - Erase

    private func eraseAll() {
        Haptics.warning()
        for session in sessions { context.delete(session) }
        for recipe in recipes { context.delete(recipe) }
        try? context.save()
    }
}
