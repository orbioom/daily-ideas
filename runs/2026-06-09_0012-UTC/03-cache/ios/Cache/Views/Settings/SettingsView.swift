import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var goals: [Goal]
    @AppStorage("cache.symbol") private var symbol = "$"
    @AppStorage("cache.hideComplete") private var hideComplete = false
    @AppStorage("cache.haptics") private var haptics = true
    @State private var confirmReset = false

    private let symbols = ["$", "€", "£", "¥", "₹", "kr", "R$", "C$", "A$", "₩"]

    var body: some View {
        Form {
            Section("Currency") {
                Picker("Symbol", selection: $symbol) {
                    ForEach(symbols, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.menu)
                Text("Preview: \(Money.string(1234.5, symbol: symbol))")
                    .font(.caption).foregroundStyle(Brand.text3)
            }
            Section("Goals list") {
                Toggle("Hide completed goals", isOn: $hideComplete)
            }
            Section("Feedback") {
                Toggle("Haptics", isOn: $haptics)
                    .onChange(of: haptics) { _, new in Haptics.enabled = new }
            }
            Section("Sample data") {
                Button("Load sample goals") {
                    SeedData.loadSample(context); Haptics.success()
                }
                .disabled(!goals.isEmpty)
            }
            Section {
                Button(role: .destructive) { confirmReset = true } label: { Text("Reset onboarding") }
            } footer: {
                Text("Cache keeps everything on this device. No accounts, no bank links, no ads.")
            }
            Section {
                HStack { Text("Version"); Spacer(); Text("1.0").foregroundStyle(Brand.text3).font(Brand.mono(14)) }
            }
        }
        .navigationTitle("Settings")
        .alert("Reset onboarding?", isPresented: $confirmReset) {
            Button("Reset", role: .destructive) {
                UserDefaults.standard.set(false, forKey: "cache.onboarded")
            }
            Button("Cancel", role: .cancel) {}
        } message: { Text("You'll see the intro again next launch. Your goals are kept.") }
    }
}
