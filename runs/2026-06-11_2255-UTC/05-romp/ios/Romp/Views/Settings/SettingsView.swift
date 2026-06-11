import SwiftUI

struct SettingsView: View {
    @AppStorage("roundSeconds") private var roundSeconds = 60
    @AppStorage("tiltControls") private var tiltControls = true
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Gameplay") {
                    Picker("Default round length", selection: $roundSeconds) {
                        Text("30 seconds").tag(30)
                        Text("60 seconds").tag(60)
                        Text("90 seconds").tag(90)
                        Text("120 seconds").tag(120)
                    }
                    Toggle("Tilt to score", isOn: $tiltControls)
                    Text("With tilt on, hold the phone to your forehead: tilt the screen toward the floor for a correct guess, toward the ceiling to pass. The on-screen buttons always work too.")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }

                Section("Feedback") {
                    Toggle("Haptics", isOn: $hapticsEnabled)
                }

                Section("How to play") {
                    Text("""
                    One player holds the phone so everyone else can see the word. The group acts, describes or hums it (deck rules vary — be generous). Guess right: tilt down. Stuck: tilt up to pass. Highest score when the timer dies wins the round, loser fetches snacks.
                    """)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Built-in decks", value: "8 · \(DeckLibrary.decks.reduce(0) { $0 + $1.words.count }) cards")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
