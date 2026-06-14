import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    @State private var showPaywall = false
    @State private var showResetConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Pro
                Section {
                    if isPro {
                        HStack {
                            Label("Bell Pro", systemImage: "checkmark.seal.fill")
                                .foregroundStyle(Theme.accent)
                            Spacer()
                            Text("Unlocked").foregroundStyle(Theme.textSecondary)
                        }
                    } else {
                        Button { showPaywall = true } label: {
                            Label("Unlock Bell Pro", systemImage: "sparkles")
                        }
                    }
                }

                // MARK: Preferences
                Section("Session") {
                    Toggle("Sound", isOn: $settings.soundEnabled)
                    Toggle("Haptics", isOn: $settings.hapticsEnabled)
                    Toggle("Keep screen awake", isOn: $settings.keepScreenAwake)
                }

                Section("Goal") {
                    Stepper("Daily goal: \(settings.dailyMinutesGoal) min",
                            value: $settings.dailyMinutesGoal, in: 5...120, step: 5)
                    Picker("Default soundscape", selection: $settings.defaultAmbient) {
                        ForEach(Ambient.allCases) { amb in
                            Text(amb.displayName).tag(amb.rawValue)
                        }
                    }
                }

                // MARK: Data
                Section {
                    Button(role: .destructive) { showResetConfirm = true } label: {
                        Label("Reset sample data", systemImage: "arrow.counterclockwise")
                    }
                } footer: {
                    Text("Wipes all sessions and presets, then re-seeds the built-in presets and demo history.")
                }

                // MARK: About
                Section("About") {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("About Bell", systemImage: "info.circle")
                    }
                    LabeledContent("Version", value: "1.0")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView(reason: .general) }
            .alert("Reset sample data?", isPresented: $showResetConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    SeedData.reset(context: context)
                    Haptics.warning(enabled: settings.hapticsEnabled)
                }
            } message: {
                Text("This cannot be undone.")
            }
        }
    }
}
