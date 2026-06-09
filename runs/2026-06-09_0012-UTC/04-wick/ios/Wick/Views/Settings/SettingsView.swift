import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var trades: [Trade]
    @AppStorage("wick.symbol") private var symbol = "$"
    @AppStorage("wick.startBalance") private var startBalance = 10000.0
    @AppStorage("wick.haptics") private var haptics = true
    @State private var confirmReset = false
    @State private var balanceText = ""

    private let symbols = ["$", "€", "£", "¥", "₹", "A$", "C$"]

    var body: some View {
        Form {
            Section("Currency") {
                Picker("Symbol", selection: $symbol) {
                    ForEach(symbols, id: \.self) { Text($0).tag($0) }
                }
            }
            Section("Equity curve") {
                HStack {
                    Text("Starting balance").foregroundStyle(Brand.text2)
                    Spacer()
                    Text(symbol).foregroundStyle(Brand.text3)
                    TextField("10000", text: $balanceText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .font(Brand.mono(15))
                        .frame(maxWidth: 120)
                        .onChange(of: balanceText) { _, new in
                            if let v = Double(new.replacingOccurrences(of: ",", with: "")), v >= 0 {
                                startBalance = v
                            }
                        }
                }
                Text("Used as the baseline for your equity curve.")
                    .font(.caption).foregroundStyle(Brand.text3)
            }
            Section("Feedback") {
                Toggle("Haptics", isOn: $haptics)
                    .onChange(of: haptics) { _, new in Haptics.enabled = new }
            }
            Section("Sample data") {
                Button("Load sample trades") { SeedData.loadSample(context); Haptics.success() }
                    .disabled(!trades.isEmpty)
            }
            Section {
                Button(role: .destructive) { confirmReset = true } label: { Text("Reset onboarding") }
            } footer: {
                Text("Wick keeps your journal entirely on this device. No brokerage logins, no sync, no ads.")
            }
            Section {
                HStack { Text("Version"); Spacer(); Text("1.0").foregroundStyle(Brand.text3).font(Brand.mono(14)) }
            }
        }
        .navigationTitle("Settings")
        .onAppear { balanceText = startBalance == startBalance.rounded() ? String(Int(startBalance)) : String(startBalance) }
        .alert("Reset onboarding?", isPresented: $confirmReset) {
            Button("Reset", role: .destructive) {
                UserDefaults.standard.set(false, forKey: "wick.onboarded")
            }
            Button("Cancel", role: .cancel) {}
        } message: { Text("You'll see the intro again next launch. Your trades are kept.") }
    }
}
