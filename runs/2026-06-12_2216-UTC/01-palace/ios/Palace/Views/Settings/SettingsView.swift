import SwiftUI

struct SettingsView: View {
    @AppStorage("drawThree") private var drawThree = false
    @AppStorage("leftHandMode") private var leftHandMode = false
    @AppStorage("showScoreBar") private var showScoreBar = true
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("feltStyle") private var feltStyleRaw = Felt.classic.rawValue

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Draw", selection: $drawThree) {
                        Text("One card").tag(false)
                        Text("Three cards").tag(true)
                    }
                    Picker("Felt", selection: $feltStyleRaw) {
                        ForEach(Felt.allCases) { felt in
                            Text(felt.displayName).tag(felt.rawValue)
                        }
                    }
                } header: {
                    Text("Game")
                } footer: {
                    Text("The draw setting takes effect on the next deal. Draw three is the harder, traditional casino rule.")
                }

                Section("Table") {
                    Toggle("Show score, time & moves", isOn: $showScoreBar)
                    Toggle("Left-handed layout", isOn: $leftHandMode)
                        .accessibilityHint("Places the stock and waste piles on the right side")
                }

                Section("Feedback") {
                    Toggle("Haptics", isOn: $hapticsEnabled)
                }

                Section {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Ads", value: "None, ever")
                    LabeledContent("Your data", value: "Stays on this device")
                } header: {
                    Text("About")
                } footer: {
                    Text("Palace is classic Klondike with no ads, no tracking, and no energy meters. Just the cards.")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
