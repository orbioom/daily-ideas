import SwiftUI

struct SparkSettingsView: View {
    @AppStorage(SparkSettings.defaultDuration) private var defaultDuration = 25
    @AppStorage(SparkSettings.warningHaptics) private var warningHaptics = true
    @AppStorage(SparkSettings.keepScreenOn) private var keepScreenOn = true
    @AppStorage(SparkSettings.transitionWarning) private var transitionWarning = true
    @AppStorage(SparkSettings.onboardingDone) private var onboardingDone = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Timer") {
                    Picker("Default Duration", selection: $defaultDuration) {
                        ForEach([15, 20, 25, 30, 45, 60], id: \.self) { m in
                            Text("\(m) minutes").tag(m)
                        }
                    }
                    .accessibilityLabel("Default session duration")
                }

                Section("Alerts") {
                    Toggle("Warning Haptics", isOn: $warningHaptics)
                        .accessibilityLabel("Haptic feedback at 5 minutes and 1 minute remaining")
                    Toggle("Transition Warning", isOn: $transitionWarning)
                        .accessibilityLabel("Show warning before ending a session early")
                }

                Section("Display") {
                    Toggle("Keep Screen On", isOn: $keepScreenOn)
                        .accessibilityLabel("Prevent screen from dimming during focus sessions")
                }

                Section("About") {
                    LabeledContent("App", value: "Spark")
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Purpose", value: "ADHD-friendly focus timer")
                }

                Section {
                    Button("Replay Onboarding") {
                        onboardingDone = false
                    }
                    .foregroundStyle(SparkTheme.electricBlue)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
