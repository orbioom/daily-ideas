import SwiftUI

struct FlowSettingsView: View {
    @AppStorage("hapticsEnabled") private var haptics = true
    @AppStorage("keepAwake") private var keepAwake = true
    @AppStorage("showBreathCues") private var showBreathCues = true
    @AppStorage("countdownBeeps") private var countdownBeeps = false
    @AppStorage("preferredDifficulty") private var preferredDifficulty = "Beginner"

    var body: some View {
        NavigationStack {
            Form {
                Section("Practice") {
                    Picker("Preferred Difficulty", selection: $preferredDifficulty) {
                        ForEach(SessionDifficulty.allCases, id: \.self) { Text($0.rawValue).tag($0.rawValue) }
                    }
                    .accessibilityLabel("Preferred practice difficulty")

                    Toggle("Show breath cues", isOn: $showBreathCues)
                        .tint(FlowTheme.sage)
                        .accessibilityLabel("Show breathing cues during sessions")

                    Toggle("Keep screen awake", isOn: $keepAwake)
                        .tint(FlowTheme.sage)
                        .accessibilityLabel("Prevent screen from sleeping during a session")
                }

                Section("Feedback") {
                    Toggle("Haptic transitions", isOn: $haptics)
                        .tint(FlowTheme.sage)
                        .accessibilityLabel("Haptic feedback when moving to next pose")
                }

                Section("About") {
                    HStack { Text("Sessions"); Spacer(); Text("8 built-in").foregroundStyle(FlowTheme.subtle) }
                    HStack { Text("Poses"); Spacer(); Text("20 poses").foregroundStyle(FlowTheme.subtle) }
                    HStack { Text("Version"); Spacer(); Text("1.0").foregroundStyle(FlowTheme.subtle) }
                    HStack { Text("Data"); Spacer(); Text("On-device only").font(.caption).foregroundStyle(FlowTheme.subtle) }
                }
            }
            .scrollContentBackground(.hidden)
            .background(FlowTheme.bg)
            .navigationTitle("Settings")
        }
    }
}
