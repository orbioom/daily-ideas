import SwiftUI

struct SettingsView: View {
    @AppStorage("defaultWPM") private var defaultWPM = 150.0
    @AppStorage("prompterFontSize") private var fontSize = 34.0
    @AppStorage("countdownSeconds") private var countdownSeconds = 3
    @AppStorage("guideStyle") private var guideStyleRaw = PrompterView.GuideStyle.band.rawValue
    @AppStorage("mirrorHorizontal") private var mirrorHorizontal = false
    @AppStorage("mirrorVertical") private var mirrorVertical = false
    @AppStorage("keepAwake") private var keepAwake = true
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Reading pace") {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Default speed")
                            Spacer()
                            Text("\(Int(defaultWPM)) wpm")
                                .foregroundStyle(Theme.textSecondary)
                                .monospacedDigit()
                        }
                        Slider(value: $defaultWPM, in: 60...300, step: 5)
                            .accessibilityLabel("Default reading speed")
                            .accessibilityValue("\(Int(defaultWPM)) words per minute")
                    }
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Text size")
                            Spacer()
                            Text("\(Int(fontSize)) pt")
                                .foregroundStyle(Theme.textSecondary)
                                .monospacedDigit()
                        }
                        Slider(value: $fontSize, in: 20...64, step: 2)
                            .accessibilityLabel("Prompter text size")
                            .accessibilityValue("\(Int(fontSize)) points")
                    }
                    Stepper("Countdown: \(countdownSeconds)s", value: $countdownSeconds, in: 0...10)
                }

                Section("Display") {
                    Picker("Guide line", selection: $guideStyleRaw) {
                        ForEach(PrompterView.GuideStyle.allCases, id: \.rawValue) { style in
                            Text(style.label).tag(style.rawValue)
                        }
                    }
                    Toggle("Mirror horizontally", isOn: $mirrorHorizontal)
                    Toggle("Flip vertically", isOn: $mirrorVertical)
                    Text("Mirroring is for beam-splitter teleprompter glass, where the phone's reflection must read correctly.")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }

                Section("Behavior") {
                    Toggle("Keep screen awake while prompting", isOn: $keepAwake)
                    Toggle("Haptic feedback", isOn: $hapticsEnabled)
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    Text("Lectern keeps every script on this device. Nothing is uploaded, ever.")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
