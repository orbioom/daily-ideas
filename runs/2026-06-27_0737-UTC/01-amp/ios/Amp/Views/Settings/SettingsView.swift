import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var settingsArr: [AmpSettings]
    @Environment(\.modelContext) private var context

    private var settings: AmpSettings { settingsArr.first ?? AmpSettings.fetch(context: context) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Units") {
                    Toggle("Use miles & gallons", isOn: Binding(
                        get: { settings.useImperial },
                        set: { settings.useImperial = $0 }
                    ))
                }
                Section("Currency") {
                    Picker("Symbol", selection: Binding(
                        get: { settings.currencySymbol },
                        set: { settings.currencySymbol = $0 }
                    )) {
                        Text("$ USD").tag("$")
                        Text("€ EUR").tag("€")
                        Text("£ GBP").tag("£")
                        Text("¥ JPY").tag("¥")
                        Text("C$ CAD").tag("C$")
                        Text("A$ AUD").tag("A$")
                    }
                }
                Section("Savings Comparison") {
                    HStack {
                        Text("Gas price")
                        Spacer()
                        TextField("3.80", value: Binding(
                            get: { settings.fuelCostPerUnit },
                            set: { settings.fuelCostPerUnit = $0 }
                        ), format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 70)
                        Text(settings.useImperial ? "/gal" : "/L")
                            .foregroundStyle(.secondary)
                    }
                }
                Section("Accessibility") {
                    Toggle("Enable Haptics", isOn: Binding(
                        get: { settings.enableHaptics },
                        set: { settings.enableHaptics = $0 }
                    ))
                }
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0").foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Made by")
                        Spacer()
                        Text("Orbioom").foregroundStyle(.secondary)
                    }
                    Text("Amp tracks EV charging on-device. No account, no cloud, no subscription.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .onChange(of: settings.useImperial) { _, _ in try? context.save() }
            .onChange(of: settings.currencySymbol) { _, _ in try? context.save() }
            .onChange(of: settings.enableHaptics) { _, _ in try? context.save() }
        }
    }
}
