import SwiftUI

struct SettingsView: View {
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("showMoodCheckIn") private var showMoodCheckIn = true
    @AppStorage("gentleLanguage") private var gentleLanguage = true
    @AppStorage("defaultBelief") private var defaultBelief = 75.0

    var body: some View {
        NavigationStack {
            Form {
                Section("Today screen") {
                    Toggle("Show mood check-in", isOn: $showMoodCheckIn)
                        .tint(Brand.live)
                    Text("Hide it if you'd rather keep Today purely about thought records.")
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                }

                Section("Records") {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Default starting belief")
                            Spacer()
                            Text("\(Int(defaultBelief))%")
                                .font(Brand.mono(15, weight: .medium))
                                .foregroundStyle(Brand.text2)
                        }
                        Slider(value: $defaultBelief, in: 25...100, step: 5)
                            .tint(Brand.live)
                            .accessibilityLabel("Default starting belief")
                            .accessibilityValue("\(Int(defaultBelief)) percent")
                    }
                    Toggle("Gentle summaries", isOn: $gentleLanguage)
                        .tint(Brand.live)
                    Text("Gentle summaries soften the wording on the save screen when a record doesn't move the numbers.")
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                }

                Section("Feel") {
                    Toggle("Haptic feedback", isOn: $hapticsEnabled)
                        .tint(Brand.live)
                }

                Section("About") {
                    LabeledContent("App", value: "Steady 1.0")
                    LabeledContent("Made by", value: "Orbioom")
                    LabeledContent("Method", value: "CBT thought records")
                    Text("Steady is a self-help tool based on cognitive behavioral therapy techniques. It is not therapy, diagnosis, or medical advice. If you're in crisis, contact local emergency services or a crisis line first.")
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                    Text("Every word you write stays on this device. No account, no cloud, no analytics.")
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
