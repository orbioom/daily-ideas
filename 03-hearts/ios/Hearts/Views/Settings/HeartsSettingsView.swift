import SwiftUI

struct HeartsSettingsView: View {
    @AppStorage("heartsAILevel") private var aiLevelRaw = AILevel.medium.rawValue
    @AppStorage("heartsHaptics") private var hapticsEnabled = true
    @AppStorage("heartsShowPoints") private var showPoints = true
    @AppStorage("heartsHasSeenOnboarding") private var hasSeenOnboarding = true

    private var aiLevel: Binding<AILevel> {
        Binding(
            get: { AILevel(rawValue: aiLevelRaw) ?? .medium },
            set: { aiLevelRaw = $0.rawValue }
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.04, green: 0.08, blue: 0.04).ignoresSafeArea()

                List {
                    Section("Gameplay") {
                        Picker("AI Difficulty", selection: aiLevel) {
                            ForEach(AILevel.allCases) { level in
                                Text(level.rawValue).tag(level)
                            }
                        }
                        .pickerStyle(.navigationLink)
                    }
                    .listRowBackground(Color.white.opacity(0.08))

                    Section("Display") {
                        Toggle("Show Points on Cards", isOn: $showPoints)
                    }
                    .listRowBackground(Color.white.opacity(0.08))

                    Section("Feel") {
                        Toggle("Haptic Feedback", isOn: $hapticsEnabled)
                    }
                    .listRowBackground(Color.white.opacity(0.08))

                    Section("About") {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("1.0").foregroundStyle(.secondary)
                        }
                        Button("Show Introduction") {
                            hasSeenOnboarding = false
                        }
                        .foregroundStyle(Color(red: 0.85, green: 0.1, blue: 0.2))
                    }
                    .listRowBackground(Color.white.opacity(0.08))
                }
                .scrollContentBackground(.hidden)
                .foregroundStyle(.white)
            }
            .navigationTitle("Settings")
            .toolbarBackground(Color(red: 0.04, green: 0.08, blue: 0.04), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .tint(Color(red: 0.85, green: 0.1, blue: 0.2))
    }
}
