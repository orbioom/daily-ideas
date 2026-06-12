import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("use24Hour") private var use24Hour = true
    @AppStorage("weekStartsMonday") private var weekStartsMonday = true
    @AppStorage("currencySymbol") private var currencySymbol = "$"
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true

    @Query private var shiftTypes: [ShiftType]
    @Query private var patterns: [RotationPattern]
    @Query private var overrides: [ShiftOverride]

    private let currencies = ["$", "€", "£", "¥", "₹", "R$", "kr", "zł", "CHF "]

    var body: some View {
        NavigationStack {
            Form {
                Section("Display") {
                    Toggle("24-hour times", isOn: $use24Hour)
                    Picker("Week starts on", selection: $weekStartsMonday) {
                        Text("Monday").tag(true)
                        Text("Sunday").tag(false)
                    }
                }

                Section {
                    Picker("Currency", selection: $currencySymbol) {
                        ForEach(currencies, id: \.self) { symbol in
                            Text(symbol.trimmingCharacters(in: .whitespaces)).tag(symbol)
                        }
                    }
                } header: {
                    Text("Pay")
                } footer: {
                    Text("Used for pay estimates on Today and Earnings. Rates live on each shift type.")
                }

                Section("Feedback") {
                    Toggle("Haptics", isOn: $hapticsEnabled)
                }

                Section {
                    LabeledContent("Shift types", value: "\(shiftTypes.count)")
                    LabeledContent("Rotations", value: "\(patterns.count)")
                    LabeledContent("Changed days", value: "\(overrides.count)")
                    LabeledContent("Version", value: "1.0")
                } header: {
                    Text("About")
                } footer: {
                    Text("Rota keeps your roster on this device — no account, no sync server, no subscription. Built for nurses, paramedics, factory crews, pilots, baristas, and anyone whose week isn't Monday-to-Friday.")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
