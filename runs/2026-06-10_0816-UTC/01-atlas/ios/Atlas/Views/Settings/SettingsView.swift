import SwiftUI

struct SettingsView: View {
    @AppStorage("weightUnit") private var unitRaw = WeightUnit.kg.rawValue
    @AppStorage("weeklyGoal") private var weeklyGoal = 3
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("keepAwake") private var keepAwake = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Units") {
                    Picker("Weight unit", selection: $unitRaw) {
                        ForEach(WeightUnit.allCases) { u in
                            Text(u.label).tag(u.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                    Text("Weights are stored in kilograms and converted for display, so switching is always safe.")
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                }

                Section("Training") {
                    Stepper("Weekly session goal: \(weeklyGoal)", value: $weeklyGoal, in: 1...7)
                        .accessibilityHint("Used for the week streak in Insights")
                    Toggle("Keep screen awake in workouts", isOn: $keepAwake)
                        .tint(Brand.live)
                }

                Section("Feel") {
                    Toggle("Haptic feedback", isOn: $hapticsEnabled)
                        .tint(Brand.live)
                }

                Section("About") {
                    LabeledContent("App", value: "Atlas 1.0")
                    LabeledContent("Made by", value: "Orbioom")
                    Text("Your training never leaves this device. No account, no upload, no tracking.")
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
