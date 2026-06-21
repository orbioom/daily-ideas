import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var settingsQuery: [PegSettings]
    @Environment(\.modelContext) private var ctx

    private var settings: PegSettings {
        if let s = settingsQuery.first { return s }
        let s = PegSettings(); ctx.insert(s); return s
    }

    var body: some View {
        ZStack {
            PegTheme.backgroundGradient.ignoresSafeArea()
            Form {
                Section("Gameplay") {
                    Picker("Difficulty", selection: Bindable(settings).difficulty) {
                        Text("Easy").tag(0)
                        Text("Medium").tag(1)
                        Text("Hard").tag(2)
                    }
                    Toggle("Show Hints", isOn: Bindable(settings).showHints)
                }
                Section("Feedback") {
                    Toggle("Haptic Feedback", isOn: Bindable(settings).hapticFeedback)
                    Toggle("Sound Effects", isOn: Bindable(settings).soundEnabled)
                }
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Target Score")
                        Spacer()
                        Text("121 points")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
