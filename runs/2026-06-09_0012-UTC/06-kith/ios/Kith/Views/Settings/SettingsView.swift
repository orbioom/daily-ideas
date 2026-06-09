import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var people: [Person]
    @AppStorage("kith.soonWindow") private var soonWindow = 3
    @AppStorage("kith.occasionWindow") private var occasionWindow = 30
    @AppStorage("kith.haptics") private var haptics = true
    @State private var confirmReset = false

    var body: some View {
        Form {
            Section("Reach-out reminders") {
                Stepper(value: $soonWindow, in: 0...14) {
                    Text(soonWindow == 0 ? "Only show overdue people"
                                         : "Show people due within \(soonWindow) day\(soonWindow == 1 ? "" : "s")")
                        .font(Brand.mono(14))
                }
            }
            Section("Occasions") {
                Stepper(value: $occasionWindow, in: 7...120, step: 7) {
                    Text("Look ahead \(occasionWindow) days").font(Brand.mono(14))
                }
            }
            Section("Feedback") {
                Toggle("Haptics", isOn: $haptics)
                    .onChange(of: haptics) { _, new in Haptics.enabled = new }
            }
            Section("Sample data") {
                Button("Load sample people") { SeedData.loadSample(context); Haptics.success() }
                    .disabled(!people.isEmpty)
            }
            Section {
                Button(role: .destructive) { confirmReset = true } label: { Text("Reset onboarding") }
            } footer: {
                Text("Kith is fully private and on-device. Your relationships are yours alone — no cloud, no ads.")
            }
            Section {
                HStack { Text("Version"); Spacer(); Text("1.0").foregroundStyle(Brand.text3).font(Brand.mono(14)) }
            }
        }
        .navigationTitle("Settings")
        .alert("Reset onboarding?", isPresented: $confirmReset) {
            Button("Reset", role: .destructive) {
                UserDefaults.standard.set(false, forKey: "kith.onboarded")
            }
            Button("Cancel", role: .cancel) {}
        } message: { Text("You'll see the intro again next launch. Your people are kept.") }
    }
}
