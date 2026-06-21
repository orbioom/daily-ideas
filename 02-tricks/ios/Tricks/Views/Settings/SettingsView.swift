import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var settingsArr: [TricksSettings]
    @Environment(\.modelContext) private var ctx
    private var settings: TricksSettings { settingsArr.first ?? { let s=TricksSettings(); ctx.insert(s); return s }() }

    var body: some View {
        NavigationStack {
            ZStack {
                TricksTheme.background.ignoresSafeArea()
                Form {
                    Section("Gameplay") {
                        Picker("AI Difficulty", selection: Binding(get:{settings.difficulty}, set:{settings.difficulty=$0})) {
                            Text("Easy").tag("easy"); Text("Medium").tag("medium"); Text("Hard").tag("hard")
                        }.accessibilityLabel("Select AI difficulty")
                        Picker("Winning Score", selection: Binding(get:{settings.targetScore}, set:{settings.targetScore=$0})) {
                            Text("300 pts").tag(300); Text("500 pts").tag(500); Text("750 pts").tag(750)
                        }.accessibilityLabel("Target score to win")
                    }
                    Section("Experience") {
                        Toggle("Sound Effects", isOn: Binding(get:{settings.soundEnabled}, set:{settings.soundEnabled=$0}))
                        Toggle("Haptics", isOn: Binding(get:{settings.hapticEnabled}, set:{settings.hapticEnabled=$0}))
                        Toggle("Show Card Values", isOn: Binding(get:{settings.showCardValues}, set:{settings.showCardValues=$0}))
                    }
                    Section("Rules") {
                        Text("Spades always trump. Must follow suit. Nil bid: +/-100. Bags penalty: -100 per 10 bags.").font(.caption).foregroundStyle(TricksTheme.secondaryText)
                    }
                    Section {
                        Button("Reset Onboarding", role: .destructive) { settings.hasCompletedOnboarding = false }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
        }
    }
}
