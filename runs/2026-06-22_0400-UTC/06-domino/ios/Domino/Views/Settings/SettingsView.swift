import SwiftUI

struct SettingsView: View {
    let settings: DominoSettings
    let engine: DominoEngine

    var body: some View {
        NavigationStack {
            Form {
                Section("AI Difficulty") {
                    Picker("Difficulty", selection: Binding(
                        get: { DominoEngine.AIDifficulty(rawValue: settings.difficulty) ?? .medium },
                        set: { settings.difficulty = $0.rawValue }
                    )) {
                        ForEach(DominoEngine.AIDifficulty.allCases, id: \.self) { d in
                            Text(d.displayName).tag(d)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section("Match Rules") {
                    Picker("Points to Win", selection: Binding(
                        get: { settings.matchPointTarget },
                        set: { settings.matchPointTarget = $0 }
                    )) {
                        Text("50 pts").tag(50)
                        Text("100 pts").tag(100)
                        Text("150 pts").tag(150)
                        Text("200 pts").tag(200)
                    }
                }
                Section("Display") {
                    Picker("Tile Style", selection: Binding(
                        get: { settings.tileStyle },
                        set: { settings.tileStyle = $0 }
                    )) {
                        Text("Classic").tag("classic")
                        Text("Modern").tag("modern")
                    }
                    Toggle("Haptic Feedback", isOn: Binding(
                        get: { settings.hapticsEnabled },
                        set: { settings.hapticsEnabled = $0 }
                    ))
                }
                Section("About") {
                    HStack { Text("Version"); Spacer(); Text("1.0").foregroundStyle(.secondary) }
                    Link("Privacy Policy", destination: URL(string: "https://orbioom.com/privacy")!)
                }
            }
            .scrollContentBackground(.hidden)
            .background(DominoTheme.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .preferredColorScheme(.dark)
    }
}
