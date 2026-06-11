import SwiftUI

struct SettingsView: View {
    @AppStorage("skim.speedWPM") private var speedWPM = 300
    @AppStorage("skim.chunkSize") private var chunkSize = 1
    @AppStorage("skim.theme") private var themeRaw = SkimTheme.ReaderBackground.cream.rawValue
    @AppStorage("skim.fontSize") private var fontSize = 36

    var body: some View {
        Form {
            Section("Reading Defaults") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Default speed")
                        Spacer()
                        Text("\(speedWPM) WPM")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: Binding(
                        get: { Double(speedWPM) },
                        set: { speedWPM = Int($0) }
                    ), in: 100...800, step: 25)
                    .tint(SkimTheme.accent)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Default reading speed: \(speedWPM) words per minute")

                Picker("Words per flash", selection: $chunkSize) {
                    Text("1 word").tag(1)
                    Text("2 words").tag(2)
                    Text("3 words").tag(3)
                }
                .accessibilityLabel("Words per flash")

                Picker("Default theme", selection: $themeRaw) {
                    ForEach(SkimTheme.ReaderBackground.allCases, id: \.self) { t in
                        Text(t.rawValue).tag(t.rawValue)
                    }
                }
                .accessibilityLabel("Default reading theme")

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Font size")
                        Spacer()
                        Text("\(fontSize)pt")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: Binding(
                        get: { Double(fontSize) },
                        set: { fontSize = Int($0) }
                    ), in: 20...60, step: 4)
                    .tint(SkimTheme.accent)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Font size: \(fontSize) points")
            }

            Section("About") {
                LabeledContent("Version", value: "1.0")
                Link("Privacy Policy", destination: URL(string: "https://orbioom.com/privacy")!)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }
}
