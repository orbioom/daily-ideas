import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var pets: [Pet]
    @AppStorage("whisker.weightUnit") private var unitRaw = WeightUnit.kg.rawValue
    @AppStorage("whisker.soonWindow") private var soonWindow = 3
    @AppStorage("whisker.haptics") private var haptics = true

    @State private var confirmReset = false

    private var unit: WeightUnit { WeightUnit(rawValue: unitRaw) ?? .kg }

    var body: some View {
        Form {
            Section("Units") {
                Picker("Weight unit", selection: $unitRaw) {
                    Text("Kilograms (kg)").tag(WeightUnit.kg.rawValue)
                    Text("Pounds (lb)").tag(WeightUnit.lb.rawValue)
                }
            }
            Section("Reminders") {
                Stepper(value: $soonWindow, in: 1...14) {
                    Text("“Soon” means within \(soonWindow) day\(soonWindow == 1 ? "" : "s")")
                        .font(Brand.mono(14))
                }
            }
            Section("Feedback") {
                Toggle("Haptics", isOn: $haptics)
                    .onChange(of: haptics) { _, new in Haptics.enabled = new }
            }
            Section("Sample data") {
                Button("Load sample pets") {
                    SeedData.loadSample(context); Haptics.success()
                }
                .disabled(!pets.isEmpty)
                if !pets.isEmpty {
                    Text("Sample data is only available on an empty library.")
                        .font(.caption).foregroundStyle(Brand.text3)
                }
            }
            Section {
                Button(role: .destructive) { confirmReset = true } label: { Text("Reset onboarding") }
            } footer: {
                Text("Whisker stores everything on this device. Nothing leaves your phone.")
            }
            Section {
                HStack { Text("Version"); Spacer(); Text("1.0").foregroundStyle(Brand.text3).font(Brand.mono(14)) }
            }
        }
        .navigationTitle("Settings")
        .alert("Reset onboarding?", isPresented: $confirmReset) {
            Button("Reset", role: .destructive) {
                UserDefaults.standard.set(false, forKey: "whisker.onboarded")
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You'll see the intro again next launch. Your pets and records are kept.")
        }
    }
}
