import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var settingsArr: [IvorySettings]
    @Environment(\.modelContext) private var ctx

    private var settings: IvorySettings {
        settingsArr.first ?? { let s = IvorySettings(); ctx.insert(s); return s }()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                IvoryTheme.background.ignoresSafeArea()
                Form {
                    Section("Gameplay") {
                        Picker("Difficulty", selection: Binding(
                            get: { settings.difficulty },
                            set: { settings.difficulty = $0 }
                        )) {
                            Text("Beginner").tag("beginner")
                            Text("Intermediate").tag("intermediate")
                            Text("Advanced").tag("advanced")
                        }
                        .accessibilityLabel("Select AI difficulty")

                        Picker("Play as", selection: Binding(
                            get: { settings.playerColor },
                            set: { settings.playerColor = $0 }
                        )) {
                            Text("⚫ Black (first)").tag("black")
                            Text("⚪ White (second)").tag("white")
                        }
                        .accessibilityLabel("Choose your disc color")

                        Toggle("Show valid move hints", isOn: Binding(
                            get: { settings.showHints },
                            set: { settings.showHints = $0 }
                        ))
                    }

                    Section("Experience") {
                        Toggle("Animations", isOn: Binding(
                            get: { settings.showAnimations },
                            set: { settings.showAnimations = $0 }
                        ))
                        Toggle("Haptics", isOn: Binding(
                            get: { settings.hapticEnabled },
                            set: { settings.hapticEnabled = $0 }
                        ))
                    }

                    Section("About") {
                        LabeledContent("Version", value: "1.0")
                        LabeledContent("Rules", value: "Reversi / Othello")
                        if let wikiURL = URL(string: "https://en.wikipedia.org/wiki/Reversi") {
                            Link("How to Play", destination: wikiURL)
                                .foregroundStyle(IvoryTheme.accent)
                        }
                    }

                    Section {
                        Button("Reset Onboarding", role: .destructive) {
                            settings.hasCompletedOnboarding = false
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
        }
    }
}
