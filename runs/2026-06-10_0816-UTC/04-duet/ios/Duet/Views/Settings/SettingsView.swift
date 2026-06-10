import SwiftUI

struct SettingsView: View {
    @AppStorage("nameA") private var nameA = ""
    @AppStorage("nameB") private var nameB = ""
    @AppStorage("includeSpark") private var includeSpark = true
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true

    var body: some View {
        NavigationStack {
            Form {
                Section("You two") {
                    TextField("First partner", text: $nameA)
                    TextField("Second partner", text: $nameB)
                    Text("Names appear on answer cards and the pass-the-phone flow.")
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                }

                Section("Questions") {
                    Toggle("Include Spark questions", isOn: $includeSpark)
                        .tint(Brand.live)
                    Text("Spark is the flirtier deck. Off keeps the daily question family-table safe.")
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                }

                Section("Feel") {
                    Toggle("Haptic feedback", isOn: $hapticsEnabled)
                        .tint(Brand.live)
                }

                Section("About") {
                    LabeledContent("App", value: "Duet 1.0")
                    LabeledContent("Made by", value: "Orbioom")
                    Text("Everything — answers, memories, check-ins — lives on this one phone. No account, no cloud, no per-couple subscription.")
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
