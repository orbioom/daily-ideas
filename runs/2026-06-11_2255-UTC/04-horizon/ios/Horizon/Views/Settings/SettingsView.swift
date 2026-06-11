import SwiftUI

struct SettingsView: View {
    @AppStorage("currencySymbol") private var currencySymbol = "$"
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("roundChartValues") private var roundChartValues = true

    private let symbols = ["$", "€", "£", "¥", "₹", "CHF ", "A$", "C$", "kr "]

    var body: some View {
        NavigationStack {
            Form {
                Section("Display") {
                    Picker("Currency symbol", selection: $currencySymbol) {
                        ForEach(symbols, id: \.self) { s in
                            Text(s.trimmingCharacters(in: .whitespaces)).tag(s)
                        }
                    }
                    Toggle("Compact chart labels", isOn: $roundChartValues)
                }

                Section("Behavior") {
                    Toggle("Haptic feedback", isOn: $hapticsEnabled)
                }

                Section("Method") {
                    Text("""
                    Every projection runs in today's money: your nominal return is converted to a real return using the Fisher equation, so the FIRE number you see buys what it would buy now.

                    FIRE number = annual spending ÷ withdrawal rate. Coast FIRE = the amount that, growing untouched, reaches your FIRE number by your target age. The chart band shows your expected return ±2 percentage points.
                    """)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    Text("Horizon stores everything on this device, links to no accounts, and is a planning tool — not financial advice.")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
