import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("limber.goalMinutes") private var goalMinutes = 10
    @AppStorage("limber.countIn") private var countInSeconds = 3
    @AppStorage("limber.transition") private var transitionSeconds = 5
    @AppStorage("limber.keepAwake") private var keepAwake = true
    @AppStorage("limber.haptics") private var haptics = true

    @State private var confirmReset = false

    var body: some View {
        Form {
            Section("Daily goal") {
                Stepper(value: $goalMinutes, in: 1...60) {
                    Text("\(goalMinutes) minutes a day").font(Brand.mono(15))
                }
            }
            Section("Session") {
                Stepper(value: $countInSeconds, in: 0...10) {
                    Text(countInSeconds == 0 ? "No count-in" : "Count-in: \(countInSeconds)s")
                        .font(Brand.mono(15))
                }
                Stepper(value: $transitionSeconds, in: 0...15) {
                    Text(transitionSeconds == 0 ? "No rest between stretches" : "Rest between: \(transitionSeconds)s")
                        .font(Brand.mono(15))
                }
                Toggle("Keep screen awake", isOn: $keepAwake)
            }
            Section("Feedback") {
                Toggle("Haptics", isOn: $haptics)
                    .onChange(of: haptics) { _, new in Haptics.enabled = new }
            }
            Section {
                Button(role: .destructive) { confirmReset = true } label: {
                    Text("Reset onboarding")
                }
            } footer: {
                Text("Limber keeps all your data on this device. Nothing is uploaded.")
            }
            Section {
                HStack {
                    Text("Version"); Spacer()
                    Text("1.0").foregroundStyle(Brand.text3).font(Brand.mono(14))
                }
            }
        }
        .navigationTitle("Settings")
        .alert("Reset onboarding?", isPresented: $confirmReset) {
            Button("Reset", role: .destructive) {
                UserDefaults.standard.set(false, forKey: "limber.onboarded")
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You'll see the intro again next launch. Your routines and history are kept.")
        }
    }
}
