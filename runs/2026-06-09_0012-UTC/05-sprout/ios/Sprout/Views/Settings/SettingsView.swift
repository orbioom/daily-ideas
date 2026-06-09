import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var kids: [Kid]
    @AppStorage("sprout.symbol") private var symbol = "$"
    @AppStorage("sprout.autoApprove") private var autoApprove = false
    @AppStorage("sprout.autoAllowance") private var autoAllowance = true
    @AppStorage("sprout.haptics") private var haptics = true
    @State private var confirmReset = false

    private let symbols = ["$", "€", "£", "¥", "₹", "A$", "C$", "kr"]

    var body: some View {
        Form {
            Section("Currency") {
                Picker("Symbol", selection: $symbol) {
                    ForEach(symbols, id: \.self) { Text($0).tag($0) }
                }
            }
            Section("Approval") {
                Toggle("Auto-approve completed chores", isOn: $autoApprove)
                Text(autoApprove ? "Chores count and pay out the moment they're checked off."
                                 : "Completed chores wait for a parent to approve them on the Today board.")
                    .font(.caption).foregroundStyle(Brand.text3)
            }
            Section("Allowance") {
                Toggle("Pay weekly allowance automatically", isOn: $autoAllowance)
            }
            Section("Feedback") {
                Toggle("Haptics", isOn: $haptics)
                    .onChange(of: haptics) { _, new in Haptics.enabled = new }
            }
            Section("Sample data") {
                Button("Load sample family") { SeedData.loadSample(context); Haptics.success() }
                    .disabled(!kids.isEmpty)
            }
            Section {
                Button(role: .destructive) { confirmReset = true } label: { Text("Reset onboarding") }
            } footer: {
                Text("Sprout keeps everything on this device — no accounts, no debit cards, no ads.")
            }
            Section {
                HStack { Text("Version"); Spacer(); Text("1.0").foregroundStyle(Brand.text3).font(Brand.mono(14)) }
            }
        }
        .navigationTitle("Settings")
        .alert("Reset onboarding?", isPresented: $confirmReset) {
            Button("Reset", role: .destructive) {
                UserDefaults.standard.set(false, forKey: "sprout.onboarded")
            }
            Button("Cancel", role: .cancel) {}
        } message: { Text("You'll see the intro again next launch. Your family data is kept.") }
    }
}
