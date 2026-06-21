import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var settingsQuery: [PebbleSettings]
    @Environment(\.modelContext) private var ctx

    private var settings: PebbleSettings {
        if let s = settingsQuery.first { return s }
        let s = PebbleSettings()
        ctx.insert(s)
        return s
    }

    var body: some View {
        ZStack {
            PebbleTheme.backgroundGradient.ignoresSafeArea()
            Form {
                Section("Gameplay") {
                    Picker("Difficulty", selection: Bindable(settings).difficulty) {
                        Text("Easy").tag(0)
                        Text("Medium").tag(1)
                        Text("Hard").tag(2)
                    }
                    Picker("Stones per Pit", selection: Bindable(settings).stonesPerPit) {
                        Text("3").tag(3)
                        Text("4 (Standard)").tag(4)
                        Text("6").tag(6)
                    }
                }
                Section("Feedback") {
                    Toggle("Haptic Feedback", isOn: Bindable(settings).hapticFeedback)
                    Toggle("Sound Effects", isOn: Bindable(settings).soundEnabled)
                }
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0").foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Rules")
                        Spacer()
                        Text("Kalah (standard)").foregroundStyle(.secondary)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Settings")
        }
    }
}
