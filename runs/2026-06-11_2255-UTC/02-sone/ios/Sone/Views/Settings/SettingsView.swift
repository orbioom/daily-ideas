import SwiftUI

struct SettingsView: View {
    @AppStorage("calibrationOffset") private var calibrationOffset = 100.0
    @AppStorage("keepAwakeWhileMetering") private var keepAwake = true
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Calibration offset")
                            Spacer()
                            Text(String(format: "%+.0f dB", calibrationOffset - 100))
                                .monospacedDigit()
                                .foregroundStyle(Theme.textSecondary)
                        }
                        Slider(value: $calibrationOffset, in: 80...120, step: 1)
                            .accessibilityLabel("Calibration offset")
                            .accessibilityValue(String(format: "%+.0f decibels from default", calibrationOffset - 100))
                        Button("Reset to default") { calibrationOffset = 100 }
                            .font(.caption)
                            .disabled(calibrationOffset == 100)
                    }
                } header: {
                    Text("Calibration")
                } footer: {
                    Text("If you have access to a reference meter, adjust until Sone matches it in a steady sound. Most iPhones read accurately within ±3 dB at the default.")
                }

                Section("Behavior") {
                    Toggle("Keep screen awake on the meter", isOn: $keepAwake)
                    Toggle("Haptic feedback", isOn: $hapticsEnabled)
                }

                Section("Privacy") {
                    Label {
                        Text("Audio is analyzed live on this device and reduced to a single level number. Nothing is recorded, stored, or transmitted.")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    } icon: {
                        Image(systemName: "lock.shield")
                            .foregroundStyle(Theme.accent)
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Exposure standard", value: "NIOSH 85 dB / 8 h")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
