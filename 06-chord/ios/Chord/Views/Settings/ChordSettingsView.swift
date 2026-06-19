import SwiftUI

struct ChordSettingsView: View {
    @AppStorage(ChordSettings.defaultKey) private var defaultKey = "C"
    @AppStorage(ChordSettings.defaultTempo) private var defaultTempo = 120
    @AppStorage(ChordSettings.defaultGenre) private var defaultGenre = "Pop"
    @AppStorage(ChordSettings.hapticFeedback) private var hapticFeedback = true
    @AppStorage(ChordSettings.showRomanNumerals) private var showRomanNumerals = true
    @AppStorage(ChordSettings.onboardingDone) private var onboardingDone = true

    private let rootNotes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B",
                              "Db", "Eb", "Ab", "Bb"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Defaults") {
                    Picker("Default Key", selection: $defaultKey) {
                        ForEach(rootNotes, id: \.self) { n in Text(n).tag(n) }
                    }
                    .accessibilityLabel("Default musical key")

                    Stepper("Default Tempo: \(defaultTempo) BPM", value: $defaultTempo, in: 40...240, step: 5)
                        .accessibilityLabel("Default tempo: \(defaultTempo) beats per minute")

                    Picker("Default Genre", selection: $defaultGenre) {
                        ForEach(ProgressionGenre.allCases, id: \.self) { g in
                            Label(g.rawValue, systemImage: g.icon).tag(g.rawValue)
                        }
                    }
                }

                Section("Display") {
                    Toggle("Show Roman Numerals", isOn: $showRomanNumerals)
                        .accessibilityLabel("Show chord function as roman numerals (e.g. I, IV, V)")
                }

                Section("Feedback") {
                    Toggle("Haptic Feedback", isOn: $hapticFeedback)
                        .accessibilityLabel("Vibration feedback when toggling favorites")
                }

                Section("About") {
                    LabeledContent("App", value: "Chord")
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Purpose", value: "Songwriter chord sketchpad")
                }

                Section {
                    Button("Replay Onboarding") {
                        onboardingDone = false
                    }
                    .foregroundStyle(ChordTheme.teal)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
